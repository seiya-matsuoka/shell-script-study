# 10. DB / Docker / Application との連携

## この Unit の目的

これまで学んだ Shell Script を PostgreSQL、Docker Container、Application など実際の system に近い対象へ接続し、複数の command や system を順番につなぐ glue / orchestration の役割を理解する。  
この Unit では PostgreSQL、Docker、Application そのものを詳しく学び直すのではなく、それぞれが提供する CLI や interface を Shell Script から利用し、成功・失敗・起動待ち・data の受け渡しを制御することに重点を置く。

代表的には次の流れを扱う。

```text
CSV
↓
Shell Script
↓
psql
↓
PostgreSQL
```

さらに Unit 後半では、次の処理を一つの Shell Script からつなぐ。

```text
PostgreSQL Container 起動
↓
DB 起動完了待ち
↓
schema 作成 / CSV import
↓
Application 起動
↓
health check
↓
API call
↓
DB の最終確認
↓
cleanup
```

Shell Script 自身が DB server や Application の機能を実装するのではなく、既存の command / process / service の間をつなぎ、処理順序と failure handling を担当するイメージを持つ。

## 学習内容

### Shell Script を glue として使う

Shell Script は、複雑な business logic や大規模な data processing をすべて実装する用途より、既存の command や program を順番につなぐ用途に向いている。

たとえば今回利用する仕組みはそれぞれ役割が異なる。

```text
docker compose
→ Container lifecycle を操作する

psql
→ PostgreSQL へ SQL を送る

pg_isready
→ PostgreSQL が connection を受け付けられるか確認する

python3
→ 学習用 Application process を起動する

curl
→ HTTP endpoint を呼び出す

jq
→ JSON response を読む
```

Shell Script はこれらを、

```text
A が成功したら B
B が利用可能になるまで待つ
C が失敗したら終了
最後に resource を片付ける
```

という流れへまとめる。

この Unit で重要なのは command 数を増やすことではなく、**異なる system の境界をどのように Shell から制御するか**である。

### PostgreSQL と `psql`

`psql` は PostgreSQL の command line client である。  
SQL を対話的に入力するだけでなく、Shell Script から SQL 文や SQL file を実行するためにも利用できる。

今回の PostgreSQL は Docker Compose で起動するため、host 側へ `psql` を必須で導入せず、Container 内の `psql` を利用する。

```bash
docker compose exec -T db \
  psql \
  -U unit10 \
  -d unit10db \
  -c 'SELECT 1;'
```

ここでは二つの CLI を組み合わせている。

```text
docker compose exec
→ running Container 内で command を実行

psql
→ Container 内から PostgreSQL へ接続して SQL を実行
```

`docker compose exec` は通常 TTY を割り当てるが、Shell Script のような非対話実行では `-T` で pseudo-TTY を無効にして利用する。

### Connection information

DB connection には、代表的に以下の情報が必要になる。

```text
host
port
database
user
password
```

今回の Compose 環境では default として次を利用する。

```text
host            127.0.0.1
host-side port  55432
database        unit10db
user            unit10
password        unit10-password
```

ただし Shell sample は主に Container 内の `psql` を `docker compose exec` から実行するため、host-side port を直接使わない処理もある。

connection information は環境ごとに変わり得るため、Compose file と Shell Script では environment variable から変更できる形にしている。

```bash
POSTGRES_USER=${POSTGRES_USER:-unit10}
POSTGRES_DB=${POSTGRES_DB:-unit10db}
```

password のような secret は、確認用 output へ安易に表示しない。

今回の password は local learning environment 用の固定値であり、production credential 管理の例ではない。

### SQL file と failure handling

長い SQL を Shell Script の文字列として埋め込むより、SQL 自体を `.sql` file として分離できる。

今回の `sql/` には以下を用意している。

```text
01-schema.sql
→ table 作成

02-reset.sql
→ learning data を reset

03-summary.sql
→ status ごとの件数を確認
```

