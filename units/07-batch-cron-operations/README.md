# 07. バッチ・cron・定期実行と運用設計

## この Unit の目的

人間が Terminal から手動で実行する Shell Script と、cron などの scheduler から無人で定期実行される Shell Script の違いを理解する。  
定期実行では、Script の処理内容が正しいだけでなく、対話操作なしで完了できること、実行環境を暗黙に仮定しないこと、後から結果や原因を追跡できること、再実行や二重実行に耐えられることなど、運用を意識した設計が重要になる。

この Unit では batch processing と cron を中心に、PATH / working directory / environment variable、stdout / stderr / log、exit status、retry / timeout / cleanup、idempotency、partial failure、lock を一つの流れとして扱う。  
最後に systemd service / timer を取り上げ、cron との大まかな役割の違いと process supervision の考え方へつなげる。

## 学習内容

### Batch processing と unattended execution

batch processing は、一定量の data や複数の処理をまとめて実行する形を指す。  
Web request のように人間の操作へ即座に応答する処理とは異なり、決められた input を順番に処理したり、指定時刻にまとめて処理したりする場面で利用される。

Shell Script は、file 操作、command の組み合わせ、log 処理、backup、API call などを自動化しやすいため、小規模な batch processing によく利用される。

定期実行される Script では、人間がその場にいないことを前提にする。

```text
manual execution
→ Terminal で人間が実行
→ prompt を見て入力できる
→ error をその場で確認できる

unattended execution
→ scheduler が自動実行
→ 人間からの入力を待てない
→ 実行環境が interactive shell と異なる場合がある
→ 後から log や exit status で結果を確認する
```

そのため、`read` で user input を待つ Script より、argument、configuration、environment variable などから必要な情報を受け取る Script の方が定期実行に向いている。

また、処理途中で問題が発生したときに「画面を見て人間が判断する」ことへ依存しない。  
正常終了・異常終了を exit status で示し、必要な情報を stdout / stderr や log file に残すことが重要になる。

### cron / crontab

cron は Unix / Linux 系環境で定期的に command を実行する代表的な仕組みである。  
一般的には cron daemon が schedule を監視し、登録された時刻になると command を起動する。

user 単位の schedule は crontab で管理できる。

```bash
crontab -e
```

現在の user crontab を確認する場合は次のようにする。

```bash
crontab -l
```

crontab の代表的な 5 field は以下である。

```text
minute hour day-of-month month day-of-week command
```

たとえば毎日 02:30 に command を実行する場合は次のようになる。

```cron
30 2 * * * command
```

5 分ごとの例は以下である。

```cron
*/5 * * * * command
```

この Unit では schedule syntax の全パターンを暗記することは目的としない。  
「どの field が何を表すか」「scheduler が指定時刻に command を起動する」という基本構造を理解する。

`config/cron/crontab.example` には学習用の記述例を用意している。  
実際の crontab へ登録する場合は、repository の配置場所や利用環境に合わせて absolute path を設定する必要がある。

### 定期実行時の environment

手動実行では、普段使っている interactive shell の environment を無意識に利用していることがある。

たとえば、

- `PATH`
- current working directory
- `HOME`
- shell startup file で設定した environment variable
- alias / shell function

などである。

cron から実行される process は、普段の Terminal と同じ environment で起動されるとは限らない。  
そのため、Terminal では動くのに cron では動かない、という問題が起こることがある。

#### PATH

Shell が、

```bash
awk
```

のような command name を実行するときは `PATH` から executable を探索する。

```bash
command -v awk
```

で現在どの executable が解決されるか確認できる。

定期実行 Script では、

- Script 内で必要な `PATH` を明示する
- command の absolute path を使用する
- 実行前に dependency を確認する

といった方法を、処理の性質に応じて選ぶ。

すべての command を無条件に absolute path にする必要があるわけではないが、「interactive shell と同じ PATH があるはず」と暗黙に仮定しないことが重要である。

#### Working directory と absolute path

relative path は current working directory を基準に解釈される。

```bash
./input/data.csv
```

