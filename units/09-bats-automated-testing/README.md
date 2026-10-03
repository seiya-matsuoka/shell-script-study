# 09. Bats による Shell Script の自動テスト

## この Unit の目的

Shell Script に対しても test code を用意し、期待する動作を自動的に確認できることを理解する。  
これまでの Unit では、Script を実行して stdout / stderr、exit status、生成 file などを人間が確認してきた。Unit 09 では、その確認内容を Bats の test code として記述し、同じ確認を繰り返し自動実行できる形へ置き換える。  
この Unit では Bats の基本構文だけでなく、正常系・異常系、argument validation、exit status、stdout / stderr、複数行 output、file creation、file contents、temporary directory、fixture、test isolation、function 分割、外部 command の fake 化までを扱う。  
最終的には、単に `.bats` を書けることだけではなく、**Shell Script のどの挙動を test すべきか、どのような構造だと test しやすいか**まで理解することを目標とする。

## 学習内容

### Shell Script に自動テストを書く意味

Shell Script は小さな automation で使われることが多いため、手動実行だけで済ませることもできる。  
しかし Script の役割が増えると、変更のたびにすべての入力条件や failure pattern を手作業で確認するのは難しくなる。  
たとえば次のような確認がある。

```text
argument を正しく渡した
→ exit status 0
→ expected stdout
argument が不足している
→ non-zero exit status
→ usage を stderr に出す
input file が存在する
→ output file を作る
→ file contents が正しい
input file が存在しない
→ output file を作らない
→ non-zero exit status
```

これらを人間が毎回実行すると、確認漏れや見落としが起こり得る。  
自動テストへ変えると、同じ確認を何度でも同じ条件で実行できる。

```text
source code を変更
↓
test suite を実行
↓
expected behavior と一致するか確認
↓
pass / fail
```

自動テストは「bug が絶対にないこと」を証明するものではない。  
しかし、**以前確認できていた代表的な動作が、変更後も維持されていることを短時間で再確認する仕組み**として役立つ。

### Bats

Bats は Bash Automated Testing System の略で、Bash や UNIX command の動作を test するための framework である。  
Bats の test file は `.bats` extension を持ち、Bash に近い記述の中へ `@test` という test case を定義する。  
最小形は次のようになる。

```bash
#!/usr/bin/env bats

@test "sample command succeeds" {
  run printf '%s\n' 'hello'
  [ "$status" -eq 0 ]
  [ "$output" = "hello" ]
}
```

Bats の test case 内では通常の Shell command を利用できる。  
各 assertion も特別な assertion language ではなく、`[` や `[[` などの Shell command が success するかどうかで判定できる。

```text
assertion command が 0
→ test を継続
assertion command が non-zero
→ test failure
```

そのため、Bats を学ぶ際にも Shell の exit status の理解がそのまま利用できる。

### `.bats` と `@test`

Bats test file は通常、次の shebang から始める。

```bash
#!/usr/bin/env bats
```

一つの test case は `@test` で表す。

```bash
@test "正常系: NAME を渡すと greeting を stdout に出して成功する" {
  ...
}
```

`@test` の description は test 実行時にも表示されるため、何を確認している test なのか分かる名前にする。  
悪い例として、

```text
test1
test2
```

だけでは failure 時に何を確認していたのか判断しにくい。  
一方、

```text
正常系: NAME を渡すと greeting を stdout に出して成功する
異常系: argument がない場合は usage を stderr に出して status 2 で終了する
```

のように expected behavior を名前へ含めると、test result から目的を読み取りやすい。

### `run`

Bats の `run` helper は、test 対象 command を実行し、その結果を Bats の special variable へ保存する。

```bash
run bash "$GREET_SCRIPT" "Alice"
```

主に次の値を利用する。

```text
$status
→ command の exit status
$output
→ command output
$lines
→ output を line 単位で扱う array
```

たとえば、

```bash
run bash "$GREET_SCRIPT" "Alice"
[ "$status" -eq 0 ]
[ "$output" = "hello, Alice" ]
```

では、

```text
command を実行
↓
exit status を $status へ保存
output を $output へ保存
↓
expected value と比較
```

という流れになる。  
`run` を利用すると、test 対象 command が non-zero で終了しても、その時点で test case を終了させず、`$status` を使って expected failure かどうか確認できる。

### `$status`

`$status` は `run` が実行した command の exit status を保持する。

```bash
[ "$status" -eq 0 ]
```

は success を確認している。

```bash
[ "$status" -eq 1 ]
```

のように、特定の failure status を確認することもできる。  
Unit 04・07 で確認したとおり、Shell Script では exit status が machine-readable な結果になる。  
Bats ではその exit status をそのまま expected behavior として test できる。  
たとえば argument 不足を `2`、input validation failure を `1` としている Script なら、

```text
argument なし
→ status 2
invalid input
→ status 1
success
→ status 0
```

という interface を test code で固定できる。

### `$output` と stdout / stderr

通常の `run` では command の stdout / stderr を output として扱える。  
一方、この Unit では「正常結果は stdout、error message は stderr」という interface 自体も test するため、`--separate-stderr` を利用する。

```bash
run --separate-stderr bash "$GREET_SCRIPT"
```

この場合、主に次の variable を使える。

```text
$output
→ stdout
$stderr
→ stderr
$lines
→ stdout の line array
$stderr_lines
→ stderr の line array
```