SQL file は `psql -f` から実行できる。

```bash
psql ... -f /sql/01-schema.sql
```

Shell Script から実行する場合、SQL error が起きたのに後続処理へ進まないようにする必要がある。

今回の sample では、

```bash
-v ON_ERROR_STOP=1
```

を付ける。

これにより SQL 処理で error が発生した場合、`psql` の exit status を Shell 側で failure として扱いやすくなる。

```text
SQL success
↓
psql success
↓
次の処理へ

SQL failure
↓
psql non-zero
↓
Shell Script で終了 / recovery
```

### CSV import

CSV の parsing を Bash だけで実装するのではなく、PostgreSQL が提供する CSV import 機能へ渡す。

今回の流れは以下になる。

```text
data/items.csv
↓
Docker volume mount
↓
/data/items.csv
↓
psql \copy
↓
items table
```

実行例は次の形である。

```text
\copy items(name, status)
FROM '/data/items.csv'
WITH (FORMAT csv, HEADER true)
```

CSV data の解釈は PostgreSQL に任せ、Shell Script は、

```text
schema を用意
↓
data を reset
↓
CSV import
↓
結果確認
```

という orchestration を担当する。

Unit 05 で扱った「複雑な data format を Shell だけで無理に parse しない」という考え方にもつながる。

### Docker Container を Shell から操作する

Docker 自体の仕組みはこの Unit の主目的ではない。

Shell Script から操作する代表的な command として以下を扱う。

```bash
docker compose up -d db
docker compose ps db
docker compose logs db
docker compose exec -T db ...
docker compose down
```

役割は次のように分けられる。

```text
up -d
→ Container を background で起動

ps
→ Container の現在状態を確認

logs
→ Container process の output を確認

exec
→ running Container 内で command を実行

down
→ Compose で作成した resource を停止・削除
```

Shell Script から Docker command を呼ぶ場合も、通常の external command と同じく exit status を持つ。

```bash
if ! docker compose ... up -d db; then
  exit 1
fi
```

Container 操作だから特別な failure handling になるのではなく、これまで学んだ external command の success / failure として扱える。

### Container が起動したことと service が利用可能なことは違う

`docker compose up -d` が成功しても、その直後から PostgreSQL が connection を受け付けられるとは限らない。

```text
Container process start
↓
PostgreSQL initialization
↓
connection accepting
```

という時間差がある。

そのため統合 Script では、

```bash
pg_isready
```

を一定間隔で実行し、DB が request を受け付けられる状態まで待つ。

```text
起動 command success
≠
service ready
```

という考え方は、Unit 06 の Application readiness と同じである。

固定時間の、

```bash
sleep 10
```

だけで待つこともできるが、必要以上に待つ場合や、10 秒で足りない場合がある。

そのため、

```text
状態を確認
↓
まだなら sleep
↓
有限回 retry
```

という polling を利用する。

### Application の位置づけ

この Unit では、DB と連携する対象として小さな learning support Application を `support/app/server.py` に用意している。

Python 自体は学習対象ではない。

Application は主に次の endpoint を持つ。

```text
GET /health
GET /api/items
```

`/health` は PostgreSQL へ `SELECT 1` を実行し、DB access まで成功する場合に、

```json
{ "status": "UP" }
```

を返す。

`/api/items` は PostgreSQL の `items` table を読み、JSON として返す。

したがって、

```text
Application process が起動
```

しただけでは `/health` が必ず成功するわけではない。

```text
Application
↓
DB access
↓
success
↓
health = UP
```

まで確認することで、Application と DB の接続も含めた状態確認になる。

### Application process の起動と停止

Application は次のように background process として起動できる。

```bash
python3 support/app/server.py > app.log 2>&1 &
app_pid=$!
```

`&` で background 実行し、`$!` からその process の PID を取得する。

```text
start
↓
PID 保存
↓
health check
↓
利用
↓
kill
```

という流れにすると、Shell Script が自分で起動した Application process を後から停止できる。