という path が正しくても、scheduler が別 directory から Script を起動すると対象 file が見つからない可能性がある。

Script 自身の directory を基準にする場合は、たとえば次のように求められる。

```bash
script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)
```

そのうえで、

```bash
"$script_dir/input/data.csv"
```

のように path を組み立てる。

重要なのは「常に absolute path を書く」ことではなく、**どの directory を path の基準にするかを意図的に決めること**である。

#### Environment variable

interactive shell の startup file で設定した variable が、cron でも存在するとは限らない。

Script が特定の environment variable を必要とするなら、

```bash
: "${APP_ENV:?APP_ENV is required}"
```

のように前提を確認する。

credential などを environment variable から受け取る場合も、scheduler からどのようにその variable を渡すかを運用側で設計する必要がある。

### 定期実行と logging

人間がその場で画面を見ていないため、定期実行 Script では「後から何が起きたか分かる出力」が重要になる。

stdout と stderr は、Unit 02 で扱った役割をそのまま利用できる。

```text
stdout
→ 通常の処理結果

stderr
→ error / diagnostic message
```

cron entry から file へ保存する場合は、たとえば次のように redirect できる。

```bash
/path/to/job.sh >> /path/to/job.log 2>&1
```

この場合は stdout と stderr の両方が同じ log file へ追記される。

ただし、単に大量の message を出せばよいわけではない。  
後から「いつ」「どの処理で」「何が起きたか」を追える情報を残す。

```text
2026-09-26T02:30:00+0900 INFO  batch started
2026-09-26T02:30:01+0900 INFO  processing item=alpha
2026-09-26T02:30:02+0900 WARN  retry attempt=1
2026-09-26T02:30:04+0900 ERROR upload failed
```

最低限でも timestamp と message があると、複数回の定期実行結果を区別しやすい。  
必要に応じて `INFO` / `WARN` / `ERROR` のような level を付ければ、message の意味も追いやすくなる。

log level の高度な設計や logging framework を作ることが目的ではない。  
この Unit では、無人実行後に原因を追跡できる程度の一貫した output を意識する。

### 運用を意識した Script

Unit 04 で扱った安全性の仕組みは、定期実行される Script で特に重要になる。

#### Exit status

scheduler や別 Script は exit status から job の結果を判断できる。

```text
0
→ success

non-zero
→ failure
```

異常が発生したのに最後の `printf` などが成功して exit status `0` になると、外部からは正常終了したように見える。  
処理全体の結果に合った status を返すことが重要である。

#### Timeout / retry

network access や external command が停止した場合、定期 batch 自体が終わらない状態を避ける。

```text
timeout
→ 1 回の処理時間に上限を設ける

retry
→ 一時的な failure を有限回再試行する
```

Unit 06 の HTTP retry と同じく、すべての failure を無条件に retry するものではない。  
最大回数と待機時間を決める。

#### Cleanup

temporary file や intermediate directory を使用する場合、正常終了時だけでなく failure 時にも cleanup できるよう `trap` を利用できる。

定期実行では同じ Script が何度も動くため、前回の temporary data が残り続けないことも重要になる。

#### Idempotency と再実行

idempotency は、同じ処理を繰り返しても期待する最終状態が壊れない性質として考えられる。

たとえば、

```bash
printf '%s\n' 'status=completed' > "$output_file"
```

のように期待する状態へ書き直す処理は、再実行しても同じ内容になる。

一方、

```bash
printf '%s\n' 'status=completed' >> "$output_file"
```

なら、再実行するたびに同じ行が増える。

すべての batch を完全に idempotent にできるわけではないが、failure 後に再実行する可能性を考え、

- 同じ data を二重登録しないか
- output が重複しないか
- 途中まで成功した状態から再開できるか

を検討する。

#### Partial failure

複数 file や record を処理する batch では、一件だけ失敗することがある。

```text
item A → success
item B → failure
item C → success
```

このとき、

- 最初の failure で batch 全体を終了する
- failure item を記録して残りを続行する
- 成功 / failure を別 directory に分ける
- 最後に全体を non-zero で終了する

など、目的に応じた設計がある。

