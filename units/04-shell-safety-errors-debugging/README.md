# 04. 安全な Shell Script・エラー処理・デバッグ

## この Unit の目的

正常系で動くだけの Script ではなく、不正入力、command failure、異常終了、再実行などを考慮した安全で堅牢な Shell Script の基本を理解する。  
この Unit では、command failure の扱い、`set -euo pipefail`、validation、`trap` と cleanup、idempotency、partial failure、lock、timeout / retry、安全な file・command 操作、secrets、debugging を扱う。  
安全な書き方を記号や定型句として暗記するのではなく、アンチパターン、問題が発生する条件、改善版を比較し、「何を防ぐための処理なのか」「その対策だけでは何を防げないのか」を考えながら学習する。

Unit 01～03 で扱った exit status、signal、stdin / stdout / stderr、pipe、quote、condition、function などを前提として利用する。  
この Unit で扱う安全性は、一つの option を有効にすれば完成するものではない。入力の検証、failure の扱い、cleanup、再実行、二重実行、外部処理の failure、destructive operation、secret、debugging などをそれぞれ考えることを重視する。

## 学習内容

### Command failure と exit status

Shell Script では、command が non-zero で終了しても、Script が自動的に必ず停止するとは限らない。  
failure を明示的に扱わなければ、後続処理が「前の処理は成功した」という前提で進み、別の error や不整合につながる場合がある。

```bash
false
printf '%s\n' 'processing continues'
```

`false` は non-zero を返すが、通常の Bash では後続の `printf` がそのまま実行される。  
そのため、「この command が失敗した場合は何をするか」を Script 側で判断する必要がある。

#### `exit`

`exit` は Script / Shell process 全体を終了し、呼び出し元へ exit status を返す。

```bash
if [[ -z $input ]]; then
  printf '%s\n' 'input is required' >&2
  exit 2
fi
```

どの non-zero value を使うかは Script の設計によるが、`0` を success、non-zero を failure として利用する基本は Unit 01 から共通している。

#### `return`

function 内では `return` を利用して function の status を caller へ返せる。

```bash
validate_value() {
  if [[ ... ]]; then
    return 0
  fi

  return 1
}
```

`return` は function から戻るものであり、`exit` のように Script 全体を終了させるものではない。

#### `&&`

`&&` は左側 command が success の場合だけ右側 command を実行する。

```bash
command1 && command2
```

短い success 条件を表すには便利だが、failure 時の message、cleanup、複数 step などを含む場合は `if` の方が意図を明確にしやすい。

#### `||`

`||` は左側 command が failure の場合だけ右側 command を実行する。

```bash
command || handle_error
```

`|| true` のような書き方で意図的に failure を無視する場合もあるが、「なぜ無視してよいのか」が明確であることが重要である。  
単に Script を止めたくないという理由だけで failure を握りつぶすと、本来検知すべき問題まで見えなくなる。

#### `if command; then`

Shell では command の exit status をそのまま `if` の条件として利用できる。

```bash
if grep -q 'target' "$file"; then
  printf '%s\n' 'found'
else
  printf '%s\n' 'not found'
fi
```

success / failure を判定するためだけに `$?` を別 variable へ保存する必要がなく、どの command の結果を判定しているかも読みやすい。

### `set -e`

`set -e` は、特定の command failure が発生した場合に Shell を終了させる Bash option である。

```bash
set -e
```

単純な例では、次の `false` で Script が終了し、その後の command は実行されない。

```bash
set -e
printf '%s\n' 'before'
false
printf '%s\n' 'after'
```

ただし、`set -e` は「non-zero が一つでも発生したら、どの文脈でも必ずその場で終了する」という単純な仕組みではない。  
`if` の条件、`while` / `until` の条件、`&&` / `||` list、pipeline など、failure が control flow の判定として利用される文脈では挙動が異なる。

たとえば次の `false` は `if` の条件として意図的に評価されている。

```bash
set -e

if false; then
  ...
else
  ...
fi
```

この場合、`false` が non-zero だからという理由だけで Script がそこで終了するわけではない。

そのため、`set -e` を有効にしたから「command failure はすべて自動的に適切に処理される」と考えない。  
重要な command failure については、`if command; then`、`if ! command; then`、`||` などを利用して Script の意図を明示する方が適切な場合がある。

### `set -u`

`set -u` は、未定義 variable を参照したときに error として扱う option である。

```bash
set -u
```

variable 名の typo や、必要な設定値が渡されていない問題に早く気付きやすくなる。

一方、optional な variable まで単純に参照すると error になるため、必要に応じて parameter expansion を利用する。

```bash
optional=${OPTIONAL_VALUE:-}
```

`set -u` は「未定義 variable を許さない」という方針を Script に追加するものであり、値の内容が正しいかまで検証するものではない。

### `set -o pipefail`

通常の pipeline では、pipeline 全体の exit status は基本的に最後の command の status になる。

```bash
false | true
```

この場合、途中の `false` が failure でも、最後の `true` が success のため pipeline 全体は `0` になり得る。

`set -o pipefail` を有効にすると、途中の failure も pipeline の結果へ反映できる。

```bash
set -o pipefail
false | true
```

Unit 02 でも基本挙動を確認したが、この Unit では error handling の観点から改めて扱う。

### `set -euo pipefail`

以下の組み合わせは、一般に strict mode と呼ばれることがある。

```bash
set -euo pipefail
```

概念としては以下を組み合わせている。

```text
-e
→ 一定の command failure で終了

-u
→ 未定義 variable の参照を error にする

-o pipefail
→ pipeline の途中 failure を pipeline 全体へ反映
```

有用な初期設定になり得る一方、これだけで Script が「安全」になるわけではない。

`set -euo pipefail` は、以下を自動的には行わない。

- required argument の意味を検証する
- numeric value の範囲を検証する
- file / directory の種類を検証する
- external dependency の存在を確認する
- temporary file を cleanup する
- 同じ処理の重複実行を防ぐ
- partial failure から安全に再実行できるようにする
- 二重実行を lock する
- external service の timeout / retry を設計する
- destructive operation の対象 path が正しいか確認する
- secret を log へ出さないようにする

したがって strict mode は、安全性を考える出発点の一つではあっても、安全性そのものの代替ではない。

### Validation

Script が処理を始める前に、必要な入力や前提条件を検証することで、途中まで処理した後に失敗する状況を減らせる。