たとえば、

```bash
[ -z "$output" ]
[[ "$stderr" == usage:* ]]
```

なら、

```text
stdout
→ empty
stderr
→ usage message
```

を確認している。  
この Unit の sample は `run --separate-stderr` を利用するため、Bats 1.8.0 以上を前提とする。

### `$lines`

複数行 output を一つの string として比較すると、可読性が下がる場合がある。  
たとえば output が、

```text
start
item=alpha
item=beta
finish
```

なら、`$lines` を利用して個別の行を確認できる。

```bash
[ "${#lines[@]}" -eq 4 ]
[ "${lines[0]}" = "start" ]
[ "${lines[1]}" = "item=alpha" ]
[ "${lines[2]}" = "item=beta" ]
[ "${lines[3]}" = "finish" ]
```

`$output` と `$lines` はどちらか一方しか使えないものではない。

```text
$output
→ output 全体の比較
$lines
→ 特定 line や line count の確認
```

というように test したい内容に合わせて使い分ける。

### 正常系と異常系

自動テストでは success path だけでなく failure path も重要になる。  
たとえば `01-greet.sh` では、

```text
正常系
NAME="Alice"
→ status 0
→ hello, Alice
異常系 1
argument なし
→ status 2
→ usage を stderr
異常系 2
empty NAME
→ status 1
→ validation message を stderr
```

を別 test case として確認する。  
正常系だけを test すると、validation logic を変更して壊しても気付きにくい。  
異常系 test は、「失敗すべき input で確実に失敗する」という behavior を守るために利用できる。

### File creation と file contents

Shell Script は file を生成・更新する処理が多いため、stdout だけではなく file system の状態も test 対象になる。  
たとえば report Script では、

```text
Script 実行
↓
output file が存在するか
↓
内容が expected value か
```

を確認する。  
file existence は、

```bash
[ -f "$OUTPUT_FILE" ]
```

で確認できる。  
contents は、

```bash
run cat "$OUTPUT_FILE"
[ "${lines[0]}" = "source=report-input.txt" ]
[ "${lines[1]}" = "lines=3" ]
[ "${lines[2]}" = "first=alpha" ]
```

のように確認できる。  
重要なのは、「Script が status 0 だった」という一点だけで success と判断しないことである。  
Script の責務が file creation なら、**実際にその side effect が期待どおり発生したか**も test する。  
異常系では逆に、

```bash
[ ! -e "$OUTPUT_FILE" ]
```

のように「作られてはいけない file が存在しない」ことも確認できる。

### `setup` / `teardown`

複数 test case で同じ準備処理を繰り返す場合、Bats の `setup` を利用できる。

```bash
setup() {
  TEST_WORK_DIR="$BATS_TEST_TMPDIR/work"
  mkdir -p -- "$TEST_WORK_DIR"
  INPUT_FILE="$TEST_WORK_DIR/report-input.txt"
  copy_fixture "report-input.txt" "$INPUT_FILE"
}
```

`setup` は各 test case の前に実行される。  
そのため、test case ごとに同じ初期状態を作りやすい。  
`teardown` は各 test case の後に実行される。

```bash
teardown() {
  rm -rf -- "$TEST_WORK_DIR"
}
```

主に cleanup に利用できる。

```text
test case A
↓
setup
↓
test A
↓
teardown
test case B
↓
setup
↓
test B
↓
teardown
```

test case 間で状態を共有しすぎると、test の実行順によって pass / fail が変わる原因になる。  
そのため `setup` / `teardown` は test isolation を作る基本的な仕組みとして重要になる。

### `BATS_TEST_TMPDIR`

Bats は test case ごとに利用できる temporary directory として `$BATS_TEST_TMPDIR` を提供する。  
この Unit では、

```bash
TEST_WORK_DIR="$BATS_TEST_TMPDIR/work"
```

のように test 専用 workspace を作る。  
利点は、real project file や `/tmp` 上の固定 file 名を直接操作せずに済むことである。

```text
固定 path
/tmp/test-output.txt
→ 別 test / 別 process と衝突する可能性
BATS_TEST_TMPDIR
→ test case ごとに固有の temporary directory
→ test isolation を作りやすい
```

Shell Script は file system への side effect が多いため、temporary directory を使って test 対象を隔離することが特に重要になる。

### Fixture

fixture は test を実行するためにあらかじめ用意した input data や初期状態である。  
この Unit では、

```text
tests/fixtures/report-input.txt
tests/fixtures/records.txt
tests/fixtures/empty-input.txt
```

を利用する。  
fixture を直接変更すると、次の test に影響する可能性がある。  
そのため `test_helper.bash` の `copy_fixture` を使い、test case 用 temporary directory へ copy してから変更する。

```bash
copy_fixture "records.txt" "$RECORD_FILE"
```

この方法なら、

```text
original fixture
→ immutable な基準 data
working copy
→ test case 内で自由に変更
```

という役割分担にできる。

### Test isolation

test isolation は、一つの test case の変更や side effect が他の test case の結果へ影響しない状態を指す。  
`04-isolation.bats` では、一つ目の test case で fixture copy に `gamma` を追記する。

```text
alpha
beta
↓
alpha
beta
gamma
```

しかし次の test case では `setup` が再実行され、original fixture から新しい working copy を作る。

```text
次の test
↓
alpha
beta
```

へ戻る。  
もし前の test で変更した file をそのまま次の test が使えば、