重要なのは、partial failure が発生したときの挙動を偶然に任せず、**どこまで処理を継続し、何を job 全体の failure とするかを決めること**である。

#### 二重実行と lock

定期実行では、前回 job が終わる前に次の schedule が来る可能性がある。

```text
02:00 start
↓
処理が長引く

02:05 next schedule
↓
同じ Script が二重起動
```

同じ output file や database record を同時に操作すると問題になる場合がある。

Linux では `flock` を使って lock を取得し、既に別 process が実行中なら新しい process を終了させる方法がある。

```bash
exec 9>"/tmp/job.lock"
flock -n 9
```

lock が必要かどうかは処理内容による。  
読み取りだけで競合しない Script にまで必ず lock を入れるのではなく、二重実行で問題が起こる処理に対して利用する。

### systemd service / timer

systemd を利用する Linux environment では、service と timer を組み合わせて定期実行を構成できる。

service unit は「何を実行するか」を定義する。

```ini
[Service]
Type=oneshot
WorkingDirectory=/path/to/unit
ExecStart=/usr/bin/bash /path/to/job.sh
```

timer unit は「いつ service を起動するか」を定義する。

```ini
[Timer]
OnCalendar=*:0/5
Unit=sample.service
```

cron と systemd timer はどちらも定期実行に利用できるが、同じ仕組みではない。

大まかには、

```text
cron
→ schedule に従って command を起動する
→ シンプルな定期実行で長く利用されている

systemd service / timer
→ service と schedule を unit として管理
→ service state や journal と統合できる
→ process supervision と同じ systemd の仕組みに乗る
```

と捉える。

systemd service では長時間動作する process に対する restart policy なども設定できる。  
一方、定期 batch では `Type=oneshot` の service を timer から起動する構成もある。

この Unit では systemd の詳細な unit 設計や Linux server administration は対象にしない。  
cron 以外にも定期実行と process 管理を統合する仕組みがあり、service / timer という役割分担があることを理解する。

## 使用するもの

この Unit では主に以下を利用する。

- WSL 2 上の Linux
- Bash
- `cron` / `crontab` の概念と設定例
- `date`
- `timeout`
- `flock`
- `find`
- `wc`
- `mktemp`
- `systemd` service / timer の設定例

`cron` daemon や systemd timer を実際に常駐設定すること自体は必須としない。  
利用環境によって cron / systemd の有効化状態が異なるため、基本的な Script は Terminal から再現できるようにし、cron / systemd は設定内容と実行環境の違いを理解することを優先する。

## 事前準備

Unit 01～06 が完了し、以下を確認済みであることを前提とする。

- process / exit status
- stdin / stdout / stderr
- path / environment variable
- Bash Script の argument / condition / loop / function
- `trap` / cleanup
- timeout / retry
- idempotency
- lock / `flock`
- log processing
- API 等の external process / service との連携

Unit 07 へ移動する。

```bash
cd units/07-batch-cron-operations
```

成果物を確認する。

```bash
find . -maxdepth 3 -type f | sort
```

```text
07-batch-cron-operations/
├─ README.md
├─ config/
│  ├─ cron/
│  │  └─ crontab.example
│  └─ systemd/
│     ├─ unit07-batch.service
│     └─ unit07-batch.timer
└─ examples/
   ├─ batch/
   │  ├─ 01-non-interactive.sh
   │  └─ 02-batch-loop.sh
   ├─ environment/
   │  ├─ 01-runtime-context.sh
   │  ├─ 02-path-resolution.sh
   │  ├─ 03-working-directory.sh
   │  └─ 04-environment-variable.sh
   ├─ logging/
   │  ├─ 01-stdout-stderr.sh
   │  └─ 02-structured-log.sh
   ├─ operations/
   │  ├─ 01-exit-status.sh
   │  ├─ 02-retry-timeout.sh
   │  ├─ 03-idempotent-output.sh
   │  ├─ 04-partial-failure.sh
   │  └─ 05-lock.sh
   └─ systemd/
      └─ 01-batch-job.sh
```

主要 command を確認する。