#### Required argument

必須 argument が存在するか確認する。

```bash
input=${1:-}

if [[ -z $input ]]; then
  printf '%s\n' 'input argument is required' >&2
  exit 2
fi
```

単に `$1` を利用し始めるのではなく、入口で不足を検知する。

#### Option

`getopts` などを利用する場合は、unknown option や option argument の不足も error として扱う。

```bash
while getopts ':n:' option; do
  ...
done
```

Unit 03 で構文を学んだ `getopts` を、ここでは invalid input を拒否する validation の観点から利用する。

#### Numeric value

argument が存在していても、期待する format であるとは限らない。

```bash
if [[ ! $number =~ ^[0-9]+$ ]]; then
  ...
fi
```

さらに実用上は、「integer であるか」だけでなく許容範囲まで確認する場合もある。  
この Unit では numeric format の基本的な validation まで扱う。

#### File / directory

path を受け取った場合は、存在だけでなく期待する種類かも確認する。

```bash
[[ -f $input_file ]]
[[ -d $output_dir ]]
```

たとえば input として directory が渡されたのに regular file を前提に処理を続けると、後続 command で分かりにくい failure が発生する可能性がある。

#### Environment variable

必須 environment variable は処理開始時に確認できる。

```bash
: "${UNIT04_CONFIG:?UNIT04_CONFIG is required}"
```

`:` は何もしない command として利用でき、その argument で parameter expansion を評価する。  
必須設定がない場合に早い段階で failure にできる。

#### Dependency

外部 command を利用する Script では、その command が実行環境に存在することを前提にしている。

```bash
if ! command -v grep > /dev/null 2>&1; then
  printf '%s\n' 'required command not found: grep' >&2
  exit 1
fi
```

`command -v` により dependency の存在を先に確認すると、処理途中の `command not found` よりも失敗理由を明確にできる。

### Cleanup と `trap`

temporary file / directory などを作成する Script では、正常終了時だけでなく error や signal による終了時にも cleanup が必要になる場合がある。

```bash
temp_dir=$(mktemp -d)
```

最後に単純な `rm` を置くだけでは、その行へ到達する前に Script が終了した場合に temporary data が残る可能性がある。

#### Cleanup function

cleanup 処理を function へまとめる。

```bash
cleanup() {
  rm -f -- "$temp_file"
  rmdir -- "$temp_dir" 2> /dev/null || true
}
```

cleanup を一か所に集約すると、正常終了・error・signal ごとに同じ削除処理を重複して書かずに済む。

#### `trap ... EXIT`

`EXIT` trap を設定すると、Shell が終了するときに cleanup function を呼び出せる。

```bash
trap cleanup EXIT
```

正常終了だけでなく `exit` で終了する場合などにも cleanup を実行できる。

ただし、`SIGKILL` のように process 側で捕捉できない signal では trap を実行できない。  
「trap を設定したから、どの異常終了でも必ず cleanup される」とは考えない。

#### Signal handler

signal を受けたときの処理を定義できる。

```bash
trap handle_term TERM
```

signal handler 内で cleanup を直接行う設計も可能だが、今回のサンプルでは signal handler が `exit` し、`EXIT` trap に cleanup を一元化する。

```text
SIGTERM
↓
handle_term
↓
exit 143
↓
EXIT trap
↓
cleanup
```

signal と process の基本は Unit 01 で扱った内容とつながる。

### Idempotency と再実行性

batch や運用 Script では、「一度成功すること」だけでなく、「同じ Script を再実行したらどうなるか」を考える必要がある。

idempotency は、同じ操作を複数回行っても、意図する最終状態が不必要に変化しない性質として考える。

たとえば、設定行を毎回無条件に追記する処理では、

```bash
printf '%s\n' 'feature.enabled=true' >> config
```

再実行するたびに同じ行が増える。

一方、既に存在する場合は追加しないようにすれば、同じ最終状態を保ちやすい。

```bash
if ! grep -qxF -- "$line" "$target"; then
  printf '%s\n' "$line" >> "$target"
fi
```

すべての処理を完全に idempotent にできるとは限らないが、再実行時に何が重複するかを考えることが重要である。

### Partial failure

複数 step からなる Script は、途中まで成功してから failure する可能性がある。

```text
step 1 success
↓
step 2 failure
↓
Script stopped
```

この状態で Script を最初から再実行したとき、step 1 をもう一度実行して問題ないかを考える必要がある。

対応方法には、たとえば以下のような考え方がある。

- 各 step 自体を idempotent にする
- 完了済み状態を確認する
- marker や外部状態を確認して skip する
- transaction を利用できる処理では transaction を利用する
- 途中まで作成したものを rollback / cleanup する

この Unit のサンプルでは marker file を使い、step 1 完了後に failure しても、再実行時に step 1 を重複実行しない基本を確認する。

### 二重実行と lock

cron や batch job では、前回実行がまだ終わっていないのに次回実行が開始されるなど、同じ Script が同時に複数動く可能性がある。

```text
job A ────────────────
        job B ────────────────
```

同じ file や DB record を同時に更新すると、重複処理や競合につながる場合がある。

#### `flock`

Linux では `flock` を利用して lock を取得できる。

```bash
exec 9> "$lock_file"
flock -n 9
```

今回のサンプルでは fd 9 に lock file を接続し、最初の process が lock を保持している間に別 process が同じ lock を non-blocking で取得しようとして失敗することを確認する。

`-n` は lock を取得できない場合に待ち続けず failure にする。

```bash
flock -n ...
```

高度な lock 設計、lock file の配置戦略、長時間待機などはこの Unit では扱わず、「二重実行を防ぐために lock という考え方がある」ことと `flock` の基本までを扱う。

### 外部処理の failure

network、external service、別 process などに依存する処理では、failure だけでなく「応答が返らない」「一時的に失敗する」という状態も考える必要がある。

#### Timeout

外部処理が無制限に待ち続けると、その Script や batch 全体が終了しない可能性がある。

GNU `timeout` command を利用すると、実行時間の上限を設けられる。

```bash
timeout 10 command
```

timeout によって終了した場合、代表的には status `124` が返る。  
ただし、実際の status の扱いは command や option によって確認する必要がある。

#### Retry

一時的な failure で成功する可能性がある処理では retry が有効な場合がある。

```text
attempt 1 → failure
attempt 2 → failure
attempt 3 → success
```