```text
test A を先に実行
→ test B pass
test B だけ実行
→ test B fail
```

のような order-dependent test になる可能性がある。  
良い test suite では、可能な範囲で各 test が独立して実行できるようにする。

### Test helper

複数 `.bats` file から共通処理を利用するため、この Unit では `tests/test_helper.bash` を用意している。

```bash
load test_helper
```

によって test file から helper を読み込む。  
helper では、

```text
PROJECT_ROOT の解決
fixture path の生成
fixture copy
```

を共通化している。  
たとえば、

```bash
fixture_path() {
  local fixture_name=$1
  printf '%s/tests/fixtures/%s\n' "$PROJECT_ROOT" "$fixture_name"
}
```

を各 `.bats` file に重複して書く必要がなくなる。  
ただし helper を巨大化して test logic の大部分を隠すと、test file を読んでも何を確認しているか分かりにくくなる。  
共通化するのは setup や path 解決など、複数 test で本当に共通する補助処理を中心にする。

### テストしやすい Script

同じ動作をする Script でも、内部構造によって test の書きやすさは変わる。  
`examples/testability/01-large-main.sh` は、

```text
argument validation
file validation
line count
status 判定
output file 作成
```

を一つの main flow にまとめている。  
この構造でも test はできる。  
しかし、たとえば `READY` / `EMPTY` の status 判定だけを test したくても Script 全体を実行する必要がある。

```text
status 判定だけ確認したい
↓
input file を準備
output path を準備
CLI 全体を実行
output file を読む
```

という形になる。  
一方、`02-report-lib.sh` では、

```text
validate_input
report_status
build_report
```

へ function を分けている。  
Bats から library を `source` すれば、

```bash
run report_status "$INPUT_FILE"
```

のように対象 function だけを直接 test できる。

```text
large main
→ integration / end-to-end に近い test になりやすい
function 分割
→ 小さい behavior を直接 test しやすい
```

という違いがある。

### Function 分割と責務

function 分割は「test のためだけ」に行うものではない。  
処理の責務を分けることで、可読性や再利用性も改善できる。  
たとえば、

```text
validate_input
→ input file が利用可能か
report_status
→ data から status を判断
build_report
→ report text を生成
CLI main
→ argument を受け取り、各 function を組み合わせる
```

と役割が分かれていると、どこを test すべきかも考えやすくなる。  
一方、細かく function を分割しすぎれば必ず良いわけではない。  
重要なのは、

```text
独立して意味を持つ判断
独立して再利用したい処理
side effect と pure な判断
```

などの境界を意識することである。

### Side effect

Shell Script では side effect が多い。  
代表例は、

```text
file creation / modification
network request
process execution
directory change
environment variable change
```

などである。  
side effect 自体が悪いわけではない。  
しかし test では、real environment を変更しないように対象を隔離したり、dependency を差し替えたりする必要がある。  
この Unit では、

```text
file side effect
→ BATS_TEST_TMPDIR
input data
→ fixture copy
external curl
→ fake command + PATH replacement
```

という方法を使う。

### External dependency

外部 command や network service に依存する Script を test するとき、毎回 real service を呼ぶと test が不安定になる場合がある。  
`01-fetch-status.sh` は、

```bash
curl -fsS "$API_URL/status"
```

を実行する。  
これを test のたびに real HTTP server へ接続すると、

```text
network failure
server outage
response change
rate limit
execution time
```

など、test 対象 Script 以外の要因で failure する可能性がある。  
Unit 09 では、real `curl` を毎回使わず fake command へ差し替える。

### Mock / stub / fake の考え方

test double を表す言葉として mock、stub、fake などがある。  
この Unit では framework ごとの厳密な分類を覚えることを目的としない。  
大まかには、

```text
real dependency の代わりに
test 用の controllable な dependency を使う
```

という考え方を理解する。  
今回の `tests/fakes/curl` は、real curl の全機能を再現しない。  
Unit 09 の test に必要な最小 behavior だけ持つ。

```text
FAKE_CURL_MODE=success
→ specified response を stdout
→ status 0
FAKE_CURL_MODE=failure
→ error を stderr
→ status 22
```

これにより test から success / failure を自由に再現できる。

### `PATH` 差し替え

Shell が `curl` のような command name を実行するときは `PATH` から executable を探索する。  
そこで test の `setup` で、

```bash
FAKE_BIN="$PROJECT_ROOT/tests/fakes"
ORIGINAL_PATH=$PATH
PATH="$FAKE_BIN:$ORIGINAL_PATH"
export PATH
```

とする。  
すると、

```text
PATH の先頭
→ tests/fakes/curl
その後
→ original PATH
```

になるため、test 対象 Script が `curl` を実行すると fake command が先に見つかる。

```text
production
curl
→ real curl
test
PATH を変更
→ tests/fakes/curl
```

という差し替えができる。  
Script 本体へ、

```text
if test mode then fake curl
```

のような test 専用 branch を追加しなくても external dependency を置き換えられる点が重要である。

### Fake command で command failure を再現する

external dependency の test では success だけでなく failure も再現する。

```bash
FAKE_CURL_MODE=failure
export FAKE_CURL_MODE
run --separate-stderr bash "$FETCH_SCRIPT"
```

fake curl は stderr を出して `22` で終了する。  
それを受け取った `01-fetch-status.sh` は、