Unit 01 の process / PID、Unit 04 の cleanup、Unit 07 の unattended execution がここで組み合わさる。

### Health check と API call

Application 起動後は、process の存在だけではなく health endpoint を確認する。

```bash
curl -fsS --max-time 2 http://127.0.0.1:18090/health
```

JSON response から Application status を確認する。

```bash
jq -r '.status'
```

health が `UP` になった後に API を呼ぶ。

```bash
curl -fsS http://127.0.0.1:18090/api/items
```

ここでは Unit 06 で扱った、

```text
curl
HTTP status
timeout
JSON
jq
health
readiness
```

を、実際の DB と接続した Application へ適用する。

### DB と API を別方向から確認する

API response が正しいことだけでなく、最後に DB へ直接 query して件数を確認できる。

```text
API
↓
3 items を返す

DB
↓
SELECT COUNT(*)
↓
3
```

これは Application と DB を別々の観点から確認している。

Shell Script は、

```text
API response
DB query
```

という異なる interface の結果を組み合わせて、一連の処理が期待どおり成立したか確認できる。

### Integrated orchestration

`integration/01-run-flow.sh` は、この Unit の各要素を一つの流れへまとめる。

大まかな処理順は以下である。

```text
1. PostgreSQL Container 起動

2. pg_isready で起動完了待ち

3. schema 作成

4. table reset

5. CSV import

6. Application 起動

7. health check

8. API call

9. DB 件数確認

10. Application / Container cleanup
```

各 step は新しい技術ではなく、それまで個別に確認した command を順番につないだものである。

Shell Script が glue として機能する典型的な形である。

### Cleanup

複数 system を起動する Script では、途中 failure も考える。

たとえば、

```text
DB 起動
↓
CSV import 成功
↓
Application 起動
↓
health check failure
```

となった場合、Application や Container を残したまま Script が終了すると、次回実行へ影響する可能性がある。

統合 sample では `trap` を利用する。

```bash
trap cleanup EXIT INT TERM
```

終了理由にかかわらず、

```text
Application process 停止
temporary log 削除
docker compose down
```

を試みる。

Unit 04 で扱った cleanup が、複数 system を扱う orchestration で特に重要になる。

### どこまで Shell Script に任せるか

Shell Script は複数 command をつなぐ用途に強いが、すべての処理を Shell に書く必要はない。

今回でも、

```text
CSV parsing
→ PostgreSQL

DB query
→ psql / PostgreSQL

HTTP server
→ support Application

JSON parsing
→ jq

Container lifecycle
→ Docker Compose
```

へ任せている。

Shell が担当するのは主に、

```text
順序
条件分岐
待機
exit status
environment
data の受け渡し
cleanup
```

である。

この境界を意識すると、Shell Script が巨大な Application になることを避けやすい。

## 使用するもの

この Unit では主に以下を利用する。

- Bash
- Docker
- Docker Compose
- PostgreSQL 18 Container
- `psql`
- `pg_isready`
- `curl`
- `jq`
- Python 3
- `shfmt`
- ShellCheck

Python は learning support Application を動かすためだけに利用し、Python programming 自体は学習対象にしない。

PostgreSQL client は Container 内のものを利用するため、host 側へ `psql` を必須で導入する必要はない。

## 事前準備

Unit 01～09 が完了し、以下を確認済みであることを前提とする。

- process / PID / exit status
- stdout / stderr
- environment variable
- path / working directory
- cleanup / `trap`
- retry / timeout
- CSV / text handling
- HTTP / API / JSON
- health / readiness
- Docker の基本操作
- shfmt / ShellCheck
- automated test の基本的な考え方

Docker Desktop / Docker Engine が利用可能な状態であることを確認する。

```bash
docker version
docker compose version
```

その他の command を確認する。

```bash
command -v bash
command -v curl
command -v jq
command -v python3
```

Unit 08 で導入済みなら quality tool も確認する。