ただし無制限 retry は Script が終わらなくなるため、retry 回数を決める。

```bash
max_attempts=3
```

retry するべき failure と、すぐ中断すべき permanent failure を区別することも実務では重要になる。

#### `sleep`

retry 間に `sleep` を入れることで、failure した処理を即座に連打することを避けられる。

```bash
sleep 1
```

#### Simple backoff

retry の回数に応じて待ち時間を増やす考え方が backoff である。

```text
1 回目 failure → 1 秒待つ
2 回目 failure → 2 秒待つ
3 回目 ...
```

この Unit では delay を単純に増やす基本だけを扱う。  
exponential backoff、jitter など高度な戦略は対象外とする。

### 安全な file・command 操作

Shell Script では path や argument の扱いを誤ると、意図しない対象を操作する可能性がある。  
特に `rm` などの destructive operation では、「command が成功するか」だけでなく「何を対象として実行しようとしているか」が重要である。

#### Quote

Unit 03 で確認したとおり、variable を一つの argument として扱う場合は double quote を基本とする。

```bash
rm -f -- "$file"
```

unquoted variable では word splitting や pathname expansion が発生する可能性がある。

空文字も考慮する。

```bash
value=''
```

unquoted の empty expansion は argument として消える場合があるが、`"$value"` なら empty string という一つの argument を保持する。

#### `--`

command によっては、`-` から始まる operand が option として解釈される可能性がある。

```text
-temporary.txt
```

多くの command では `--` を利用して、「ここから先は option ではない」と明示できる。

```bash
rm -- '-temporary.txt'
```

すべての command が `--` を同じように提供するとは限らないため、対象 command の仕様は確認する必要がある。  
この Unit では `rm`、`touch` など GNU/Linux で一般的な command を前提に基本を確認する。

#### Wildcard

destructive operation に glob を利用する場合、どの directory に対して pattern を展開するかを明確にする。

```bash
rm -f -- "$target_dir"/*.tmp
```

ここでは固定部分の `"$target_dir"` を quote し、`*.tmp` だけを Shell の pathname expansion に任せている。

現在の working directory で不用意に以下のような command を実行するより、対象範囲を狭める方が意図を確認しやすい。

```bash
rm -f -- *.tmp
```

#### Empty value

destructive operation の対象 path が empty になった場合に、組み立て方によっては想定外の path を表す可能性がある。  
そのため、重要な操作では対象値が empty でないことを事前に確認する。

```bash
if [[ -z $target ]]; then
  ...
fi
```

#### Destructive operation

`rm -rf` のような destructive operation では、実行直前に対象 path を validation する。

```bash
if [[ -z $target || $target == / ]]; then
  return 1
fi
```

さらに、今回のサンプルでは削除対象が期待する parent directory の配下であることも確認している。

```bash
if [[ $target != "$expected_parent"/* ]]; then
  return 1
fi
```

このような guard は例であり、実際にどの条件を確認すべきかは Script の責任範囲によって異なる。  
重要なのは destructive command を単独の一行として考えず、その前に対象の妥当性を確認することである。

#### Working directory

relative path を利用する Script は current working directory に依存する。

```bash
rm -f generated/*
```

想定外の directory から実行すると、別の対象を操作する可能性がある。  
対策として、Script 自身の directory から absolute path を組み立てる方法や、marker file などで working directory を確認する方法がある。

この Unit のサンプルでは `.unit04-project` という marker file を使い、想定外 directory では操作を拒否する考え方を確認する。

### Secrets

password、API token、private key などの secret を Script source に直接 hard-code すると、Git repository、review、backup、log などを通じて漏えいする危険がある。

```bash
# 避ける
API_TOKEN='real-secret-value'
```

実際の利用環境では、用途に応じて以下のような外部経路から渡す。

- environment variable
- permission を制限した configuration / secret file
- CI/CD の secret 機能
- secret management service

この Unit のサンプルでは environment variable から受け取る基本だけを実行する。

```bash
: "${API_TOKEN:?API_TOKEN is required}"
```

重要なのは、「environment variable なら常に完全に安全」ということではない。  
process の環境、debug log、CI 設定などから見える可能性もあるため、secret の保管・受け渡し方法は利用環境に合わせて考える。

#### `set -x` と secret

`set -x` や `bash -x` は実行時の展開後 argument を stderr へ trace する。

```bash
set -x
command "$API_TOKEN"
```

この場合、secret が trace に含まれる可能性がある。

そのため secret を扱う箇所では、

```bash
set +x
```

で xtrace を止める、そもそも secret を command-line argument へ出さない、CI log の扱いを確認するなどの対策が必要になる。

この Unit では real secret を一切使用せず、dummy secret を使って trace への露出を確認する。

### Debugging

安全な Script を作るには、failure を防ぐだけでなく、問題が発生したときに原因を切り分けられることも重要である。

#### `bash -n`

`bash -n` は Script を実行せず syntax check を行う。

```bash
bash -n script.sh
```

`if` の `fi` がない、quote が閉じていないなどの syntax error を実行前に検知できる。

ただし、`bash -n` が成功しても runtime error、invalid input、external command failure などがないことを保証するわけではない。

#### `bash -x`

`bash -x` は Script を xtrace 有効状態で実行する。

```bash
bash -x script.sh
```

Bash が実際に実行する command と expansion 後の value を stderr に表示するため、どの argument が渡っているか、どの branch に入ったかなどを追いやすい。

source code の単純な表示ではなく、「実行時にどう展開されたか」を観察する点が重要である。

#### `set -x` / `set +x`

Script の一部分だけ trace したい場合は、以下のように切り替えられる。

```bash
set -x
...
set +x
```

Script 全体を `bash -x` で実行するより、問題のある範囲を絞って trace できる。

ただし、前述のとおり secret や個人情報などが trace に出る可能性があるため、debugging の利便性と log に出してよい data を分けて考える。

#### Debug output

必要な箇所へ temporary な debug output を追加する方法もある。

```bash
printf 'DEBUG: value=%s\n' "$value" >&2
```

正常な stdout data と混ぜたくない場合は stderr を利用する。

恒久的な diagnostic output が必要なら、`DEBUG=true` などの flag で有効化する方法もある。

#### 段階的な切り分け

問題が起きたとき、Script 全体を一度に推測するより処理単位で確認する。

```text
入力は正しいか
↓
validation は通っているか
↓
step 1 は success か
↓
step 2 は success か
↓
期待する file / output は作られたか
```