```text
curl failure
↓
failed to fetch remote status
↓
Script status 1
```

となる。  
Bats 側では、

```bash
[ "$status" -eq 1 ]
[ -z "$output" ]
[[ "$stderr" == *"fake curl: request failed"* ]]
[[ "$stderr" == *"failed to fetch remote status"* ]]
```

を確認する。  
一つの test case で、

```text
external command の failure
+
Script 自身の failure handling
```

をまとめて再現できる。

### Deterministic な test

良い automated test は、同じ code と同じ input なら同じ結果になりやすい方が扱いやすい。  
real network へ接続する test は、test 対象以外の状態によって結果が変わる可能性がある。  
fake command を使えば、

```bash
FAKE_CURL_RESPONSE=READY
```

なら必ず READY、

```bash
FAKE_CURL_RESPONSE=MAINTENANCE
```

なら必ず MAINTENANCE を返すよう制御できる。

```text
controllable input
↓
predictable result
↓
repeatable test
```

という状態を作れる。  
ただし fake だけを test して real dependency との integration を一切確認しなくてよい、という意味ではない。  
unit-level の automated test と real integration test は役割が異なる。

### Unit 08 の static analysis との違い

Unit 08 では shfmt / ShellCheck を使った品質管理を扱った。

```text
shfmt
→ formatting
ShellCheck
→ static analysis
Bats
→ runtime behavior test
```

という違いがある。  
たとえば ShellCheck は、

```text
unquoted variable
unchecked cd
```

のような pattern を検出できる。  
一方、

```text
NAME="Alice" のとき hello, Alice を出す
missing file なら output file を作らない
```

という application-specific な expected behavior は Bats などの test で確認する。  
品質管理では、どれか一つだけ選ぶのではなく、異なる層の check を組み合わせる。

## 使用するもの

この Unit では主に以下を利用する。

- Bash
- Bats / bats-core
- `bash -n`
- `shfmt`
- `ShellCheck`
- `mktemp`
- `cp`
- `cat`
- `grep`
- `wc`
- `tail`
- test fixture
- fake command
- `PATH` replacement

Bats の version を確認する。

```bash
bats --version
```

この Unit では `run --separate-stderr` を利用するため、Bats 1.8.0 以上を使用する。  
Bats が利用できるか確認する。

```bash
command -v bats
```

`shfmt` / ShellCheck も Unit 08 から継続して利用する。

```bash
command -v shfmt
command -v shellcheck
```

Bats が未導入の場合は、使用している Linux distribution の package manager または bats-core の公式 installation 方法で導入する。  
package manager で古い Bats が導入される環境では、`bats --version` を確認して 1.8.0 以上を利用する。

## 事前準備

Unit 01～08 が完了し、以下を確認済みであることを前提とする。

- Bash Script の基本構文
- argument validation
- exit status
- stdout / stderr
- file operation
- temporary directory
- `source` と function
- environment variable
- `PATH` と command resolution
- external command failure
- shfmt / ShellCheck

Unit 09 へ移動する。

```bash
cd units/09-bats-automated-testing
```

成果物を確認する。

```bash
find . -maxdepth 4 -type f | sort
```

```text
09-bats-automated-testing/
├─ README.md
├─ examples/
│  ├─ basic/
│  │  ├─ 01-greet.sh
│  │  └─ 02-list-items.sh
│  ├─ external/
│  │  └─ 01-fetch-status.sh
│  ├─ files/
│  │  ├─ 01-write-report.sh
│  │  └─ 02-append-record.sh
│  └─ testability/
│     ├─ 01-large-main.sh
│     ├─ 02-report-lib.sh
│     └─ 03-report-cli.sh
├─ quality/
│  └─ quality-check.sh
└─ tests/
   ├─ 01-basic.bats
   ├─ 02-output-lines.bats
   ├─ 03-file-output.bats
   ├─ 04-isolation.bats
   ├─ 05-testability.bats
   ├─ 06-external-dependency.bats
   ├─ fakes/
   │  └─ curl
   ├─ fixtures/
   │  ├─ empty-input.txt
   │  ├─ records.txt
   │  └─ report-input.txt
   └─ test_helper.bash
```

まず通常の Shell files の syntax を確認する。

```bash
find examples quality tests \
  \( -name '*.sh' -o -name '*.bash' \) \
  -type f \
  -print0 \
  | xargs -0 -n 1 bash -n
```

fake command も確認する。

```bash
bash -n tests/fakes/curl
```

Unit 08 から継続する quality check は次の command で実行する。

```bash
bash quality/quality-check.sh
```

`.bats` は Bats 固有の `@test` syntax を含むため、この `quality-check.sh` では shfmt / ShellCheck の対象から除外している。  
Unit 09 の test code 自体は Bats を使って実行確認する。  
全 test suite は次の command で実行できる。

```bash
bats tests/*.bats
```

個別 file だけを実行する場合は、

```bash
bats tests/01-basic.bats
```

のように指定する。

## 学習・実践

### 1. 最初の Bats test で `@test`・`run`・`$status`・`$output` を確認する

最初に test 対象 Script を読む。

```bash
cat examples/basic/01-greet.sh
```

この Script には主に 3 つの behavior がある。

```text
NAME を一つ渡す
→ status 0
→ hello, NAME を stdout
argument なし
→ status 2
→ usage を stderr
empty NAME
→ status 1
→ validation message を stderr
```