```bash
command -v bash
command -v date
command -v timeout
command -v flock
```

cron / systemd の command は environment によって存在しない場合があるため、確認のみ行う。

```bash
command -v crontab || true
command -v systemctl || true
```

## 学習・実践

### 1. 対話操作に依存しない batch Script を確認する

まず temporary input file を作る。

```bash
input_file=$(mktemp)
printf '%s\n' alpha beta gamma > "$input_file"
```

argument で input file を渡す。

```bash
bash examples/batch/01-non-interactive.sh "$input_file"
```

以下のように file と line count が表示される。

```text
processed file=... lines=3
```

この Script は `read` などで user input を待たず、実行開始時に必要な情報を argument から受け取る。

argument なしも確認する。

```bash
bash examples/batch/01-non-interactive.sh
echo $?
```

usage を stderr に出し、non-zero で終了する。

学習用 file を削除する。

```bash
rm -f -- "$input_file"
```

複数 input を自動処理する sample を実行する。

```bash
bash examples/batch/02-batch-loop.sh
```

3 files が順番に処理され、最後に、

```text
processed_count=3
```

と表示される。

ここでは処理内容そのものより、

```text
input があらかじめ決まっている
↓
人間の操作なしで loop
↓
最後まで終了
```

という unattended batch の基本形を見る。

### 2. cron / crontab の構造を確認する

設定例を表示する。

```bash
cat config/cron/crontab.example
```

次の 5 field を確認する。

```text
minute
hour
day of month
month
day of week
```

```cron
30 2 * * * command
```

は毎日 02:30 の例である。

```cron
*/5 * * * * command
```

は 5 分ごとの例である。

`crontab` が利用できる環境では、現在の user crontab を確認できる。

```bash
crontab -l
```

未登録の場合は「no crontab」のような message が出る場合がある。  
この Unit の学習のために実際の定期 job を登録する必要はない。

重要なのは、

```text
crontab
→ schedule + command を定義

cron daemon
→ schedule を監視

指定時刻
→ command を起動
```

という役割を理解することである。

### 3. 手動実行と scheduler 実行で変わりやすい environment を確認する

現在の environment を表示する。

```bash
bash examples/environment/01-runtime-context.sh
```

`PWD`、`PATH`、`HOME`、`SHELL` が表示される。

次に environment を大幅に減らした状態を疑似的に作る。

```bash
env -i \
  HOME="$HOME" \
  PATH="/usr/bin:/bin" \
  /usr/bin/bash examples/environment/01-runtime-context.sh
```

普段の Terminal と `PATH` などが異なることを確認する。

cron そのものを起動しなくても、

> scheduler から実行される process が interactive shell と同じ environment とは限らない

という前提を再現できる。

PATH による command resolution を確認する。

```bash
bash examples/environment/02-path-resolution.sh awk
```

現在の `PATH` から `awk` がどこにあるか表示される。

minimal PATH でも確認する。

```bash
env -i \
  PATH="/usr/bin:/bin" \
  /usr/bin/bash examples/environment/02-path-resolution.sh awk
```

一方、対象 command が PATH にない environment も作れる。

```bash
mkdir -p /tmp/unit07-empty-path

env -i \
  PATH="/tmp/unit07-empty-path" \
  /usr/bin/bash examples/environment/02-path-resolution.sh awk

rmdir /tmp/unit07-empty-path
```

`command not found in PATH` として non-zero になる。

次に working directory を確認する。

```bash
bash examples/environment/03-working-directory.sh
```

現在の `PWD` と Script directory が表示される。

別 directory から実行する。

```bash
unit07_dir=$PWD

(
  cd /tmp
  /usr/bin/bash "$unit07_dir/examples/environment/03-working-directory.sh"
)
```

今度は、

```text
current_working_directory
≠
script_directory
```

となる。

relative path がどの directory を基準にするかを暗黙にしない理由を、実際の値から確認する。

environment variable の前提確認も行う。

```bash
UNIT07_TARGET=production \
  bash examples/environment/04-environment-variable.sh
```

未設定の場合は、

```bash
bash examples/environment/04-environment-variable.sh
```

