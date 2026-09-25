# 06. HTTP / API / JSON の実用パターン

## この Unit の目的

Shell Script を外部サービスと連携させる代表的な例として、HTTP / API / JSON を扱う。  
`curl` で API を呼び出し、HTTP status code や `curl` の exit status を確認し、`jq` で JSON response から必要な値を取得して、その結果に応じて別の処理へつなげる基本を学習する。  
Unit 04 で扱った timeout / retry / secret、Unit 05 で扱った command の組み合わせと data flow を、HTTP / API という実用的な対象へ接続する。

HTTP protocol 自体の詳細、OAuth 等の認証方式の詳細、高度な `jq` programming には深入りせず、Shell Script から API を扱うために必要な範囲へ絞る。

## 学習内容

### HTTP request / response の基本

HTTP では client が server へ request を送り、server がその request を処理して response を返す。  
Shell Script から API を利用する場合も、この request / response の往復を `curl` などの command から行っている。

```text
Shell Script
↓ HTTP request
API server
↓ HTTP response
Shell Script
```

request には、主に「どの resource に対して」「どのような処理を求めるか」と、その処理に必要な追加情報を含める。  
この Unit では、method、URL、header、body を最低限の構成要素として扱う。

GET は resource や状態を取得するときに利用される代表的な method である。

```bash
curl http://127.0.0.1:18080/api/user
```

POST は server へ data を送り、新しい処理や登録などを依頼するときに利用されることがある。  
JSON API では、request body に JSON を入れ、`Content-Type` header で body の形式を伝える形がよく見られる。

```bash
curl \
  -X POST \
  -H 'Content-Type: application/json' \
  --data '{"name":"alice"}' \
  http://127.0.0.1:18080/api/messages
```

header は request に付加する metadata であり、body の data format や authentication 情報などを伝えるために使われる。

```bash
-H 'Content-Type: application/json'
-H 'Authorization: Bearer ...'
```

body は request で server へ渡す data 本体である。  
Shell から JSON body を作る場合、quote や escape を手作業の文字列連結で処理するより、`jq` のように JSON を理解する tool に任せる方が安全で読みやすい。

server から返る response には、処理結果を表す HTTP status code と response body がある。  
JSON API では body が JSON になっていることが多く、Shell variable や temporary file へ受け取って `jq` で必要な値を取り出せる。

HTTP status code は、request に対して HTTP level でどのような結果になったかを示す。  
この Unit では細かな code を暗記するのではなく、大きく以下の区分を理解する。

```text
2xx
→ request が成功

4xx
→ request / authentication など client 側の問題

5xx
→ server 側の failure
```

### `curl` による HTTP request

`curl` は HTTP request を command line から実行する代表的な tool であり、Shell Script から API を利用するときにも頻繁に使われる。  
URL を渡すだけの単純な GET から、method、header、body、timeout、response の保存方法などを option で組み合わせられる。

この Unit では主に以下を利用する。

```text
-sS
-H
--data
-o
-w
-f
--connect-timeout
--max-time
```

たとえば `-H` は request header、`--data` は request body、`-o` は response body の保存先、`-w` は HTTP status code などの response metadata を取得するために利用する。  
option を一覧として暗記するのではなく、request を組み立てるための option と、response / failure を扱うための option という役割を意識して読む。

### HTTP / API の failure handling

API call の failure は一種類ではない。  
Shell Script では、「HTTP request を送るところまで到達できなかった failure」と、「server から HTTP response を受け取ったが、その response が error を示している状態」を区別する必要がある。

```text
connection failure
→ server へ接続できない
→ HTTP response 自体を受け取れない

HTTP error
→ server へ接続できた
→ HTTP 4xx / 5xx response を受け取った
```

この違いがあるため、`curl` の exit status と HTTP status code は同じ情報ではない。  
既定の `curl` では、HTTP 404 を受け取っても通信そのものが成立していれば exit status `0` になり得る。  
HTTP 4xx / 5xx を `curl` の failure として扱いたい場合は `-f` を利用できる。

外部 API では、接続できないだけでなく「接続はできたが response が返ってこない」という状態も考える。  
そのため timeout を設定し、Script が無制限に待ち続けないようにする。

```bash
curl --connect-timeout 2 --max-time 5 ...
```

`--connect-timeout` は connection establishment に許す時間、`--max-time` は request 全体に許す最大時間を制限する。  
どちらも「外部処理を永遠に待たない」という Unit 04 の考え方を HTTP request へ適用したものである。

一時的な failure では retry が有効な場合もあるが、すべての error を同じように retry するわけではない。