```bash
command -v shfmt
command -v shellcheck
```

Unit 10 へ移動する。

```bash
cd units/10-db-docker-app-integration
```

成果物を確認する。

```bash
find . -maxdepth 4 -type f | sort
```

```text
10-db-docker-app-integration/
├─ README.md
├─ compose.yaml
├─ data/
│  └─ items.csv
├─ sql/
│  ├─ 01-schema.sql
│  ├─ 02-reset.sql
│  └─ 03-summary.sql
├─ examples/
│  ├─ docker/
│  │  ├─ 01-start-db.sh
│  │  ├─ 02-status-and-logs.sh
│  │  ├─ 03-exec-db.sh
│  │  └─ 04-stop-db.sh
│  ├─ postgresql/
│  │  ├─ 01-connection-info.sh
│  │  ├─ 02-run-sql-file.sh
│  │  ├─ 03-import-csv.sh
│  │  ├─ 04-query-summary.sh
│  │  └─ 05-failure-handling.sh
│  └─ application/
│     ├─ 01-start-app.sh
│     ├─ 02-wait-for-health.sh
│     ├─ 03-call-api.sh
│     └─ 04-stop-app.sh
├─ integration/
│  └─ 01-run-flow.sh
├─ support/
│  └─ app/
│     └─ server.py
└─ quality/
   └─ quality-check.sh
```

初回は `postgres:18` image の pull が必要になる場合がある。  
その場合は network connection と image download の時間が必要になる。

default の host-side PostgreSQL port は `55432`、Application port は `18090` である。  
既に別 process が利用している場合は environment variable で変更できる。

PostgreSQL port の例:

```bash
POSTGRES_PORT=55433 \
  docker compose up -d db
```

Application port を変更する場合は、Application と呼び出し側で同じ値を使う。

```bash
APP_PORT=18091 \
  bash examples/application/01-start-app.sh
```

別 Terminal では、

```bash
UNIT10_APP_URL=http://127.0.0.1:18091 \
  bash examples/application/02-wait-for-health.sh
```

## 学習・実践

### 1. Docker Compose から PostgreSQL Container を起動する

Compose configuration を確認する。

```bash
cat compose.yaml
```

主に以下を見る。

```text
image
environment
ports
volumes
healthcheck
```

この Unit では、

```text
./sql
→ /sql:ro

./data
→ /data:ro
```

として Container へ read-only mount している。

PostgreSQL Container を起動する。

```bash
bash examples/docker/01-start-db.sh
```

初回は image pull が行われる場合がある。

起動後、status と最近の log を確認する。

```bash
bash examples/docker/02-status-and-logs.sh
```

`docker compose ps` では Container が running になっていることを確認する。

Compose healthcheck が通るまで少し時間がかかる場合がある。

直接 `pg_isready` を実行する場合は次のようにできる。

```bash
docker compose exec -T db \
  pg_isready \
  -U unit10 \
  -d unit10db
```

accepting connections になれば PostgreSQL が connection を受け付けられる状態である。

ここでは、

```text
docker compose up 成功
```

と、

```text
PostgreSQL ready
```

を別の状態として確認する。

### 2. `psql` と connection information を確認する

connection information sample を実行する。

```bash
bash examples/postgresql/01-connection-info.sh
```

host、port、database、user が表示された後、Container 内の `psql` が `\conninfo` を実行する。

password は確認 output へ表示しない。

次に running Container 内で SQL を直接実行する。

```bash
bash examples/docker/03-exec-db.sh
```

`current_database()` と `current_user` の結果を確認する。

この sample は、

```text
Shell
↓
docker compose exec
↓
Container
↓
psql
↓
PostgreSQL
```

という複数段階の command execution になっている。

それぞれを別々の複雑な仕組みとして捉えるより、Shell から一つの external command chain として読む。

### 3. SQL file の実行と CSV import を確認する

schema SQL を実行する。

```bash
bash examples/postgresql/02-run-sql-file.sh 01-schema.sql
```