対応する Bats file を読む。

```bash
cat tests/01-basic.bats
```

先頭では、

```bash
load test_helper
```

によって共通 helper を読み込んでいる。  
`setup` では test 対象 path を variable に入れる。

```bash
setup() {
  GREET_SCRIPT="$PROJECT_ROOT/examples/basic/01-greet.sh"
}
```

最初の正常系 test は次の部分である。

```bash
@test "正常系: NAME を渡すと greeting を stdout に出して成功する" {
  run bash "$GREET_SCRIPT" "Alice"
  [ "$status" -eq 0 ]
  [ "$output" = "hello, Alice" ]
}
```

ここでは、

```text
run
→ test 対象 command を実行
$status
→ exit status
$output
→ output
```

という最も基本的な組み合わせを確認する。  
実際に test file を実行する。

```bash
bats tests/01-basic.bats
```

3 test cases が pass することを確認する。  
次に、test 対象 Script を Bats を使わず直接実行して比較する。

```bash
bash examples/basic/01-greet.sh Alice
```

```text
hello, Alice
```

argument なしも直接実行する。

```bash
bash examples/basic/01-greet.sh
echo $?
```

Bats test は、この手動確認を test code として残していると考えると分かりやすい。  
続いて異常系 test を読む。

```bash
run --separate-stderr bash "$GREET_SCRIPT"
[ "$status" -eq 2 ]
[ -z "$output" ]
[[ "$stderr" == usage:* ]]
```

ここでは単に non-zero であることだけではなく、

```text
expected status = 2
stdout = empty
stderr = usage
```

まで確認している。  
つまり test は、Script の user-visible / caller-visible interface を具体的に固定している。

### 2. 複数行 output を `$lines` で確認する

対象 Script を実行する。

```bash
bash examples/basic/02-list-items.sh
```

```text
start
item=alpha
item=beta
finish
```

の 4 lines が出力される。  
Bats file を読む。

```bash
cat tests/02-output-lines.bats
```

主要部分は次のとおりである。

```bash
run bash "$LIST_SCRIPT"
[ "$status" -eq 0 ]
[ "${#lines[@]}" -eq 4 ]
[ "${lines[0]}" = "start" ]
[ "${lines[1]}" = "item=alpha" ]
[ "${lines[2]}" = "item=beta" ]
[ "${lines[3]}" = "finish" ]
[[ "$output" == *"item=alpha"* ]]
```

`$output` では output 全体を扱える。  
一方 `$lines` では line ごとの assertion を書きやすい。  
実行する。

```bash
bats tests/02-output-lines.bats
```

pass したら、どの assertion が何を固定しているか確認する。  
たとえば、

```bash
[ "${#lines[@]}" -eq 4 ]
```

は内容だけでなく line 数も expected behavior として扱っている。  
もし `02-list-items.sh` に一行追加すれば、test の期待値と実装が一致しなくなる。  
その変更が仕様変更なら test も更新する必要があり、意図しない変更なら source code 側を修正する必要がある。

```text
test failure
↓
実装が間違ったのか
expected behavior が変わったのか
↓
判断する
```

という流れが automated test の基本になる。

### 3. File creation・file contents・異常系を test する

report Script を読む。

```bash
cat examples/files/01-write-report.sh
```

この Script は、

```text
INPUT_FILE
↓
line count / first line を取得
↓
OUTPUT_FILE を作成
```

という side effect を持つ。  
fixture を確認する。

```bash
cat tests/fixtures/report-input.txt
```

```text
alpha
beta
gamma
```

が入っている。  
Bats test を読む。

```bash
cat tests/03-file-output.bats
```

`setup` では、

```bash
TEST_WORK_DIR="$BATS_TEST_TMPDIR/work"
mkdir -p -- "$TEST_WORK_DIR"
INPUT_FILE="$TEST_WORK_DIR/report-input.txt"
OUTPUT_FILE="$TEST_WORK_DIR/output/report.txt"
copy_fixture "report-input.txt" "$INPUT_FILE"
```

として、test 専用 temporary directory に fixture copy を作る。  
最初の test は file creation を確認する。

```bash
run bash "$REPORT_SCRIPT" "$INPUT_FILE" "$OUTPUT_FILE"
[ "$status" -eq 0 ]
[ -f "$OUTPUT_FILE" ]
```

次の test は file contents を確認する。

```bash
run cat "$OUTPUT_FILE"
[ "$status" -eq 0 ]
[ "${lines[0]}" = "source=report-input.txt" ]
[ "${lines[1]}" = "lines=3" ]
[ "${lines[2]}" = "first=alpha" ]
```

最後の test は missing input の異常系である。

```bash
run --separate-stderr bash "$REPORT_SCRIPT" "$missing_file" "$OUTPUT_FILE"
[ "$status" -eq 1 ]
[ ! -e "$OUTPUT_FILE" ]
[[ "$stderr" == "input file not found:"* ]]
```

ここでは、

```text
failure status
error message
output file が作られていない
```

の 3 点を確認している。  
実行する。

```bash
bats tests/03-file-output.bats
```

Shell Script の test では stdout だけを見るのではなく、Script の responsibility に応じて file system state も assertion に含めることを確認する。

### 4. `setup`・`teardown`・fixture で test isolation を確認する

まず fixture を読む。

```bash
cat tests/fixtures/records.txt
```

```text
alpha
beta
```