```text
HTTP 503
→ temporary failure の可能性
→ retry を検討

HTTP 401
→ authentication の問題
→ 同じ request を繰り返しても改善しない可能性
```

retry する場合も最大回数と待機時間を決め、failure の意味に応じて継続・再試行・終了を判断する。

### Authentication token

API によっては request に authentication token を付ける。  
token は credential の一種なので、実際の値を Script source に直接記載せず、environment variable や利用環境の secret 管理機能など外部から受け取る。

```bash
: "${API_TOKEN:?API_TOKEN is required}"
```

Bearer token を request header に渡す場合は、次のような形になる。

```bash
-H "Authorization: Bearer $API_TOKEN"
```

token を source code から外しただけで secret handling が完了するわけではない。  
`set -x` / `bash -x` は展開後の command argument を stderr へ出すため、token を含む `curl` command を trace すると secret が log へ露出する可能性がある。

そのため、secret を扱う command では xtrace を無効にする、token 自体を `printf` などで出力しない、といった扱いも合わせて考える。

### JSON と `jq`

JSON は text として表現される data format だが、property、array、string の escape など JSON 固有の構造を持つ。  
そのため JSON response を `grep` / `sed` などの単純な文字列操作だけで解析するのではなく、JSON を理解する parser として `jq` を利用する。

object の property は次のように取得できる。

```bash
jq -r '.name'
```

`-r` を付けると、JSON string の `"alice"` ではなく Shell で扱いやすい `alice` という raw text を出力できる。

array の各 element を扱う場合は `.items[]` のように展開し、`select(...)` を組み合わせることで条件に合う object だけを選択できる。

```bash
jq -r '.items[] | select(.active == true) | .name'
```

この expression は、

```text
.items[]
→ array element を 1 件ずつ取り出す

select(.active == true)
→ active な object だけ残す

.name
→ 必要な property だけ取得する
```

という data flow として読む。

Shell variable を jq の条件へ渡す場合、jq program の文字列へ直接値を埋め込むのではなく `--arg` を利用する。

```bash
jq \
  --arg target "$target_name" \
  '.items[] | select(.name == $target)'
```

これにより、Shell 側の variable を data として jq へ渡し、jq program 自体と分離できる。  
逆方向では、`jq -r` の output を command substitution で Shell variable へ受け取り、その値を `if` などの condition に利用できる。

### Application の health / readiness

HTTP API は data の取得だけでなく、application の状態確認にも利用できる。

health check では、HTTP request が成功したことだけでなく、response body に含まれる application-level status も確認する場合がある。

```text
HTTP status = 200
+
JSON .status = "UP"
↓
healthy
```

つまり「server と HTTP 通信できたこと」と「application が期待する状態であること」を別の情報として確認している。

また、application process が起動していても、その直後から request を受け付けられるとは限らない。  
initialization や dependency connection の完了を待つ間、readiness endpoint が `STARTING` のような状態を返し、準備が整った後に `READY` へ変わる構成もある。

```text
process started
↓
STARTING
↓
STARTING
↓
READY
```

Shell Script では readiness endpoint を一定間隔で polling し、response JSON から状態を取得して、READY になったら後続処理へ進むことができる。  
この場合も無限に待ち続けず、request timeout、最大試行回数、待機時間を組み合わせる。

### この Unit で対象外とする内容

以下には深入りしない。

- HTTP protocol の詳細
- HTTP header の網羅的説明
- cookie / cache / proxy の詳細
- TLS / certificate の詳細
- OAuth 等の認証方式の詳細
- JWT の詳細
- 高度な `jq` programming
- production-grade retry policy
- API client library の設計

## 使用するもの

この Unit では主に以下を利用する。

- WSL 2 上の Linux
- Bash
- `curl`
- `jq`
- `mktemp`
- `sleep`
- Python 3

Python 3 は学習対象ではない。  
外部 API の仕様変更や internet connection に依存せず HTTP / API の挙動を再現するため、学習用 mock API server の起動だけに利用する。

mock API は以下の address のみに bind する。

```text
127.0.0.1:18080
```

local machine 外部からの接続を受け付けない構成としている。

## 事前準備

Unit 01～05 が完了し、以下を確認済みであることを前提とする。

- process / exit status
- stdin / stdout / stderr
- pipe / redirect
- variable / quote / condition / loop / function
- validation
- timeout / retry
- secret と xtrace
- temporary file / cleanup
- command output を次の処理へ渡す考え方

必要な command を確認する。