`items` table が作成される。

SQL file が存在しない場合も確認できる。

```bash
bash examples/postgresql/02-run-sql-file.sh missing.sql
echo $?
```

Shell 側の validation によって non-zero になる。

次に CSV import sample を実行する。

```bash
bash examples/postgresql/03-import-csv.sh
```

sample は、

```text
schema 作成
↓
table reset
↓
CSV import
↓
COUNT
```

を順番に実行する。

最後に、

```text
3
```

と表示される。

CSV 自体を確認する。

```bash
cat data/items.csv
```

```text
name,status
alpha,READY
beta,WAITING
gamma,READY
```

再度 import sample を実行する。

```bash
bash examples/postgresql/03-import-csv.sh
```

再び count は `3` になる。

`TRUNCATE ... RESTART IDENTITY` で learning data を reset してから import しているため、この sample は同じ学習状態から再実行しやすくしている。

次に summary query を実行する。

```bash
bash examples/postgresql/04-query-summary.sh
```

status ごとの件数が表示される。

SQL 自体の書き方を深掘りするのではなく、

```text
Shell Script
↓
SQL file
↓
psql
↓
DB result
```

という受け渡しを確認する。

### 4. DB command の failure を Shell 側で扱う

意図的に存在しない table を query する sample を実行する。

```bash
bash examples/postgresql/05-failure-handling.sh
echo $?
```

PostgreSQL / `psql` の error message が表示され、Script も non-zero で終了する。

sample では、

```bash
-v ON_ERROR_STOP=1
```

を利用し、SQL failure を `psql` の failure へ反映させている。

その結果を Shell 側の `if` で確認する。

重要なのは PostgreSQL の error message の詳細を覚えることではなく、

```text
DB operation failure
↓
CLI exit status
↓
Shell Script failure
```

と system boundary を越えて failure が伝播することを見ることである。

この確認後も PostgreSQL Container は起動したままでよい。

### 5. Application を起動して health / API / DB のつながりを確認する

Application を起動する前に、CSV import が完了していることを確認する。

次に Application を background で起動する。

```bash
bash examples/application/01-start-app.sh
```

PID と log file path が表示される。

起動直後から fixed `sleep` だけで待つのではなく、health endpoint を polling する。

```bash
bash examples/application/02-wait-for-health.sh
```

成功すると、

```text
application is healthy: attempt=...
```

と表示される。

health endpoint を直接確認してもよい。

```bash
curl -fsS http://127.0.0.1:18090/health | jq '.'
```

```json
{
  "status": "UP"
}
```

今回の `/health` は Application process の存在だけでなく PostgreSQL へ query できるかも確認している。

したがって、

```text
Application process
+
DB connection
```

が成立している状態を確認している。

次に API を呼ぶ。

```bash
bash examples/application/03-call-api.sh
```

CSV から PostgreSQL へ import された items が表示される。

大まかな data flow は以下である。

```text
items.csv
↓
psql \copy
↓
PostgreSQL
↓
support Application
↓
HTTP / JSON
↓
curl / jq
↓
Shell output
```

複数の technology が登場するが、Shell Script はそれぞれの interface を順番につないでいるだけである。

確認が終わったら Application を停止する。

```bash
bash examples/application/04-stop-app.sh
```

### 6. 一連の処理を統合 Script から実行する

個別操作を確認した後、一度 PostgreSQL Container も停止する。

```bash
bash examples/docker/04-stop-db.sh
```

統合 sample を実行する。

```bash
bash integration/01-run-flow.sh
```

処理の進行に応じて、

```text
1. Start PostgreSQL container
2. Wait for PostgreSQL
3. Create schema and import CSV
4. Start application
5. Wait for application health
6. Call API
7. Verify database
```

と表示される。

途中の API response では 3 items が JSON で表示される。

最後に、

```text
database_item_count=3
integration flow completed
```

となれば一連の処理が成立している。