となっている。  
append Script を読む。

```bash
cat examples/files/02-append-record.sh
```

続いて isolation test を読む。

```bash
cat tests/04-isolation.bats
```

`setup` では各 test case の前に、

```bash
copy_fixture "records.txt" "$RECORD_FILE"
```

を実行する。  
一つ目の test では `gamma` を追記する。

```bash
run bash "$APPEND_SCRIPT" "$RECORD_FILE" "gamma"
```

その後、

```bash
run bash -c 'wc -l < "$1"' _ "$RECORD_FILE"
[ "$output" -eq 3 ]
```

で 3 lines になったことを確認する。  
二つ目の test では追記処理をしていない。

```bash
run bash -c 'wc -l < "$1"' _ "$RECORD_FILE"
[ "$output" -eq 2 ]
```

2 lines に戻っているのは、二つ目の test 前に `setup` が再度実行され、fresh fixture copy が作られたためである。  
実行する。

```bash
bats tests/04-isolation.bats
```

ここで重要なのは、

```text
test A が file を変更
↓
teardown
↓
test B 用 setup
↓
新しい working copy
```

という流れである。  
同じ test を単独実行しても suite の一部として実行しても、結果が変わりにくい構造を目指す。

### 5. 大きな main と function 分割版を比較する

まず一つの Script に処理が集まっている版を読む。

```bash
cat examples/testability/01-large-main.sh
```

この Script には、

```text
validation
line count
status 判定
file creation
output
```

が一つの execution flow に入っている。  
対応する Bats test の最初の test case を確認する。

```bash
cat tests/05-testability.bats
```

```bash
run bash "$LARGE_MAIN_SCRIPT" "$INPUT_FILE" "$OUTPUT_FILE"
[ "$status" -eq 0 ]
[ -f "$OUTPUT_FILE" ]
grep -q '^status=READY$' "$OUTPUT_FILE"
```

この test では CLI 全体を実行する必要がある。  
次に function 分割した library を読む。

```bash
cat examples/testability/02-report-lib.sh
```

主に、

```text
validate_input
report_status
build_report
```

へ分かれている。  
CLI 側も確認する。

```bash
cat examples/testability/03-report-cli.sh
```

CLI は library を `source` し、各 function を組み合わせている。  
Bats test の `setup` でも、

```bash
source "$PROJECT_ROOT/examples/testability/02-report-lib.sh"
```

として library を読み込む。  
これにより、

```bash
run report_status "$INPUT_FILE"
```

と function 単位で test できる。

```bash
[ "$status" -eq 0 ]
[ "$output" = "READY" ]
```

empty input も同じ function に渡せる。

```bash
run report_status "$EMPTY_FILE"
[ "$status" -eq 0 ]
[ "$output" = "EMPTY" ]
```

実行する。

```bash
bats tests/05-testability.bats
```

この file では、

```text
large main の CLI test
function 単体 test
refactored CLI の test
validation function の異常系
```

を同じ test suite で比較できる。  
ここで「function を使えば test が良い」という単純な結論にはしない。  
重要なのは、**個別に意味を持つ logic を分離すると、その behavior だけを直接 test しやすくなる**という点である。

### 6. External dependency を fake command へ差し替える

まず test 対象 Script を読む。

```bash
cat examples/external/01-fetch-status.sh
```

この Script は `curl` を実行する。

```bash
response=$(curl -fsS "$API_URL/status")
```

通常なら external network / API が dependency になる。  
次に fake command を読む。

```bash
cat tests/fakes/curl
```

fake `curl` は environment variable によって behavior を切り替える。

```text
FAKE_CURL_MODE=success
→ FAKE_CURL_RESPONSE を stdout
→ status 0
FAKE_CURL_MODE=failure
→ error message を stderr
→ status 22
```

Bats file を読む。

```bash
cat tests/06-external-dependency.bats
```

`setup` の重要箇所は、

```bash
ORIGINAL_PATH=$PATH
PATH="$FAKE_BIN:$ORIGINAL_PATH"
export PATH
```

である。  
これにより test 対象 Script が `curl` を呼び出しても、real curl より先に `tests/fakes/curl` が解決される。  
正常系では、

```bash
FAKE_CURL_MODE=success
FAKE_CURL_RESPONSE=READY
```

とする。

```bash
run bash "$FETCH_SCRIPT"
[ "$status" -eq 0 ]
[ "$output" = "remote_status=READY" ]
```

となる。  
さらに `FAKE_CURL_MARKER` を使い、fake command が実際に呼ばれたことも確認している。

```bash
[ -f "$FAKE_CURL_MARKER" ]
```

異常系では、

```bash
FAKE_CURL_MODE=failure
```

として command failure を deterministic に作る。

```bash
run --separate-stderr bash "$FETCH_SCRIPT"
[ "$status" -eq 1 ]
[ -z "$output" ]
[[ "$stderr" == *"fake curl: request failed"* ]]
[[ "$stderr" == *"failed to fetch remote status"* ]]
```

response 内容だけ変える test もある。

```bash
FAKE_CURL_RESPONSE=MAINTENANCE
```

実行する。

```bash
bats tests/06-external-dependency.bats
```

この test は `example.invalid` を URL として設定しているが、PATH 上の fake curl が呼ばれるため real HTTP request は行わない。

### 7. Test suite 全体を実行して正常系・異常系をまとめて確認する