function や step ごとに status を確認し、どこまで正常だったかを絞る。  
`bash -n`、`bash -x`、debug output、exit status、temporary な確認 command などを目的に応じて組み合わせる。

### この Unit で軽く扱う内容

`flock` については single lock の基本的な取得・解放と、二重実行を拒否する考え方までを扱う。  
shared / exclusive lock の高度な使い分け、複数 resource の lock 順序などは対象外とする。

retry については最大回数、`sleep`、単純な backoff までを扱う。  
exponential backoff、jitter、service-specific な retry policy など高度な戦略は対象外とする。

## 使用するもの

この Unit では、主に以下を利用する。

- WSL 2 上の Linux
- Bash
- `printf`
- `false`
- `grep`
- `getopts`
- `command -v`
- `mktemp`
- `trap`
- `sleep`
- `flock`
- `timeout`
- `rm`
- `rmdir`
- `touch`
- `find`
- `wc`
- `bash -n`
- `bash -x`
- `set -x`
- `set +x`

`flock` と `timeout` は一般的な Linux 環境で利用される command であり、この Unit のサンプルでは実行前に存在を確認する。  
追加の network access や外部 service は使用せず、failure / retry / timeout は local process で安全に再現する。

## 事前準備

Unit 01～03 が完了し、以下の基本を確認済みであることを前提とする。

- process / signal / exit status
- stdin / stdout / stderr
- pipe / `pipefail`
- path / permission / temporary file
- variable / parameter expansion
- quote
- `if` / `case`
- loop
- function / `return` / `exit`
- `getopts`

Bash を確認する。

```bash
bash --version
```

`flock` と `timeout` が利用できることを確認する。

```bash
command -v flock
command -v timeout
```

リポジトリ root から Unit 04 へ移動する。

```bash
cd units/04-shell-safety-errors-debugging
```

成果物を確認する。

```bash
find . -maxdepth 3 -type f | sort
```

以下の構成になっていることを確認する。

```text
04-shell-safety-errors-debugging/
├─ README.md
└─ examples/
   ├─ cleanup/
   │  ├─ 01-trap-exit-cleanup.sh
   │  └─ 02-trap-signal-cleanup.sh
   ├─ command-failure/
   │  ├─ 01-ignore-vs-handle-failure.sh
   │  ├─ 02-and-or.sh
   │  ├─ 03-if-command.sh
   │  └─ 04-return-and-exit.sh
   ├─ debugging/
   │  ├─ 01-bash-n.sh
   │  ├─ 02-bash-x.sh
   │  ├─ 03-set-x-set-plus-x.sh
   │  └─ 04-stepwise-isolation.sh
   ├─ idempotency/
   │  ├─ 01-duplicate-vs-idempotent.sh
   │  └─ 02-partial-failure-rerun.sh
   ├─ locking/
   │  └─ 01-flock.sh
   ├─ retry/
   │  ├─ 01-timeout.sh
   │  ├─ 02-limited-retry.sh
   │  └─ 03-simple-backoff.sh
   ├─ safe-operations/
   │  ├─ 01-quote-and-empty-value.sh
   │  ├─ 02-double-dash.sh
   │  ├─ 03-wildcard-scope.sh
   │  ├─ 04-destructive-operation-guard.sh
   │  └─ 05-working-directory-check.sh
   ├─ secrets/
   │  ├─ 01-secret-input.sh
   │  └─ 02-xtrace-secret-risk.sh
   ├─ strict-mode/
   │  ├─ 01-set-e.sh
   │  ├─ 02-set-u.sh
   │  ├─ 03-pipefail.sh
   │  └─ 04-strict-mode-not-magic.sh
   └─ validation/
      ├─ 01-required-argument.sh
      ├─ 02-option-and-numeric.sh
      ├─ 03-file-and-directory.sh
      └─ 04-environment-and-dependency.sh
```

この Unit のサンプルは、意図的に failure や危険になり得る条件を再現する。  
ただし、実際の user data や repository 内の重要 file を削除しないよう、temporary directory、dummy value、child Bash などに対象を限定している。

学習中も、サンプルを変更するときは実際の home directory や repository root へ `rm -rf` などの destructive operation を向けない。  
特に path validation や wildcard のサンプルは、用意された temporary directory の範囲で確認する。

## 学習・実践

### 1. Command failure を明示的に扱う

まず、failure を無視する処理と明示的に扱う処理を比較する。

```bash
bash examples/command-failure/01-ignore-vs-handle-failure.sh
```

前半では child Bash 内で `false` が failure しても、後続の `processing continued after failure` が実行される。  
通常の Bash は、単に command が non-zero になっただけでは必ず Script を停止するわけではない。

後半では `if false; then ... else ... fi` を利用し、failure branch へ入り、status を stderr に出している。

この比較では、

```text
command failure
≠
Script が自動的に適切な error handling を行う
```

という点を確認する。

次に `&&` / `||` を確認する。

```bash
bash examples/command-failure/02-and-or.sh
```

`true && ...` では右側が実行され、`false || ...` でも右側が実行される。

概念として以下を確認する。

```text
A && B
→ A success のとき B

A || B
→ A failure のとき B
```

短い条件付き実行には便利だが、複雑な failure handling を一行へ詰め込みすぎないことも重要である。

`if command; then` の基本を確認する。

```bash
bash examples/command-failure/03-if-command.sh
```

最初は empty temporary file のため `grep -q 'target'` が failure し、`target not found` が表示される。  
その後 file に `target value` を書き込み、2 回目の `grep` は success になる。

`grep` の exit status を直接 `if` の条件として利用している点に注目する。

最後に `return` と `exit` を再確認する。

```bash
bash examples/command-failure/04-return-and-exit.sh
```

`validate_number` は numeric なら `return 0`、それ以外なら `return 1` を返す。  
function の success / failure を `if` から直接利用できる。

child Bash 内の `exit 7` は child process 自体を終了し、parent Script では `child exit status=7` と確認できる。

### 2. `set -e`・`set -u`・`pipefail` と strict mode を確認する

まず `set -e` の単純なケースと例外的な文脈を比較する。

```bash
bash examples/strict-mode/01-set-e.sh
```

最初の child Bash では、

```bash
set -e
false
```

により `false` の後ろへ進まず、child の status が `1` になる。

一方、次の child Bash では `false` が `if` の condition にある。