```bash
command -v curl
command -v jq
command -v python3
```

リポジトリ root から Unit 06 へ移動する。

```bash
cd units/06-http-api-json
```

構成を確認する。

```bash
find . -maxdepth 3 -type f | sort
```

```text
06-http-api-json/
├─ README.md
├─ examples/
│  ├─ application/
│  │  ├─ 01-health-check.sh
│  │  └─ 02-wait-until-ready.sh
│  ├─ authentication/
│  │  ├─ 01-token-from-environment.sh
│  │  └─ 02-token-and-xtrace.sh
│  ├─ failure-handling/
│  │  ├─ 01-connection-failure.sh
│  │  ├─ 02-http-error.sh
│  │  ├─ 03-timeout.sh
│  │  └─ 04-retry.sh
│  ├─ http-api/
│  │  ├─ 01-get.sh
│  │  ├─ 02-post-json.sh
│  │  ├─ 03-request-header.sh
│  │  └─ 04-status-code.sh
│  └─ json/
│     ├─ 01-property.sh
│     ├─ 02-array-filter.sh
│     ├─ 03-shell-variable-to-jq.sh
│     └─ 04-json-condition.sh
└─ support/
   └─ mock-api/
      └─ server.py
```

Terminal A で mock API を起動する。

```bash
python3 support/mock-api/server.py
```

以下が表示されれば起動できている。

```text
Unit 06 mock API: http://127.0.0.1:18080
```

Unit 06 の学習中は Terminal A を起動したままにする。  
学習終了後は Terminal A で `Ctrl+C` を押して server を停止する。

別 Terminal から health endpoint を確認してもよい。

```bash
curl -sS http://127.0.0.1:18080/api/health
```

## 学習・実践

### 1. `curl` で GET / POST / header / status code を確認する

GET request を実行する。

```bash
bash examples/http-api/01-get.sh
```

JSON response が stdout へ表示される。  
この段階では JSON を解析せず、「`curl` が response body を stdout へ出している」ことを確認する。

POST request を実行する。

```bash
bash examples/http-api/02-post-json.sh
```

この Script では request body を `jq -n` で生成し、

```bash
-H 'Content-Type: application/json'
--data "$request_body"
```

として server へ送る。  
JSON を Shell の文字列連結だけで作らず、JSON-aware な tool に escaping を任せている点に注目する。

request header を確認する。

```bash
bash examples/http-api/03-request-header.sh
```

`X-Demo: unit06` を server へ送り、response JSON から server が受け取った値を確認する。

HTTP status code と body を分けて扱う。

```bash
bash examples/http-api/04-status-code.sh
```

以下の役割になっている。

```text
-o "$body_file"
→ response body を file へ保存

-w '%{http_code}'
→ HTTP status code を stdout へ出す
```

API call では body と status code を別の情報として処理できることを確認する。

### 2. Connection failure・HTTP error・timeout・retry を区別する

connection failure を再現する。

```bash
bash examples/failure-handling/01-connection-failure.sh
```

mock API が利用していない `127.0.0.1:18081` へ接続するため、HTTP response を受け取る前に `curl` が non-zero になる。

次に HTTP 404 を確認する。

```bash
bash examples/failure-handling/02-http-error.sh
```

server には接続できるが HTTP 404 response が返る。  
`curl -f` により 4xx / 5xx を `curl` failure として扱っている。

この 2 つから以下を区別する。

```text
connection failure
≠
HTTP error
```

timeout を確認する。

```bash
bash examples/failure-handling/03-timeout.sh
```

server は `/api/slow` で 2 秒待つが、`curl` 側は `--max-time 1` のため timeout する。

retry sample を実行する前に、mock API の状態を初期化するため server を一度 `Ctrl+C` で停止して再起動する。

```bash
python3 support/mock-api/server.py
```

別 Terminal で実行する。

```bash
bash examples/failure-handling/04-retry.sh
```

mock API は `/api/unstable` に対して以下を返す。

```text
1 回目 → HTTP 503
2 回目 → HTTP 503
3 回目 → HTTP 200
```

Script は 503 の場合だけ retry し、200 で終了する。  
connection-level failure の場合は retry loop へ入らず `curl` status を返す。

### 3. Token を environment variable から渡し、log へ出さない

mock API の学習用 token を environment variable へ設定する。

```bash
export API_TOKEN='unit06-demo-token'
```

これは real secret ではなく Unit 06 専用の dummy value である。

authentication sample を実行する。

```bash
bash examples/authentication/01-token-from-environment.sh
```

token は Script source に書かず、