統合 Script は終了時に Application と PostgreSQL Container を cleanup するため、実行後に確認する。

```bash
docker compose ps
```

Unit 10 用 Container が残っていないことを確認する。

この Script で新しく学ぶ individual command はほとんどない。

重要なのは、

```text
external command
↓
exit status

service start
↓
readiness

data preparation
↓
Application start

health
↓
API

final verification
↓
cleanup
```

を一つの control flow にまとめることである。

### 7. Quality check を実行する

Unit 08 以降の通常 Shell Script と同様、formatter / static analysis の対象として確認する。

```bash
bash quality/quality-check.sh
```

内部では、

```text
shfmt -i 2 -d
ShellCheck
```

を実行する。

support Application の Python code はこの Shell quality check の対象外である。

Unit 09 で automated test を学んだが、この Unit は Docker / DB / Application の実 system integration を観察することが中心であるため、すべての操作を Bats test へ置き換えてはいない。

実務では integration test を自動化する場合もあるが、この Unit ではまず orchestration の構造を理解する。

## 実行・確認ポイント

### PostgreSQL

- `psql` を Shell Script から非対話で利用できる。
- connection information は environment ごとに変化し得る。
- password を確認 output へ不用意に表示しない。
- SQL file を `psql -f` から実行できる。
- `ON_ERROR_STOP` で SQL error を command failure へ反映させる。
- CSV parsing を Shell で再実装せず PostgreSQL の import 機能へ渡している。
- DB command の exit status を Shell 側で判断できる。

### Docker

- `docker compose up -d` で background 起動する。
- `docker compose ps` で state を確認する。
- `docker compose logs` で Container の output を確認する。
- `docker compose exec -T` で running Container 内の command を非対話実行する。
- Docker command 自体も exit status を返す external command として扱う。
- Container started と service ready を区別する。

### Application

- background process の PID を保持して停止できる。
- process start と health / readiness を区別する。
- health endpoint が DB access まで確認している。
- `curl` / `jq` で API response を Shell から利用する。
- API failure / health failure 時は後続処理へ進まない。

### Integration

- DB、Application、HTTP API を順番につないでいる。
- 各 step の success を前提に次へ進む。
- readiness polling は有限回にする。
- API と DB を別 interface から確認する。
- `trap` で途中 failure 時も cleanup を試みる。
- Shell に全処理を実装せず、各専用 tool へ処理を委譲する。

## 学習ポイント

### Shell Script の強みは各 system の interface をつなぐことにある

今回の Shell Script は PostgreSQL server も HTTP server も実装していない。

代わりに、

```text
Docker CLI
PostgreSQL CLI
HTTP API
JSON tool
OS process
```

をつないでいる。

各 system が既に持っている interface を利用し、

```text
いつ起動するか
いつ次へ進むか
何を成功とするか
失敗時にどう終了するか
```

を Shell が制御する。

これが glue / orchestration としての代表的な利用方法である。

### CLI がある system は Shell から接続しやすい

Docker には `docker`、PostgreSQL には `psql`、HTTP service には `curl` がある。

それぞれ、

```text
input
output
exit status
```

を持つため、Shell Script の control flow へ組み込みやすい。

特に exit status は異なる technology の間で共通して扱える情報になる。

```text
psql failure
Docker failure
curl failure
```

はいずれも Shell から non-zero として判断できる。

### 「起動できた」と「使える」は区別する

Container や process を起動する command が成功しても、service initialization が完了しているとは限らない。

```text
process exists
≠
service ready
```

これは DB、Web Application、message broker など多くの service に共通する。

そのため、

```text
DB
→ pg_isready

Application
→ /health
```

のように対象 system に適した readiness check を利用する。

Unit 06 で学んだ health / readiness が、実際の orchestration で必要になる理由である。

### Fixed sleep より状態を確認して待つ

単純な、

```bash
sleep 10
```

は理解しやすいが、