で処理開始前に error となる。

### 4. stdout / stderr と運用 log を確認する

stdout と stderr を別 file に redirect する。

```bash
stdout_file=$(mktemp)
stderr_file=$(mktemp)

bash examples/logging/01-stdout-stderr.sh \
  > "$stdout_file" \
  2> "$stderr_file"
```

stdout を確認する。

```bash
cat "$stdout_file"
```

stderr を確認する。

```bash
cat "$stderr_file"
```

別 stream に出力されていることを確認したら削除する。

```bash
rm -f -- "$stdout_file" "$stderr_file"
```

次に一定 format の logging sample を実行する。

```bash
bash examples/logging/02-structured-log.sh
```

各行に、

```text
timestamp
level
message
```

が含まれる。

log file へ追記する場合は次のようにできる。

```bash
log_file=$(mktemp)

bash examples/logging/02-structured-log.sh >> "$log_file" 2>&1
bash examples/logging/02-structured-log.sh >> "$log_file" 2>&1

cat "$log_file"
rm -f -- "$log_file"
```

2 回の実行結果が timestamp 付きで残るため、後からどの実行で何が起きたかを追いやすくなる。

### 5. Exit status・retry・timeout・idempotency を運用の文脈で確認する

正常終了を確認する。

```bash
bash examples/operations/01-exit-status.sh success
echo $?
```

`0` になる。

failure を確認する。

```bash
bash examples/operations/01-exit-status.sh failure
echo $?
```

`1` になる。

scheduler から見れば画面の文章より exit status が機械的な結果判定に利用しやすい。

retry / timeout sample を実行する。

```bash
bash examples/operations/02-retry-timeout.sh
```

この sample は、最初の 2 回が timeout し、3 回目に成功する処理を再現する。

```text
attempt=1 failed ...
attempt=2 failed ...
completed on attempt=3
job success attempt=3
```

という流れを確認する。

ここで見るべき点は、

```text
一回の処理時間
→ timeout で上限

一時 failure
→ 最大回数まで retry

success
→ その時点で終了
```

という組み合わせである。

次に idempotency を確認するため、同じ output directory で 2 回実行する。

```bash
work_dir=$(mktemp -d)

UNIT07_WORK_DIR="$work_dir" \
  bash examples/operations/03-idempotent-output.sh

UNIT07_WORK_DIR="$work_dir" \
  bash examples/operations/03-idempotent-output.sh

cat "$work_dir/status.txt"
wc -l "$work_dir/status.txt"

rm -rf -- "$work_dir"
```

2 回実行しても `status.txt` は 1 行のままである。

この sample では、

```bash
>
```

で「期待する最終状態」を書き直しているため、単純な再実行で duplicate row が増えない。

実際の batch では DB update や external API など、より複雑な idempotency 設計が必要になる場合もあるが、まずは再実行時の結果を意識する。

### 6. Partial failure と二重実行を確認する

partial failure sample を実行する。

```bash
bash examples/operations/04-partial-failure.sh
echo $?
```

3 件中 1 件が failure になるが、残りの item は処理を継続する。

```text
01-ok.txt
→ completed

02-fail.txt
→ failed

03-ok.txt
→ completed
```

最後に failure 件数があるため Script 全体は non-zero で終了する。

この sample では、

```text
個々の item の結果
```

と、

```text
batch 全体の結果
```

を分けて考えている。

どの failure でも即終了する設計が正しいとは限らず、逆に failure を無視して必ず `0` にするのも適切とは限らない。  
batch の目的に合わせて partial failure policy を決める。

次に lock を確認する。

Terminal A で lock を長めに保持する。

```bash
UNIT07_LOCK_HOLD_SECONDS=10 \
  bash examples/operations/05-lock.sh
```

`job finished` が出る前に Terminal B から同じ Script を実行する。

```bash
bash examples/operations/05-lock.sh
```

Terminal B 側は、

```text
another instance is already running
```

として終了する。

Terminal A が終了した後に再度実行すると、lock を取得できる。

```bash
bash examples/operations/05-lock.sh
```