ここまで個別 `.bats` file を実行してきた。  
最後に suite 全体を実行する。

```bash
bats tests/*.bats
```

今回の成果物には 6 `.bats` files、16 test cases がある。  
大きく分類すると、

```text
01-basic.bats
→ 正常系 / argument validation / stderr / exit status
02-output-lines.bats
→ 複数行 stdout / $lines
03-file-output.bats
→ file creation / contents / missing input
04-isolation.bats
→ setup / teardown / fixture / isolation
05-testability.bats
→ large main / function 分割 / direct function test
06-external-dependency.bats
→ fake command / PATH replacement / command failure
```

となる。  
全部 pass することを確認したら、test suite が何を保証しているかを test description から読み直す。  
重要なのは test case 数を増やすことそのものではない。

```text
Script の重要 behavior
↓
代表的な正常系 / 異常系
↓
適切な test case
```

という対応になっているかを見る。

### 8. Unit 08 の quality check と Bats を組み合わせて確認する

Unit 08 以降の通常 Shell files には shfmt / ShellCheck の check を継続する。

```bash
bash quality/quality-check.sh
```

この Script では、

```text
examples/
tests/test_helper.bash
tests/fakes/curl
quality/quality-check.sh
```

を quality check の対象にしている。  
`.bats` files は Bats 固有の `@test` syntax を含むため、この quality wrapper では除外している。  
続いて Bats suite を実行する。

```bash
bats tests/*.bats
```

この 2 種類の check は目的が異なる。

```text
bash quality/quality-check.sh
→ formatting / static analysis
bats tests/*.bats
→ runtime behavior
```

両方を通すことで、

```text
source code の静的な問題
+
expected behavior の regression
```

を別の観点から確認できる。  
今後 CI へ接続する場合も、local で実行した command と同じ入口を automation から実行できる形にすると理解しやすい。

## 実行・確認ポイント

### Bats の基本

- `.bats` file に `@test` で test case を定義する。
- `run` で test 対象 command を実行する。
- `$status` で exit status を確認する。
- `$output` で output 全体を確認する。
- `$lines` で複数行 output を line 単位で確認する。
- assertion 自体も Shell command であり、non-zero になれば test failure につながる。

### 正常系・異常系

- success path だけでなく validation failure も test する。
- 単に non-zero かではなく expected exit status を確認する。
- stdout / stderr の役割も behavior として test できる。
- failure 時に作成してはいけない file がないことも確認できる。

### File test

- Script の責務が file creation なら existence を確認する。
- file contents まで expected behavior として確認する。
- test 用 file は real project data と分離する。
- original fixture を直接変更せず working copy を使う。

### `setup` / `teardown`

- `setup` は各 test case の前に実行される。
- `teardown` は各 test case の後に実行される。
- repeated preparation / cleanup を共通化できる。
- test case 間で state を共有しすぎない。

### Temporary directory / isolation

- `$BATS_TEST_TMPDIR` を test case 専用 workspace として利用できる。
- fixed temporary path の衝突を避ける。
- fixture を各 test case で copy し直す。
- test order に依存しない状態を目指す。

### Testability

- large main でも end-to-end test は書ける。
- logic を function へ分離すると対象 behavior を直接 test しやすい。
- side effect と判断 logic の境界を意識する。
- test のためだけに過剰な分割をするのではなく、責務を明確にする。

### External dependency

- real external service を毎回呼ばなくても behavior を test できる。
- fake command を `PATH` の先頭へ配置して command resolution を差し替えられる。
- success / failure / response を environment variable から controllable にする。
- test 対象 Script に test 専用 branch を入れずに dependency を置き換えられる。

### Quality workflow

- shfmt / ShellCheck と Bats は役割が異なる。
- static analysis で runtime expected behavior は保証できない。
- Bats だけで formatting / static problem を確認できるわけでもない。
- local で同じ quality check と test suite を繰り返し実行できる状態にする。

## 学習ポイント

### 自動テストは手動確認をなくすものではなく、繰り返す確認をコード化する

新しい Script を作るとき、最初に人間が実行結果を見ることは重要である。  
どの output が正しいか理解していなければ test の expected value も決められない。  
そのうえで、

```text
毎回同じ command を入力する
毎回 output を目視する
```

という確認を test code へ移す。  
つまり、

```text
手動確認
↓
expected behavior を理解
↓
automated test として固定
```

という流れになる。

### Test code も code なので読みやすさと保守性が必要になる

production Script を test するために test code が複雑になりすぎると、test 自体の正しさを確認しにくくなる。  
たとえば、

```text
一つの @test に大量の scenario
巨大な setup
複雑な helper
大量の hidden state
```

は、何を確認している test なのか分かりにくくする。  
test description、fixture、helper、fake command も、source code と同じく役割が読み取れる構造を意識する。

### `$status` を確認することは Shell Script の interface を確認することでもある

CLI Script では stdout だけでなく exit status も caller との contract になる。

```text
0
→ success
1
→ validation / processing failure
2
→ usage error
```

のように意味を持たせているなら、Bats でその値を test することで contract を守れる。  
message が同じでも status が誤って `0` なら、scheduler や CI は success と判断する可能性がある。  
Unit 07 の unattended execution と Unit 09 の automated test はこの点で直接つながる。

### stdout / stderr も observable behavior になる

Shell Script では、

```text
stdout
→ normal result
stderr
→ diagnostic / error
```