```text
2 秒で ready
→ 8 秒余分に待つ

15 秒必要
→ 10 秒では失敗
```

という問題がある。

polling では、

```text
check
↓
not ready
↓
sleep
↓
check
```

を有限回繰り返す。

これにより「時間が経過したか」ではなく「必要な状態になったか」を基準に次へ進める。

### Data format ごとに適切な tool へ任せる

CSV は PostgreSQL、JSON は `jq`、SQL は `psql` が理解する。

Shell から扱うからといって、すべてを Bash の文字列処理へ変換する必要はない。

```text
CSV
→ PostgreSQL COPY

JSON
→ jq

SQL
→ psql / PostgreSQL
```

というように、data の意味を理解する tool へ渡す。

Shell はその tool の前後をつなぐ。

### Failure は system boundary を越えて伝播させる

DB error が発生したのに Shell Script が success で終了すると、呼び出し側は処理成功と誤解する。

```text
PostgreSQL failure
↓
psql non-zero
↓
Shell non-zero
↓
caller が failure を認識
```

という伝播を維持する。

Docker や HTTP でも同様である。

この考え方は Unit 11 の CI/CD で特に重要になる。  
CI step は command の exit status を基準に pipeline failure を判断することが多いためである。

### Integration Script では cleanup の重要性が増す

単一の temporary file だけなら cleanup 対象は小さい。

しかし integration Script では、

```text
Container
Application process
temporary log
```

など複数の resource を起動・生成する。

途中 failure でも片付ける必要があるため、`trap` による cleanup が実用的になる。

ただし production environment では、

```text
failure したら本当に Container を停止してよいか
shared resource ではないか
調査のため残すべきか
```

など、運用要件に応じた判断が必要になる。

### Idempotency は integration flow でも重要

CSV import 前に table を reset しているのは、同じ sample を再実行しやすくするためである。

reset せず同じ CSV を何度も import すると、

```text
duplicate
unique constraint violation
```

などが発生し得る。

実際の system では毎回 `TRUNCATE` できるとは限らない。

production では、

```text
upsert
processed flag
idempotency key
transaction
checkpoint
```

など別の設計が必要になる場合がある。

この Unit では local learning data を毎回同じ状態に戻すことで、再実行性の考え方だけを確認する。

### Application の中身と orchestration は分離して考える

`support/app/server.py` は DB query と HTTP response を担当する。

Shell Script は Application 内部の business logic を実装しない。

```text
Application
→ Application 自身の責務

Shell
→ 起動 / 待機 / 呼び出し / 終了
```

という境界になっている。

Application が Java / Spring Boot、Node.js、Python のどれで実装されていても、外部から、

```text
start command
health endpoint
API
exit status
```

を利用できれば、Shell 側の orchestration の基本的な考え方は共通する。

### Shell Script が大きくなり始めたら役割を見直す

Shell は glue として便利なため、処理を追加し続けやすい。

しかし、

- 複雑な domain logic
- 大量の data transformation
- 複雑な state management
- 高度な retry / concurrency
- 複雑な HTTP client
- 複雑な error object

まで Shell に持たせると読みづらくなりやすい。

今回の統合 Script のように、

```text
外部 command を呼ぶ
結果を見る
次の処理を決める
```

ことが中心なら Shell の強みを活かしやすい。

処理そのものが複雑になった場合は、Application code や専用 tool へ移す判断も必要になる。

### Unit 10 はこれまで学んだ要素を実 system に接続する Unit

Unit 10 で新しく登場する Shell syntax は多くない。

これまで学んだ、

```text
process
environment variable
path
exit status
stdout / stderr
trap / cleanup
timeout / retry
CSV
HTTP / API / JSON
health / readiness
batch operation
quality check
```

を、PostgreSQL / Docker / Application という実際の対象に適用している。

個々の command を覚えること以上に、

> Shell Script から別々の system をどのようにつなぎ、安全に次の処理へ進めるか

という視点を身につけることが、この Unit の中心になる。