定期実行 interval より処理時間が長くなる可能性がある場合、二重実行を許可するか、lock で防ぐかを意図的に決める。

### 7. systemd service / timer と cron の違いを確認する

systemd 用の sample job を直接実行する。

```bash
bash examples/systemd/01-batch-job.sh
```

この Script 自体は通常の batch Script であり、systemd 専用の Bash syntax を使っているわけではない。

service unit を確認する。

```bash
cat config/systemd/unit07-batch.service
```

主に次の項目を見る。

```text
Type=oneshot
→ 一回処理して終了する service

WorkingDirectory
→ process の working directory

ExecStart
→ 実行する command
```

timer unit を確認する。

```bash
cat config/systemd/unit07-batch.timer
```

```text
OnCalendar
→ schedule

Unit
→ timer が起動する service
```

という役割になっている。

この設定例は `__UNIT07_DIR__` を placeholder にしており、そのまま systemd へ登録する完成設定ではない。  
実際に利用する場合は absolute path へ置き換える。

systemd が利用できる environment では、既存 timer の一覧を確認できる。

```bash
systemctl list-timers
```

WSL 2 の設定や Linux distribution によって systemd の有効化状態は異なるため、command が利用できない場合はこの確認を省略してよい。

cron と systemd timer は、

```text
cron
→ schedule + command

systemd timer
→ schedule を timer unit へ定義
→ service unit を起動
→ systemd の service 管理と連携
```

という構造の違いを大まかに理解する。

## 実行・確認ポイント

### Batch / unattended execution

- 定期実行 Script は user input を待たずに完了できる形にする。
- argument / configuration / environment variable から input を受け取れる。
- 実行結果を exit status と log で後から確認できるようにする。

### cron

- cron daemon が schedule に従って command を起動する。
- user crontab は `crontab -e` / `crontab -l` で扱える。
- 5 field の基本的な意味を確認する。
- schedule syntax の全パターンを暗記する必要はない。
- cron entry の command / path は実際の environment を前提に確認する。

### 実行環境

- cron と interactive shell の environment は同じとは限らない。
- `PATH` によって command resolution が変わる。
- current working directory と Script directory を区別する。
- relative path の基準を明確にする。
- 必須 environment variable は処理前に確認できる。

### Logging

- stdout / stderr を用途に応じて分ける。
- redirect で log file へ保存できる。
- timestamp があると複数回の実行を区別しやすい。
- level を付けると message の種類を追いやすい。
- 後から原因を追跡できる情報を残す。

### 運用を意識した Script

- exit status で job 全体の success / failure を示す。
- timeout で無制限な待機を避ける。
- retry は有限回にする。
- temporary resource は cleanup する。
- 再実行時に duplicate / destructive effect がないか考える。
- partial failure 時の継続方針と最終 exit status を決める。
- 二重実行が問題になる処理では lock を検討する。

### systemd

- service は実行する process / command を定義する。
- timer は service を起動する schedule を定義する。
- cron と systemd timer は同一の仕組みではない。
- systemd は service state / process supervision と統合できる。
- restart policy などの詳細な systemd administration はこの Unit の対象外である。

## 学習ポイント

### 定期実行の難しさは cron syntax より「人間がいないこと」にある

cron の schedule syntax は重要だが、定期実行 Script の問題の多くは schedule の書き方だけでは解決しない。

手動実行では、

```text
error が出る
↓
画面を見る
↓
人間が command を再実行
```

という対応ができる。

cron では、

```text
error が出る
↓
誰も画面を見ていない
↓
次の schedule が来る
```

ことがある。

そのため、

```text
exit status
logging
timeout
retry
cleanup
idempotency
lock
```

といった Unit 04 までの要素が、定期実行で実際の運用上の意味を持つ。

### 「Terminal では動く」は scheduler でも動くことを保証しない

普段の Terminal には、自分が気付かない前提が含まれていることがある。

```text
PATH
current directory
environment variable
shell startup file
alias
function
```

scheduler からの実行では、その一部が存在しない可能性がある。

したがって、

> 自分の Terminal で command が見つかった

ことと、