```bash
if false; then
  ...
else
  ...
fi
```

ここでは `failure handled by if` が表示され、その後 `shell continues` まで実行される。

この結果から、`set -e` を「non-zero が出たら常に即終了する」と単純化しすぎない。

次に `set -u` を確認する。

```bash
bash examples/strict-mode/02-set-u.sh
```

未定義の `UNDEFINED_VALUE` を直接参照した child Bash は non-zero で終了する。  
一方、

```bash
"${OPTIONAL_VALUE:-}"
```

では optional な未定義 variable を empty value として扱える。

続いて `pipefail` を確認する。

```bash
bash examples/strict-mode/03-pipefail.sh
```

同じ `false | true` でも、

```text
without pipefail=0
with pipefail=1
```

となることを確認する。

最後に `set -euo pipefail` を利用した Script を確認する。

```bash
bash examples/strict-mode/04-strict-mode-not-magic.sh
```

default では `required_value=default-value` が表示される。

environment variable を指定して実行してもよい。

```bash
REQUIRED_VALUE='configured' bash examples/strict-mode/04-strict-mode-not-magic.sh
```

strict mode が有効でも Script 自身で validation を記述している点に注目する。  
strict mode は入力の意味や destructive operation の対象などを自動判断してくれるものではない。

### 3. 入力・file・environment・dependency を validation する

required argument を確認する。

正常系を実行する。

```bash
bash examples/validation/01-required-argument.sh sample-input
```

次に argument なしで実行する。

```bash
bash examples/validation/01-required-argument.sh
```

`input argument is required` と usage が stderr に表示され、non-zero で終了する。  
Script の本処理を始める前に入口で不足を検知している。

option と numeric value を確認する。

```bash
bash examples/validation/02-option-and-numeric.sh -n 42
```

正常系では `number=42` が表示される。

numeric ではない値も試す。

```bash
bash examples/validation/02-option-and-numeric.sh -n abc
```

`number must be a non-negative integer` として拒否される。

option argument がない場合も確認する。

```bash
bash examples/validation/02-option-and-numeric.sh -n
```

`getopts` による syntax-level な option validation と、その後の numeric format validation が別の役割であることを確認する。

file / directory validation を実行する。

```bash
bash examples/validation/03-file-and-directory.sh
```

サンプル自身が temporary な regular file と directory を作成し、それぞれ `-f` / `-d` で期待する種類か確認する。

最後に environment variable と dependency を確認する。

environment variable を指定して実行する。

```bash
UNIT04_CONFIG='demo-config' bash examples/validation/04-environment-and-dependency.sh
```

`UNIT04_CONFIG` が表示され、`grep` dependency が利用可能であることを確認できる。

environment variable を指定しない場合も確認する。

```bash
bash examples/validation/04-environment-and-dependency.sh
```

`${UNIT04_CONFIG:?UNIT04_CONFIG is required}` によって早い段階で failure になる。

この一連のサンプルでは、

```text
argument があるか
option が正しいか
値の format が正しいか
file / directory が期待する種類か
environment があるか
dependency があるか
```

を別々の validation として考える。

### 4. `trap` で normal / abnormal exit の cleanup をまとめる

まず `EXIT` trap の基本を確認する。

```bash
bash examples/cleanup/01-trap-exit-cleanup.sh
```

temporary file の path が `created=...` と表示される。  
Script の終了時に `trap cleanup EXIT` が実行され、temporary file / directory が削除される。

出力された path を使って、終了後に file が存在しないことを確認してもよい。

```bash
test ! -e <表示された temporary file path> && printf '%s\n' 'cleaned'
```

次に signal と cleanup を確認する。  
この確認では Terminal を 2 つ利用する。

Terminal A で待機 mode を有効にする。

```bash
UNIT04_WAIT_FOR_SIGNAL=true bash examples/cleanup/02-trap-signal-cleanup.sh
```

以下のように PID と temporary directory が表示される。

```text
PID=<PID> temp_dir=<temporary directory>
```

Terminal B から、その学習用 PID にだけ `SIGTERM` を送る。

```bash
kill -TERM <PID>
```

Terminal A に `received SIGTERM` が表示され、Script が終了する。

表示されていた temporary directory が cleanup されたことを確認する。

```bash
test ! -e <temporary directory> && printf '%s\n' 'cleaned'
```

この流れでは、

```text
SIGTERM
→ handle_term
→ exit 143
→ EXIT trap
→ cleanup
```

となっている。

signal handler ごとに cleanup を複製するのではなく、終了経路を `EXIT` trap へ集約する一つの設計例として読む。

### 5. Idempotency と partial failure 後の再実行を確認する

まず、同じ処理を 2 回実行した場合の違いを比較する。

```bash
bash examples/idempotency/01-duplicate-vs-idempotent.sh
```

結果として以下を確認する。

```text
non-idempotent count=2
idempotent count=1
```

`append_without_check` は既存状態を確認せず追記するため、2 回呼ぶと同じ設定行が 2 行になる。

`ensure_line_once` は、

```bash
grep -qxF -- "$line" "$target"
```

で既存状態を確認し、存在しない場合だけ追加する。

ここでは「同じ function を何度呼んでもまったく同じ command が実行される」ことではなく、**意図する最終状態が重複しない**ことに注目する。

次に partial failure と再実行を確認する。

```bash
bash examples/idempotency/02-partial-failure-rerun.sh
```

1 回目の `run_job true` は step 1 を完了した後、意図的に failure を返す。

```text
running step 1
simulated failure after step 1
first run failed as expected
```

その後、2 回目の `run_job false` では step 1 marker が既に存在するため、

```text
step 1 already completed
running step 2
```

という流れになる。

実運用では marker file が常に最適とは限らないが、

```text
途中 failure
↓
どこまで完了したか
↓
再実行時に何をもう一度してよいか
```

を考える基本例として確認する。

### 6. `flock` で二重実行を防ぐ考え方を確認する

`flock` の基本を実行する。

```bash
bash examples/locking/01-flock.sh
```

最初に fd 9 を lock file へ接続する。

```bash
exec 9> "$lock_file"
```

その fd に対して non-blocking lock を取得する。

```bash
flock -n 9
```

最初の lock が取得された状態で、別 process が同じ lock file に対して `flock -n` を実行する。  
2 回目は lock を取得できず、

```text
second execution blocked by lock
```

が表示される。