という役割を持たせることができる。  
その設計をしているなら、Bats でも stream を分離して test する価値がある。

```text
error message の文字列が出た
```

だけでなく、

```text
error message が stderr に出た
stdout は empty
```

まで確認することで interface をより正確に test できる。

### Side effect があるほど test isolation が重要になる

pure な calculation だけなら input と output の比較で済みやすい。  
Shell Script は、

```text
file
process
network
environment
current directory
```

など external state を変更することが多い。  
そのため test では、

```text
どこまで real environment を使うか
どこから temporary environment に切り替えるか
```

を意識する。  
この Unit の `$BATS_TEST_TMPDIR`、fixture copy、fake command はすべて isolation のための手段と考えられる。

### Fixture は test の前提条件を見える形で固定する

file data を test code の中で毎回大量に `printf` して作ることもできる。  
しかし、ある程度まとまった sample data なら fixture file として分離した方が、

```text
何を input としているか
```

を直接確認しやすい。  
一方、一行だけの temporary value まで何でも fixture file にすると file 数が増えすぎる。  
fixture は test data として独立して読む価値があるものに使う。

### Test isolation は「cleanup すればよい」だけではない

`teardown` で file を削除することは大切だが、isolation の本質はそれだけではない。

```text
他 test の state を前提にしない
execution order に依存しない
shared path で衝突しない
external environment の状態に依存しすぎない
```

ことも含む。  
`BATS_TEST_TMPDIR` と fresh fixture copy は、最初から state を分離するために利用している。

### Test しやすさは設計の feedback になる

「この function を test しにくい」という状況は、必ずしも設計が悪いことを意味しない。  
しかし、

```text
一つの function / Script が多くの責務を持つ
external dependency が内部で固定されている
side effect と判断 logic が密結合
```

していると、test setup が大きくなる傾向がある。  
そのため test を書く過程は、

```text
この処理の責務は何か
どこを独立させると読みやすいか
どの dependency を外から差し替えられるか
```

を考えるきっかけにもなる。

### Function 分割は unit test と CLI test の両方を可能にする

`report_status` を function 単位で test できても、CLI 全体の test が不要になるわけではない。  
function test は、

```text
small behavior
failure location を特定しやすい
```

という利点がある。  
CLI test は、

```text
argument
function combination
file output
```

が実際につながって動くことを確認できる。

```text
small function test
+
CLI-level test
```

を組み合わせることで異なる範囲を確認できる。

### Fake command は real command の完全コピーである必要はない

`tests/fakes/curl` は curl の option parsing、HTTP、TLS などを再実装していない。  
必要なのは今回 test したい interface、つまり、

```text
success output
failure status
failure stderr
```

を再現することだけである。  
fake が複雑になり real dependency と同程度の実装量になれば、fake 自体の maintenance cost が増える。  
学習段階では、**test に必要な最小 behavior だけを持つ fake**という考え方を押さえる。

### `PATH` 差し替えは Shell らしい dependency injection の一つ

application language では dependency を object や interface から injection する設計がある。  
Shell では command execution が `PATH` に依存しているため、test 用 executable を `PATH` の前方に配置するだけでも dependency を差し替えられる。

```text
source code
curl ...
production PATH
→ real curl
test PATH
→ fake curl
```

となる。  
これは Unit 01 で学んだ command resolution、Unit 07 で学んだ scheduler environment と同じ `PATH` の仕組みを、testability のために利用している。

### Mock / stub / fake の用語より、何を置き換えて何を確認するかが重要

test double の分類には様々な定義がある。  
この Unit の目的では、用語を細かく分類することより、

```text
real dependency は何か
↓
何を controllable にしたいか
↓
test double がどの behavior を再現すればよいか
```

を説明できることが重要である。  
高度な mocking framework や interaction verification は今回の対象外とする。

### Static analysis と automated test は互いの代替ではない

ShellCheck が通っていても、

```text
expected message が間違っている
wrong file contents を生成する
business rule を誤っている
```

ことはある。  
Bats がすべて pass していても、

```text
untested unquoted expansion
error-prone Shell pattern
```

が残る可能性はある。  
したがって、

```text
shfmt
→ format
ShellCheck
→ static analysis
Bats
→ runtime expected behavior
```

という層を組み合わせる。

### Test case 数ではなく重要な behavior の coverage を考える

test が 100 件あっても、ほぼ同じ正常系だけなら重要な failure path を確認できないことがある。  
逆に小さな Script なら、

```text
代表的な正常系
代表的な validation failure
critical side effect
external dependency failure
```

を数件で十分確認できる場合もある。  
この Unit では coverage percentage の詳細は扱わない。  
まずは「この Script が壊れたとき、どの behavior を automated test で検出したいか」を考える。

### Unit 09 以降では変更後に quality check と test を実行する流れを意識する

Unit 08 で formatter / static analysis を開発工程へ組み込んだ。  
Unit 09 では runtime test が加わる。  
今後 Shell Script を変更したときは、必要に応じて、

```bash
bash quality/quality-check.sh
bats tests/*.bats
```

のような確認を行う。  
この流れは後続の CI/CD で、

```text
source code を push
↓
automation が quality check
↓
automation が test suite
↓
pass / fail
```

へ接続できる。  
Unit 09 ではまず、**自分の local environment で automated test を作り、読んで、実行できること**を確実にする。