```bash
: "${API_TOKEN:?API_TOKEN is required}"
```

で environment から受け取る。

xtrace と token の関係を確認する。

```bash
bash examples/authentication/02-token-and-xtrace.sh
```

token を request header へ渡す部分は `set +x` の状態にし、secret を含まない後続処理だけ `set -x` で trace する。

Unit 04 で学んだ、

```text
xtrace
→ 展開後 argument が stderr へ出る
→ secret も出る可能性
```

を HTTP authentication へ適用する。

確認後は environment variable を削除する。

```bash
unset API_TOKEN
```

### 4. `jq` で property・array・filter を扱う

property を取得する。

```bash
bash examples/json/01-property.sh
```

response JSON から `.name` と `.active` を取り出して Shell variable へ入れる。

array と filter を確認する。

```bash
bash examples/json/02-array-filter.sh
```

jq expression は以下である。

```jq
.items[] | select(.active == true) | .name
```

処理を分けると、

```text
.items[]
→ array element を 1 件ずつ

select(.active == true)
→ active な object だけ

.name
→ name property だけ
```

となる。

Shell variable を jq へ渡す。

```bash
bash examples/json/03-shell-variable-to-jq.sh gamma
```

`--arg target "$target_name"` によって Shell variable を jq variable `$target` として利用する。

別 value も試す。

```bash
bash examples/json/03-shell-variable-to-jq.sh alpha
```

JSON value を Shell condition へつなげる。

```bash
bash examples/json/04-json-condition.sh
```

`.status` を取得し、

```bash
if [[ $status == UP ]]; then
```

で後続処理を決める。

この流れが Unit 06 の基本形である。

```text
API call
↓
JSON response
↓
jq で必要な値
↓
Shell condition
↓
next action
```

### 5. Health check で HTTP と application state を両方確認する

health check sample を実行する。

```bash
bash examples/application/01-health-check.sh
```

この Script は二段階で判定する。

```text
HTTP status == 200
↓
JSON .status == "UP"
↓
healthy
```

HTTP request が成立しただけでは application が期待した状態とは限らない。  
逆に body の文字列だけでは HTTP-level failure を見落とす可能性がある。

health endpoint の contract に応じて、

```text
HTTP-level state
+
application-level state
```

を組み合わせる考え方を確認する。

### 6. API response を利用して起動完了を判定する

readiness sample の状態を初期化するため mock API server を一度停止して再起動する。

```bash
python3 support/mock-api/server.py
```

別 Terminal で実行する。

```bash
bash examples/application/02-wait-until-ready.sh
```

`/api/ready` は server 起動後、以下を返す。

```text
1 回目 → STARTING
2 回目 → STARTING
3 回目 → READY
```

Script は JSON property を `jq` で取得し、

```bash
if [[ $status == READY ]]; then
```

で起動完了を判断する。

READY でなければ `sleep 1` 後に再確認する。  
`max_attempts=5` としているため永遠には待ち続けない。

```text
process を起動した
≠
application が request を受け付ける準備ができた
```

ことを意識し、固定 `sleep` だけでなく application state を確認する pattern を学ぶ。

## 実行・確認ポイント

### HTTP / API

- request と response の関係を説明できる。
- GET / POST の基本的な違いを確認する。
- `-H` で request header を追加できる。
- `--data` で request body を送れる。
- response body と HTTP status code を別々に扱える。
- HTTP protocol の詳細まで覚える必要はない。

### Failure handling

- connection failure と HTTP error は別である。
- `curl` exit status と HTTP status code は別である。
- `-f` で HTTP 4xx / 5xx を `curl` failure として扱える。
- `--connect-timeout` と `--max-time` の役割を区別する。
- retry は failure の種類を見て行う。
- retry count は有限にする。

### Authentication

- token を Script source に hard-code しない。
- environment variable から token を受け取れる。
- Authorization header へ token を渡せる。
- token value を stdout / stderr へ出さない。
- `set -x` / `bash -x` が secret を log に出す可能性を意識する。

### JSON

- JSON を `grep` / `sed` で無理に parse せず `jq` を使う。
- `.property` で property を取得できる。
- `.items[]` で array element を展開できる。
- `select(...)` で filter できる。
- `-r` で JSON string を raw text として取得できる。
- `--arg` で Shell variable を jq へ渡せる。
- jq output を Shell variable / condition へつなげられる。

### Application

- health check で HTTP status と application-level status を組み合わせられる。
- process start と application ready は同じとは限らない。
- readiness endpoint を polling して起動完了を判定できる。
- polling は max attempts と request timeout を持たせる。