このサンプルは、cron や batch で同じ Script が重なって起動したときに「同時に本処理へ進ませない」という考え方を小さく再現している。

この Unit では `flock` の高度な option や複雑な lock 設計には進まない。  
まず、

```text
二重実行が問題になる処理
↓
共有する lock 対象を決める
↓
本処理前に lock を取得
↓
取得できなければ重複実行を拒否
```

という流れを理解する。

### 7. Timeout・retry・simple backoff を確認する

まず timeout を確認する。

```bash
bash examples/retry/01-timeout.sh
```

サンプルでは、

```bash
timeout 1 bash -c 'sleep 2'
```

を実行している。

`sleep 2` は 1 秒以内に終了しないため `timeout` によって停止され、代表的な status `124` が表示される。

```text
command timed out or failed: status=124
```

外部処理を呼ぶ場合は「failure status を返す」だけでなく、「いつまでも戻らない」という failure mode も存在することを確認する。

次に回数制限付き retry を実行する。

```bash
bash examples/retry/02-limited-retry.sh
```

学習用 `unstable_command` は最初の 2 回 failure、3 回目 success になる。

```text
failed attempt=1
failed attempt=2
succeeded on attempt=3
```

`max_attempts=3` によって retry が無制限にならないようにしている。

最後に simple backoff を確認する。

```bash
bash examples/retry/03-simple-backoff.sh
```

failure 後の待機時間が、

```text
1 秒
2 秒
```

のように増える。

この Unit では、単純に delay を増やす仕組みを通して backoff の考え方だけを確認する。  
すべての failure を retry すべきではなく、invalid input や authentication failure など、retry しても改善しない failure もあることを意識する。

### 8. File・command の destructive operation を安全に扱う

まず quote と empty value を比較する。

```bash
bash examples/safe-operations/01-quote-and-empty-value.sh
```

unquoted の場合、

```bash
show_arguments $value $empty
```

`alpha beta` が word splitting され、empty value は argument として消える。

double quote した場合、

```bash
show_arguments "$value" "$empty"
```

空白を含む値も empty value も、それぞれ明示的な argument として保持される。

Unit 03 で学んだ quote を、この Unit では安全な command invocation の観点から再確認する。

次に `--` を確認する。

```bash
bash examples/safe-operations/02-double-dash.sh
```

temporary directory 内に `-temporary.txt` を作成し、

```bash
rm -- '-temporary.txt'
```

で安全に operand として渡している。

`-` から始まる filename を option と誤解させないための基本として読む。

wildcard の対象範囲を確認する。

```bash
bash examples/safe-operations/03-wildcard-scope.sh
```

削除対象は、

```bash
"$target_dir"/*.tmp
```

に限定されている。

実行結果では、

```text
target tmp count=0
other tmp count=1
```

となり、`target` 配下の `.tmp` だけ削除され、別 directory の `do-not-touch.tmp` は残る。

destructive operation の guard を確認する。

```bash
bash examples/safe-operations/04-destructive-operation-guard.sh
```

`rm -rf` の前に、

- empty ではない
- `/` ではない
- expected parent の配下である

ことを確認している。

この validation が通った学習用 temporary directory だけを削除し、

```text
validated target removed
```

が表示される。

最後に working directory の確認を行う。

```bash
bash examples/safe-operations/05-working-directory-check.sh
```

`other` directory では `.unit04-project` marker がないため操作を拒否する message が stderr に出る。  
`project` directory では marker が存在するため working directory が妥当と判断される。

このサンプルは、relative path に依存する destructive operation の前に「今どこにいるか」を確認する考え方を示している。

### 9. Secret を source / xtrace から守る

まず environment variable から secret を受け取る基本を確認する。  
ここでは必ず dummy value を使う。

```bash
API_TOKEN='dummy-token' bash examples/secrets/01-secret-input.sh
```

Script は token 自体を表示せず、設定されていることと長さだけを表示する。

```text
API_TOKEN is set (length=...)
```

environment variable を指定しない場合も確認する。

```bash
bash examples/secrets/01-secret-input.sh
```

`${API_TOKEN:?API_TOKEN is required}` によって failure になる。

実際の password / token をこの学習リポジトリの source code や command history に入力する必要はない。  
学習では必ず dummy value を利用する。

次に xtrace に secret が出る危険を確認する。

```bash
bash examples/secrets/02-xtrace-secret-risk.sh
```

この Script では `DEMO_TOKEN='dummy-secret-for-learning'` という dummy value だけを利用する。

`set -x` が有効な状態で secret を argument として利用すると、展開後の値が trace に含まれる。  
temporary trace file から dummy secret を `grep` し、実際に trace へ含まれていることを確認する。

この結果から、

```text
debugging を有効にする
↓
便利
↓
ただし展開後の secret まで stderr / CI log に出る可能性
```

という trade-off を理解する。

### 10. `bash -n`・`bash -x`・debug output で問題を切り分ける

まず `bash -n` の syntax check を確認する。

```bash
bash examples/debugging/01-bash-n.sh
```

Script 内で一時的に `valid.sh` と `invalid.sh` を作成する。

`valid.sh` は syntax check に成功し、

```text
valid.sh syntax OK
```

が表示される。

`invalid.sh` は `fi` が欠けており、

```text
invalid.sh syntax error detected
```

となる。

`bash -n` は Script を実際に実行して動作を確認するものではなく、syntax error を検出する手段であることを区別する。

次に `bash -x` を確認する。

```bash
bash examples/debugging/02-bash-x.sh
```

内部の child Bash が xtrace mode で実行され、`name` や `message` の代入、展開後の `printf` などが stderr に表示される。

trace と通常 stdout が同じ Terminal に見える場合でも、

```text
xtrace
→ stderr

通常の printf
→ stdout
```

という違いがある。

部分的な xtrace を確認する。

```bash
bash examples/debugging/03-set-x-set-plus-x.sh
```

`set -x` から `set +x` までの範囲だけ trace される。  
その後の dummy secret を扱う行では trace が無効になっている。

最後に debug output を利用した段階的な切り分けを確認する。

通常実行する。

```bash
bash examples/debugging/04-stepwise-isolation.sh
```

次に debug output を有効にする。

```bash
DEBUG=true bash examples/debugging/04-stepwise-isolation.sh
```

`DEBUG=true` の場合は各 step の開始が stderr に表示される。

```text
DEBUG: step_one started
DEBUG: step_two started
```