> Script が必要な実行環境を自分で満たしている

ことは分けて考える。

この観点は cron だけでなく、CI/CD、container、systemd、remote execution などにも共通する。

### Absolute path は目的ではなく、曖昧な前提を減らすための手段

cron の説明では「absolute path を使う」と言われることが多い。

しかし学習上重要なのは、

```text
absolute path を大量に書く
```

ことそのものではない。

重要なのは、

```text
この file path は何を基準に解決されるか
この command はどの PATH から解決されるか
```

を明確にすることである。

Script directory を基準に path を作る方法や、必要な PATH を明示する方法もある。

### Log は「たくさん出す」より「後から判断できる」ことが重要

大量の `echo` を残しても、timestamp や対象 item が分からなければ、定期実行後の調査には使いにくい。

```text
ERROR
```

だけより、

```text
2026-09-26T02:30:04+0900 ERROR item=report.csv upload failed
```

の方が原因を追いやすい。

一方、secret や大量の raw data を log へ出せばよいわけでもない。  
Unit 06 の authentication token と同様、**残すべき情報と残してはいけない情報を区別する**。

### Exit status は無人実行における machine-readable な結果になる

人間に向けた message は理解しやすいが、scheduler や monitoring system が文章を読んで判断するわけではない。

```text
stdout / stderr
→ 人間が後から調査する information

exit status
→ caller が success / failure を判断する information
```

という役割分担を持たせられる。

Shell Script の最後に偶然実行された command の status が job 全体の status にならないよう、処理結果を意識する。

### Idempotency は retry と再実行を安全にする

定期 job は failure すると再実行されることがある。

```text
途中まで成功
↓
failure
↓
再実行
```

という場合、前回の成功部分をもう一度実行しても問題ないかが重要になる。

retry と idempotency は別の概念だが、運用上は強く関係する。

```text
retry できる
+
再実行しても状態が壊れない
↓
failure recovery がしやすい
```

という関係になる。

### Partial failure は「一件失敗した」以上の設計問題

複数 item の batch では、failure が発生した時点で全体を止めるべき場合と、残りを続行した方がよい場合がある。

たとえば独立した log files の archive なら、一 file の failure を記録して残りを続行する判断もあり得る。  
一方、前の処理結果を次の処理が前提にする transaction 的な batch なら、途中継続が危険な場合もある。

つまり、

```text
continue / stop
```

は Shell syntax の問題ではなく、batch の processing model の問題である。

### Lock は二重実行を防ぐが、すべての Script に必要ではない

定期実行 interval が 5 分でも、通常 10 秒で終わる Script なら普段は重複しない。

しかし external service の遅延などで 10 分かかれば、次の schedule と重なる可能性がある。

lock はその競合を防げるが、

- 同時実行しても安全
- read-only
- instance ごとに独立した data を扱う

ような処理では不要な場合もある。

「cron なら必ず `flock`」ではなく、**concurrent execution が何を壊すか**から判断する。

### cron と systemd timer は優劣ではなく運用環境と目的で選ぶ

単純な定期 command なら cron は理解しやすく、広く利用されている。

systemd timer は service unit と組み合わせることで、

```text
schedule
service state
journal
dependency
process management
```

などを systemd の管理へ統合できる。

どちらが常に正しいというものではない。  
既存環境、OS、運用方式、必要な process management に合わせて選択する。

この Unit では「cron を覚えたら systemd は不要」「systemd が新しいから cron は不要」という理解にはしない。

### Unit 07 はこれまでの安全性の学習を運用へ接続する Unit

Unit 07 では新しい Bash syntax を大量に増やすことが目的ではない。

Unit 04 までに学んだ、

```text
exit status
validation
timeout
retry
cleanup
idempotency
lock
```

Unit 05 の、

```text
file / log processing
logging
```

Unit 06 の、

```text
external service
timeout
retry
```

を、

```text
人間がいない状態で
決められた時刻に
繰り返し実行される
```

という条件へ置いたとき、何を考える必要があるかを整理する Unit である。

この考え方は後続の CI/CD でもそのまま利用する。