## 学習ポイント

### API call は `curl` 1 行ではなく複数層の結果を持つ

API call には少なくとも以下の層がある。

```text
connection / transfer
↓
curl exit status

HTTP protocol-level result
↓
HTTP status code

application-level result
↓
JSON body
```

たとえば、

```text
curl status = 0
HTTP status = 404
JSON = {"error":"not_found"}
```

という組み合わせもあり得る。

「何を success とするか」は Script の目的によって決める。

### `curl` exit status と HTTP status を混同しない

connection failure では HTTP response 自体がない。  
HTTP 404 では server との通信は成立している。

そのため、

```text
connection / transfer
→ curl status

HTTP result
→ HTTP status code
```

という切り分けができる。

`curl -f` は HTTP 4xx / 5xx を `curl` failure へ寄せる便利な option だが、概念上は別の情報であることを理解して使う。

### Timeout / retry は HTTP でも Unit 04 と同じ原則

HTTP になっても安全性の原則は変わらない。

```text
timeout
→ 永遠に待たない

retry
→ 無制限に繰り返さない

failure classification
→ retry 可能か考える
```

HTTP 503 と 401 を同じ retry policy にしないよう、failure の意味を見て処理する。

### POST body は文字列連結より data-aware な tool で組み立てる

JSON request を手作業で quote すると、値に quote や特殊文字が含まれた場合に壊れやすい。

```bash
jq -n --arg name "$name" '{name: $name}'
```

のように JSON の escaping は JSON-aware な tool に任せる。

Unit 05 の「複雑な data format は専用 parser / tool へ任せる」という考え方と同じである。

### JSON は text だが、ただの text として parse しない

JSON に対して `grep` / `sed` / `cut` を重ねれば、小さな例では動く場合がある。  
しかし whitespace、property order、nested object、escaping などで壊れやすい。

```text
JSON
→ jq / JSON parser
```

として format を理解している tool を使う。

### Shell と `jq` の境界でも quote を意識する

Shell variable を jq expression へ直接埋め込むより、

```bash
jq \
  --arg target "$target" \
  '.items[] | select(.name == $target)'
```

のように `--arg` で data と program を分ける。

異なる parser / language 間で data を渡すときは、それぞれの quote / escape を混ぜないことが重要である。

### Secret を externalize しても log への露出は別問題

token を environment variable に移せば source code への hard-code は避けられる。  
しかし、

```bash
set -x
curl -H "Authorization: Bearer $API_TOKEN" ...
```

とすれば token が stderr に出る可能性がある。

```text
secret storage
+
secret transport
+
logging / tracing
```

を別々に考える。

### Health と readiness は同じとは限らない

概念として、

```text
health
→ application が正常に動作しているか

readiness
→ request を受け付けられる準備ができたか
```

と分けられる場合がある。

この Unit では framework 固有の定義には深入りせず、

```text
API response
↓
必要な value を取得
↓
期待した状態か判定
↓
次へ進む / 待つ / failure
```

という Shell Script 側の pattern を学ぶ。

### 起動完了待ちは固定 `sleep` より状態確認が有効な場合がある

単純に `sleep 10` とすると、

```text
2 秒で ready
→ 不要に待つ

20 秒必要
→ まだ ready でない
```

ということがある。

readiness endpoint を polling すれば application 自身の状態を見て判断できる。  
ただし polling 自体も無限にしない。

```text
max attempts
+
sleep interval
+
request timeout
```

を組み合わせる。

### Shell は API client library の代替ではなく orchestration に強い

複雑な OAuth flow、大量 data processing、複雑な request model まで Bash に実装し始めると保守しにくくなる。

一方、

```text
API を呼ぶ
↓
JSON の数 property を取得
↓
状態に応じて command を実行
```

のような automation は Shell と相性がよい。

この Unit の到達点は HTTP / JSON の全機能を学ぶことではなく、

```text
curl
↓
status / JSON
↓
jq
↓
Shell condition
↓
next command
```

という基本的な実用 pattern を理解することである。

### 後続 Unit とのつながり

この Unit の内容は後続 Unit で以下のようにつながる。

```text
Unit 07 batch / cron
→ scheduled API call
→ health check
→ retry / log

Unit 10 DB / Docker / Application
→ application health / readiness
→ API との連携

Unit 11 CI/CD
→ deployment 後 health check
→ API response による validation
→ secret
→ failure propagation
```

HTTP / API を特別なものとしてではなく、Shell Script が外部 service と data をやり取りする代表例として捉える。