`step_two` が failure することを明示的に検知し、`step_three` へ進まない。

問題があるときは、Script 全体を闇雲に書き換えるのではなく、

```text
syntax
↓
input
↓
step 1
↓
step 2
↓
external command
↓
output / state
```

のように段階を分け、どこまで期待どおりかを確認する。

## 実行・確認ポイント

### Command failure

- command が non-zero になっても、通常の Bash では必ず Script が停止するわけではない。
- `exit` は Script / Shell process 全体を終了する。
- `return` は function から caller へ status を返す。
- `&&` は左側 success、`||` は左側 failure の場合に右側を実行する。
- `if command; then` で command の exit status を直接 control flow に利用できる。
- 重要な failure は、Script の意図に合わせて明示的に処理する。

### `set` / strict mode

- `set -e` は便利だが、すべての non-zero をどの文脈でも同じように扱うわけではない。
- `set -u` は未定義 variable の参照を error として扱う。
- `set -o pipefail` は pipeline の途中 failure を pipeline 全体へ反映する。
- `set -euo pipefail` は有用な組み合わせだが、validation や cleanup などを自動化するものではない。
- strict mode を有効にしただけで Script の安全性が完成するわけではない。

### Validation

- required argument は本処理前に確認する。
- option syntax と option value の妥当性は別々に考えられる。
- numeric value は存在だけでなく期待する format か確認する。
- path は regular file / directory など期待する種類か確認する。
- 必須 environment variable は早い段階で検証できる。
- `command -v` で external dependency の存在を確認できる。

### Cleanup

- temporary file / directory は正常終了時だけでなく異常終了も考慮する。
- cleanup function に削除処理をまとめられる。
- `trap cleanup EXIT` で Shell 終了時に cleanup を実行できる。
- signal handler から `exit` し、`EXIT` trap に cleanup を一元化する設計ができる。
- `SIGKILL` など trap できない終了もあるため、cleanup は絶対保証ではない。

### 再実行性

- 同じ Script を複数回実行したときに重複 data が増えないか考える。
- 既存状態を確認して必要な操作だけ行うことが idempotency につながる。
- partial failure では、どこまで完了しているかを考える。
- 再実行時に完了済み step を重複させない設計が必要な場合がある。

### 二重実行

- 同じ batch / Script が同時に複数動く可能性を考える。
- shared resource を扱う処理では二重実行が問題になる場合がある。
- `flock` で lock を取得し、重複実行を拒否できる。
- この Unit では `flock` の基本だけを扱う。

### Timeout / Retry

- external process がいつまでも戻らない場合に timeout が必要になる。
- retry は回数上限を設ける。
- retry 間に `sleep` を入れられる。
- backoff により retry ごとの待ち時間を増やせる。
- すべての failure が retry に適しているわけではない。

### 安全な file / command 操作

- variable を一つの argument として扱う場合は quote を基本とする。
- empty value も command の意味を変える可能性がある。
- `--` で `-` から始まる operand を option と区別できる command がある。
- destructive operation の wildcard は対象 directory を明示して scope を狭くする。
- `rm -rf` などの前に target path を validation する。
- relative path を利用する場合は working directory の前提を意識する。

### Secrets

- password / token を Script source に hard-code しない。
- environment variable、secret file、CI secrets など外部から渡す方法がある。
- environment variable も無条件に安全という意味ではない。
- `bash -x` / `set -x` は展開後の secret を stderr / log に出す可能性がある。
- debugging 時も secret の境界を意識する。

### Debugging

- `bash -n` で実行せず syntax check ができる。
- `bash -x` で実行時の expansion と command を trace できる。
- `set -x` / `set +x` で trace 対象範囲を限定できる。
- debug output は stderr に分けることができる。
- 問題は処理単位で success / failure を確認し、段階的に切り分ける。

## 学習ポイント

### 「正常系で動く」と「安全に失敗できる」は別の性質

Script が正しい input で一度成功することは重要だが、それだけでは運用上安全とは言えない。

実際には、

```text
argument がない
file がない
dependency がない
command が failure
network / external process が戻らない
途中まで処理して failure
同じ Script が二重起動
再実行
予期しない path
secret を含んだ debug log
```

などが発生する。

安全な Script を考えるときは、「成功時に何をするか」と同じ程度に「失敗したときにどういう状態を残すか」を考える。

### Error handling は failure を隠すことではなく、failure の意味を決めること

`|| true` を付ければ command failure を無視できる場合がある。  
しかし、それは error handling ができたことを意味しない。

重要なのは、その failure が、

```text
想定内
→ 継続してよい

retry 可能
→ 回数制限付きで再試行

recoverable
→ cleanup / rollback して継続または終了

fatal
→ message を出して終了
```

のどれなのかを Script 側で判断することである。

failure を無条件に握りつぶすと、本来停止すべき処理まで成功したように見える可能性がある。

### `set -euo pipefail` は policy の一部であり、設計の代わりではない

strict mode は typo、未定義 variable、pipeline failure などを見つけやすくできる。  
しかし、Script の目的や input の意味は理解できない。

たとえば、

```bash
set -euo pipefail
rm -rf -- "$target"
```

と書いても、`target` が本当に削除すべき directory かは strict mode には分からない。

同様に、

```text
required argument の意味
再実行の安全性
二重実行
timeout
retry policy
secret management
```

も strict mode では解決しない。

したがって、

```text
Shell option
+
explicit validation
+
explicit failure handling
+
cleanup
+
state / rerun design
```

のように複数の観点を組み合わせる。

### `set -e` の難しさは「failure を control flow に使う Shell」と関係している

Shell では command の success / failure 自体が `if`、`while`、`&&`、`||` などの control flow に利用される。

```bash
if grep -q pattern file; then
  ...
fi
```

この `grep` の non-zero は、必ずしも「予期しない異常」ではない。  
「pattern がなかった」という condition として意図的に利用している。

そのため、`set -e` はすべての non-zero を同じように fatal error として扱うわけではない。

この特徴を理解すると、

> `set -e` があるから failure handling を書かなくてよい

ではなく、

> `set -e` を使いつつ、意味のある success / failure は control flow に明示する

という考え方がしやすくなる。

### Validation は「できるだけ早く、具体的な理由で失敗させる」ためにある

validation がない Script は、入力の問題が後続 command の failure として現れることがある。

```text
本当の原因:
input file がない

後で発生する error:
grep: file not found
```

入口で、

```bash
if [[ ! -f $input_file ]]; then
  ...
fi
```

と確認すれば、「必要な input file がない」という本来の原因をその場で示せる。

これは単に error を増やすのではなく、**処理を始める前に前提条件を確認し、failure の場所と理由を近づける**考え方である。

### Cleanup は「最後に rm を書く」だけでは不十分な場合がある

正常終了だけを考えるなら Script 最後の `rm` でも cleanup できる。

しかし、

```text
temporary file 作成
↓
中間処理 failure
↓
exit
↓
最後の rm へ到達しない
```

という経路では残る。

`trap ... EXIT` を利用すると、複数の終了経路から cleanup function へ処理を集約できる。

一方、`SIGKILL` や machine failure など cleanup code 自体を実行できない状況もある。  
そのため temporary data の設計では、cleanup が失敗しても致命的にならない置き場所・命名・権限も考える余地がある。

### Idempotency は「何度実行しても何もしない」ことではない

idempotent な処理でも、毎回 condition check や command の実行が行われる場合がある。  
重要なのは、同じ operation を繰り返しても意図しない重複や状態変化を増やさないことである。

今回の例では、

```text
同じ設定行を 2 回追加
→ 2 行になる

既存行を確認して必要時のみ追加
→ 1 行を維持
```

という違いを確認した。

file copy、directory creation、DB 更新、API request などではそれぞれ idempotency の考え方が異なる。  
後続 Unit でも「再実行したらどうなるか」を継続して考える。

### Partial failure を考えると Script は一連の command ではなく state transition に見える

複数 step の Script を、

```text
command A
command B
command C
```

とだけ見ると、「どこで失敗したか」に注目しやすい。

一方で state として考えると、

```text
未処理
↓
step 1 完了
↓
step 2 完了
↓
完了
```

となる。

step 1 完了後に failure したなら、再実行時の starting state は「未処理」ではない。

この視点を持つと、

- idempotent にする
- completion marker を持つ
- transaction にする
- rollback する
- resume する

といった設計判断につながる。

### Idempotency と lock は別の問題を解決する

idempotency があっても、二つの process が同時に同じ resource を更新すると race condition が起きる可能性がある。  
逆に lock があっても、前回途中 failure 後の再実行が重複処理になる可能性は残る。

```text
idempotency
→ 繰り返し実行への対策

lock
→ 同時実行への対策
```

両者は関連するが同じものではない。

batch / cron では、

```text
前回 job がまだ動いている
+
次回 job が開始
```

という状況があり得るため、必要に応じて両方の観点を持つ。

### Retry は failure を「なかったこと」にする仕組みではない

retry は transient failure に有効な場合があるが、原因によっては何度繰り返しても成功しない。

たとえば、

```text
一時的 network error
→ retry が有効な可能性

invalid credential
→ retry しても改善しない可能性

invalid input
→ retry すべきではない
```

retry を設計するときは、

- 何を retry するか
- 最大何回か
- どれくらい待つか
- 最終 failure をどう返すか
- operation 自体が再試行可能か

を考える。

特に外部 API への write のような処理では、最初の request が server 側では成功したが client が response を受け取れなかった、といった状況もあり得る。  
後続 Unit では HTTP / API と組み合わせる際にも再実行性を意識する。

### Destructive operation では command より前の validation が本体になることがある

`rm -rf` 自体の syntax は難しくない。  
危険なのは「何を削除対象として渡したか」である。

そのため安全性の中心は、

```text
target は empty ではないか
root ではないか
expected directory 配下か
working directory は正しいか
glob の範囲は正しいか
```

という事前確認になる。

destructive operation では、

> command が正しいか

だけでなく、

> argument が本当に意図した対象か

を確認する習慣が重要である。

### Quote と `--` は小さな記述でも入力によって挙動が変わる問題を防ぐ

通常の filename だけで試していると、

```bash
rm $file
```

でも問題なく動くことがある。

しかし、

```text
空白を含む
空文字
glob character を含む
- から始まる
```

といった input が来ると意味が変わる可能性がある。

```bash
rm -- "$file"
```

のような書き方は、正常系の見た目を変えるためではなく、入力値によって command-line parsing が意図せず変化する可能性を減らすためにある。

### Secret management と debugging は衝突することがある

debugging では「実際に何が渡ったか」を見たい。  
一方、secret management では「実際の値を log に出したくない」。

`set -x` はこの二つが衝突しやすい代表例である。

```text
xtrace
→ expansion 後の argument が見える
→ debugging しやすい
→ secret まで見える可能性
```

そのため debug tooling は無条件に有効化するのではなく、data の機密性と合わせて利用範囲を決める。

CI/CD では trace が build log として長期間保存されたり、多くの member から閲覧できたりする可能性もある。  
後続の CI/CD Unit でも同じ観点が必要になる。

### Debugging は「情報を増やす」前に「問題範囲を狭める」

問題が起きると、すぐに大量の `echo` を追加したり Script 全体を `bash -x` にしたくなる場合がある。

しかし効率的に原因を探すには、

```text
syntax error か
input error か
どの step まで success か
どの command が non-zero か
期待した file / data があるか
```

を順番に狭める。

そのうえで必要な場所だけ、

```text
bash -n
bash -x
set -x / set +x
DEBUG output
exit status
```

を利用する。

この考え方は Shell Script に限らず、application code や CI/CD の troubleshooting にもつながる。

### Unit 04 の安全性は後続 Unit で繰り返し利用する

この Unit で学んだ内容は、安全性だけを独立して学んで終わるものではない。

後続 Unit では、たとえば以下のようにつながる。

```text
Unit 05 file / log processing
→ input validation
→ safe path handling
→ cleanup

Unit 06 HTTP / API / JSON
→ dependency check
→ timeout
→ retry
→ secret

Unit 07 batch / cron
→ lock
→ idempotency
→ cleanup
→ rerun

Unit 10 DB / Docker / Application
→ partial failure
→ external command failure
→ dependency

Unit 11 CI/CD
→ exit status
→ secret
→ debug log
→ failure propagation
```

今後の Script を読むときは、正常系の command の流れだけではなく、

```text
何が failure し得るか
↓
その failure を検知できるか
↓
どの状態を残すか
↓
再実行できるか
↓
diagnostic information を安全に残せるか
```

という視点を継続して持つことが、この Unit の中心となる。
