# 08. shfmt / ShellCheck とコード品質

## この Unit の目的

Shell Script の formatter である `shfmt` と、static analysis tool である `ShellCheck` の役割を理解し、コード品質を継続的に確認する基本的な流れを身につける。  
editor 上で自動整形や warning が表示されることだけを目的とせず、CLI から同じ tool を実行できること、local と CI で同じ基準を利用できること、warning の意味を理解してコードを改善することを重視する。

この Unit では、意図的に formatting が崩れた Script や ShellCheck warning を含む Script を用意している。  
問題を検出し、出力を読み、原因を理解し、改善後のコードと比較することで、単に tool の指摘を消すのではなく「なぜその指摘が出るのか」を確認する。

## 学習内容

### Formatter と static analysis

`shfmt` と `ShellCheck` はどちらも Shell Script の品質管理に利用できるが、役割は異なる。

```text
shfmt
→ formatting を統一する
→ indentation や空白、構造上の見た目を揃える

ShellCheck
→ Shell Script を静的に解析する
→ error になりやすい書き方や潜在的な問題を warning として示す
```

formatter は主に「どう書式を揃えるか」を扱う。  
たとえば function、`if`、loop の indentation や空白を一定の規則へ揃えることで、書き手ごとの見た目の差を減らせる。

一方 static analysis は、Script を実際に production data で実行しなくても source code を解析し、問題になり得る pattern を検出する。

```text
source code
↓
ShellCheck が解析
↓
SCxxxx warning
↓
該当箇所と理由を確認
↓
必要なら修正
```

両者は競合するものではなく、別の問題を担当する。

```text
formatting が揃っている
≠
安全な Script である

ShellCheck warning がない
≠
formatting が統一されている
```

そのため実際の品質管理では、formatter と static analysis を組み合わせて利用できる。

### shfmt

`shfmt` は Shell source code を一定の format に整える formatter である。  
この Unit では 2 space indentation を明示して利用する。

format 済みの結果を stdout へ表示する場合は次のように実行できる。

```bash
shfmt -i 2 script.sh
```

file 自体を書き換える場合は `-w` を利用する。

```bash
shfmt -i 2 -w script.sh
```

一方、file を変更せず「formatting 差分が存在するか」を確認する場合は `-d` を利用できる。

```bash
shfmt -i 2 -d script.sh
```

`-d` は formatted result と現在の file に差がある場合、その diff を表示し non-zero で終了する。  
そのため、local での確認だけでなく CI の quality check にも利用できる。

```text
developer
↓
shfmt -i 2 -w
↓
source code を整形

quality check / CI
↓
shfmt -i 2 -d
↓
未整形なら failure
```

重要なのは formatter の細かな style を暗記することではない。  
project 内で同じ設定を利用し、人によって formatting 判断が変わらないようにすることである。

### Format と format check

format と format check は目的が異なる。

```text
format
shfmt -i 2 -w ...
→ tool が source code を修正する

format check
shfmt -i 2 -d ...
→ source code は変更せず差分の有無を確認する
```

開発者が local で `-w` を使い、commit 前や CI では `-d` を使う、といった使い分けができる。

CI が勝手に source code を書き換えても、その変更が developer の branch へ自動的に戻るとは限らない。  
そのため CI では「違反を検出して failure にする」、local では「formatter で修正する」という構成が分かりやすい。

### Editor integration と CLI

VS Code などの editor では、保存時の format や diagnostic 表示として shfmt / ShellCheck を統合できる。

```text
editor integration
→ coding 中にすぐ feedback を得る

CLI
→ editor に依存せず同じ check を再現する
```

editor integration は便利だが、個人ごとの editor 設定だけに依存すると、別の editor や CI では同じ check を再現できない。

そのため、

```text
editor
local terminal
CI
```

のどこから利用しても、同じ formatter / analyzer と同じ project rule を使える状態が理想になる。

この Unit では特定 editor extension の設定方法を学習対象にはせず、まず CLI で tool の役割と結果を理解する。

### ShellCheck

ShellCheck は `sh` / `bash` などの Shell Script を解析し、典型的な問題や落とし穴を warning として示す static analysis tool である。

基本形は次のとおり。

```bash
shellcheck script.sh
```

複数 file もまとめて指定できる。

```bash
shellcheck script-a.sh script-b.sh
```

ShellCheck の output には、問題箇所、severity、`SC2086` のような code、説明が表示される。

```text
file / line
↓
warning / info / error
↓
SCxxxx
↓
問題の説明
```

`SCxxxx` は warning の種類を識別する code である。  
番号そのものを暗記する必要はなく、出力された code と説明を読み、「どの Shell の挙動が問題になっているか」を理解することが重要である。

### Syntax error と static analysis の違い

Shell の syntax が成立しているかは `bash -n` でも確認できる。

```bash
bash -n script.sh
```

たとえば `if` に対応する `fi` がない Script は syntax として parse できないため、実行前に検出できる。

一方、次のようなコードは syntax としては成立する。

```bash
printf '%s\n' $name
```

しかし `$name` に space や glob character が含まれると、意図しない word splitting / pathname expansion が起こり得る。

```text
bash -n
→ syntax として成立しているか

ShellCheck
→ syntax に加え、Shell 固有の危険な pattern や不自然な書き方を解析
```

static analysis は runtime test の代わりではない。  
実際の data や external service によって発生する問題は、ShellCheck だけでは確認できない。

### Quote と word splitting

ShellCheck で特に重要な指摘の一つが variable expansion の quote である。

問題例は次のようになる。

```bash
printf '%s\n' $name
```

`$name` を quote しない場合、展開結果に対して word splitting や glob expansion が行われる可能性がある。

```text
name="hello world"

$name
↓
hello
world
```

一つの value を一つの argument として渡したいなら、

```bash
printf '%s\n' "$name"
```

のように quote する。

ShellCheck では、このような unquoted expansion に対して代表的に `SC2086` などの指摘が出る。

重要なのは、

> ShellCheck が言ったから quote を付ける

ではなく、

> この expansion は 1 argument として渡したいので quote が必要

と理解することである。

### Command substitution と word splitting

command substitution の結果を unquoted な形で `for` に渡す pattern も問題になりやすい。

```bash
for file in $(some_command); do
  ...
done
```

command output に space を含む file name があれば、意図した一件の data が複数 word に分割される。

ShellCheck はこのような command substitution に対して、代表的に `SC2046` などで warning を出す。

line 単位で data を扱うなら、

```bash
while IFS= read -r line; do
  ...
done
```

のように「どの単位で data を読むか」を明確にする方が安全である。

Unit 05 で扱った file name や `while read` と同じく、Shell では文字列をどのように分割するかを意識する。

### Glob と variable

glob 自体は Shell の便利な機能であり、使用してはいけないものではない。

```bash
for file in "$target_dir"/*.log; do
  ...
done
```

ここでは、

```text
"$target_dir"
→ directory 名は 1 value として扱う

*.log
→ glob expansion させる
```

と役割を分けている。

一方、

```bash
for file in $target_dir/*.log; do
  ...
done
```

では variable 部分まで unquoted になり、directory 名に space などがある場合に意図しない splitting が起こる可能性がある。

ShellCheck の warning は単純に「すべて quote する」と読むのではなく、**どこを literal value として扱い、どこを Shell に展開させたいのか**を考える材料にする。

### Unused variable

定義した variable を使っていない場合、typing mistake、削除し忘れ、実装漏れなどの可能性がある。

```bash
report_name='daily-report.txt'
```

を定義したにもかかわらず、その後どこからも参照していない場合、ShellCheck は代表的に `SC2034` を出すことがある。

unused variable が必ず bug というわけではない。  
しかし、

```text
本当に不要
→ 削除する

本来使う予定だった
→ 実装を修正する

意図的に未使用
→ 理由を確認する
```

という判断のきっかけになる。

### Error-prone pattern

Shell Script では、一つ前の command が失敗しても次の command へ進むことがある。

たとえば、

```bash
cd "$target_dir"
printf 'current=%s\n' "$PWD"
```

では `cd` が失敗した場合、元の directory のまま後続処理を行う。

後続処理が destructive operation なら、想定外の場所を変更する危険もある。

そのため、

```bash
if ! cd -- "$target_dir"; then
  exit 1
fi
```

のように failure を確認できる。

ShellCheck はこの種の error-prone pattern についても、Shell 固有の注意点として warning を出す。

### Warning の読み方

ShellCheck warning を見たときは、すぐに suppression したり機械的に suggested fix を入れたりせず、次の順序で確認する。

```text
1. どの file / line か
2. severity は何か
3. SCxxxx code は何か
4. message は何を問題としているか
5. 実際にどの input で問題になるか
6. この Script の意図に合う修正は何か
```

warning は「絶対にそのコードが bug である」という意味ではない。  
static analysis は source code から問題の可能性を推定するため、意図的な pattern に対して warning が出る場合もある。

それでも、まず warning の理由を理解することが先である。

### Suppression

ShellCheck には特定 warning を無効化する directive がある。

```bash
# shellcheck disable=SC2034
value='...'
```

ただし suppression は、

```text
warning が出た
↓
邪魔なので disable
```

という使い方をしない。

基本は、

```text
warning の意味を確認
↓
コードを改善できるか検討
↓
その pattern が本当に意図的か確認
↓
必要な場合だけ suppression
```

という順序にする。

suppression する場合も、可能なら対象を狭くし、なぜその warning を許容するのかコードから分かるようにする。

### Local と CI で同じ check を使う

quality check は editor だけで実行するより、repository 内から CLI で再現できる方が共有しやすい。

この Unit では `quality/quality-check.sh` を用意している。

```bash
bash quality/quality-check.sh
```

内部では、

```text
shfmt -d
ShellCheck
```

を順番に実行する。

同じ Script を local から実行でき、後続 Unit の CI からも呼び出せるなら、

```text
local と CI で rule が違う
```

という状態を減らせる。

この Unit では CI configuration 自体は作成しない。  
CI/CD との統合は Unit 11 で扱う。

## 使用するもの

この Unit では以下を利用する。

- Bash
- `bash -n`
- `shfmt`
- `ShellCheck`
- `diff`
- `cp`
- `mktemp`

最初に command が利用できるか確認する。

```bash
command -v bash
command -v shfmt
command -v shellcheck
```

version も確認する。

```bash
shfmt --version
shellcheck --version
```

`shfmt` または `ShellCheck` が未導入の場合は、使用している Linux distribution の package manager または各 tool の公式 installation 方法で導入する。  
この Unit では特定 distribution の package 管理方法そのものは学習対象にしない。

## 事前準備

Unit 01～07 が完了し、以下を確認済みであることを前提とする。

- Bash Script の基本構文
- variable expansion と quote
- word splitting / glob
- exit status
- safe operation
- file / text processing
- batch / unattended execution
- local CLI tool の実行

Unit 08 へ移動する。

```bash
cd units/08-shfmt-shellcheck-quality
```

成果物を確認する。

```bash
find . -maxdepth 4 -type f | sort
```

```text
08-shfmt-shellcheck-quality/
├─ README.md
├─ examples/
│  ├─ shfmt/
│  │  ├─ 01-unformatted.sh
│  │  └─ 02-formatted.sh
│  └─ shellcheck/
│     ├─ problem/
│     │  ├─ 01-unquoted-variable.sh
│     │  ├─ 02-command-substitution.sh
│     │  ├─ 03-glob.sh
│     │  ├─ 04-unused-variable.sh
│     │  ├─ 05-unchecked-cd.sh
│     │  └─ 06-syntax-error.sh
│     ├─ fixed/
│     │  ├─ 01-unquoted-variable.sh
│     │  ├─ 02-command-substitution.sh
│     │  ├─ 03-glob.sh
│     │  ├─ 04-unused-variable.sh
│     │  └─ 05-unchecked-cd.sh
│     └─ suppression/
│        └─ 01-targeted-suppression.sh
└─ quality/
   └─ quality-check.sh
```

`problem/` 配下は学習のために意図的な warning や syntax error を含む。  
Unit 08 以降の通常コードに対する品質方針とは分けて扱う。

## 学習・実践

### 1. shfmt で formatting と処理内容を分けて確認する

まず整形前の Script を読む。

```bash
cat examples/shfmt/01-unformatted.sh
```

indentation や `{`、`then` 周辺の空白が揃っていないが、Bash syntax としては成立している。

```bash
bash -n examples/shfmt/01-unformatted.sh
echo $?
```

`0` になることを確認する。

実際に実行する。

```bash
bash examples/shfmt/01-unformatted.sh alice
```

次のように表示される。

```text
hello, alice
```

つまり、

```text
formatting が崩れている
≠
syntax error
```

である。

次に `shfmt` の結果を stdout へ表示する。

```bash
shfmt -i 2 examples/shfmt/01-unformatted.sh
```

元 file を変更せず、formatter が整えた形を確認できる。

reference として用意した整形済み file も読む。

```bash
cat examples/shfmt/02-formatted.sh
```

両方とも同じ処理を行う。

```bash
bash examples/shfmt/02-formatted.sh alice
```

ここで `shfmt` は application logic を書き換えるための tool ではなく、source code の format を一定に揃える tool だと確認する。

### 2. format と format check を確認する

repository 内の教材 file を直接変更せず、temporary copy で確認する。

```bash
work_dir=$(mktemp -d)
cp examples/shfmt/01-unformatted.sh "$work_dir/sample.sh"
```

format check を実行する。

```bash
shfmt -i 2 -d "$work_dir/sample.sh"
echo $?
```

formatting 差分が表示され、non-zero になる。

次に file を formatter で書き換える。

```bash
shfmt -i 2 -w "$work_dir/sample.sh"
```

内容を確認する。

```bash
cat "$work_dir/sample.sh"
```

再び check する。

```bash
shfmt -i 2 -d "$work_dir/sample.sh"
echo $?
```

今度は差分がなく `0` になる。

temporary directory を削除する。

```bash
rm -rf -- "$work_dir"
```

この流れから、

```text
-w
→ fix

-d
→ check
```

という用途の違いを確認する。

### 3. ShellCheck warning の基本的な読み方を確認する

最初に unquoted variable の問題コードを解析する。

```bash
shellcheck examples/shellcheck/problem/01-unquoted-variable.sh
echo $?
```

`$name` の quote に関する warning と `SC2086` を確認する。

次に Script 自体は syntax として成立することを確認する。

```bash
bash -n examples/shellcheck/problem/01-unquoted-variable.sh
echo $?
```

`bash -n` は `0` になる。

実際の挙動も比較する。

```bash
bash examples/shellcheck/problem/01-unquoted-variable.sh 'hello world'
```

問題コードでは `hello` と `world` が別 argument として `printf` に渡されるため、複数行になる。

改善版を実行する。

```bash
bash examples/shellcheck/fixed/01-unquoted-variable.sh 'hello world'
```

こちらでは `"hello world"` が一つの value として扱われる。

ShellCheck を実行する。

```bash
shellcheck examples/shellcheck/fixed/01-unquoted-variable.sh
echo $?
```

warning が解消されることを確認する。

ここでは `SC2086` の番号を覚えることより、

```text
unquoted expansion
↓
word splitting / glob expansion
↓
意図した 1 argument が壊れる可能性
↓
quote
```

という因果関係を理解する。

### 4. Command substitution・glob・unused variable の warning を改善する

command substitution の問題を確認する。

```bash
shellcheck examples/shellcheck/problem/02-command-substitution.sh
```

続いて実行する。

```bash
bash examples/shellcheck/problem/02-command-substitution.sh
```

`alpha report.txt` が一件の file name ではなく、

```text
alpha
report.txt
```

へ分かれることを確認する。

改善版を実行する。

```bash
bash examples/shellcheck/fixed/02-command-substitution.sh
```

`while IFS= read -r` を使うことで、line 単位の値を保持する。

```bash
shellcheck examples/shellcheck/fixed/02-command-substitution.sh
```

次に glob の問題を確認する。

```bash
shellcheck examples/shellcheck/problem/03-glob.sh
```

問題は `*.log` そのものではなく、`$target_dir` まで unquoted で展開されている点に注目する。

改善版を読む。

```bash
cat examples/shellcheck/fixed/03-glob.sh
```

```bash
for file in "$target_dir"/*.log; do
```

では directory value を quote しつつ、glob 部分は expansion させている。

```bash
shellcheck examples/shellcheck/fixed/03-glob.sh
```

unused variable も確認する。

```bash
shellcheck examples/shellcheck/problem/04-unused-variable.sh
```

`report_name` が定義されているのに使われていないため、代表的に `SC2034` が表示される。

改善版では output file path の一部として実際に利用する。

```bash
shellcheck examples/shellcheck/fixed/04-unused-variable.sh
bash examples/shellcheck/fixed/04-unused-variable.sh
```

warning ごとに修正方法を暗記するのではなく、「その warning が指している Shell の挙動や実装漏れは何か」を読む。

### 5. Error-prone pattern と syntax error の違いを確認する

unchecked `cd` を解析する。

```bash
shellcheck examples/shellcheck/problem/05-unchecked-cd.sh
```

`cd` が失敗しても後続処理へ進む可能性があることを確認する。

存在しない directory を指定して実行する。

```bash
bash examples/shellcheck/problem/05-unchecked-cd.sh /tmp/unit08-does-not-exist
echo $?
```

`cd` 自体は error になるが、その後の `printf` が実行される。  
そのため最後の command が成功し、Script 全体の exit status が `0` になることにも注目する。

改善版を実行する。

```bash
bash examples/shellcheck/fixed/05-unchecked-cd.sh /tmp/unit08-does-not-exist
echo $?
```

こちらは `cd` failure を検出して non-zero で終了する。

次に意図的な syntax error を確認する。

```bash
bash -n examples/shellcheck/problem/06-syntax-error.sh
echo $?
```

`fi` がないため parse error になる。

ShellCheck でも確認する。

```bash
shellcheck examples/shellcheck/problem/06-syntax-error.sh
echo $?
```

ここでは、

```text
syntax error
→ Shell grammar として成立しない

static analysis warning
→ syntax は成立していても危険・不自然な pattern がある
```

という違いを比較する。

ShellCheck は syntax problem も報告できるが、ShellCheck の価値は syntax check だけに限定されない。

### 6. Suppression は warning の意味を理解してから使う

suppression sample を読む。

```bash
cat examples/shellcheck/suppression/01-targeted-suppression.sh
```

次の directive がある。

```bash
# shellcheck disable=SC2034
```

ShellCheck を実行する。

```bash
shellcheck examples/shellcheck/suppression/01-targeted-suppression.sh
echo $?
```

対象 warning が suppression される。

この sample では external loader が読む metadata という前提を置き、Script 自身から参照しない variable を学習用に再現している。

重要なのは directive の書き方より判断順序である。

```text
warning
↓
原因を理解
↓
通常の修正が可能か確認
↓
意図的なコードなら suppression を検討
```

単に quality check を green にするためだけに suppression を増やさない。

### 7. Local quality check と editor / CI の関係を確認する

通常コードをまとめて check する。

```bash
bash quality/quality-check.sh
```

Script 内では最初に `shfmt -d`、続いて `shellcheck` を実行する。

すべて通れば、

```text
quality checks passed
```

と表示される。

この quality check では `problem/` を対象から外している。  
そこには学習用として意図的な warning / syntax error があるためである。

一方、

```text
examples/shfmt/02-formatted.sh
examples/shellcheck/fixed/
examples/shellcheck/suppression/
quality/quality-check.sh
```

は通常コードとして check 対象になる。

editor integration を使う場合も、保存時に formatter を実行したり ShellCheck diagnostic を表示したりできる。  
ただし最終的に CLI でも同じ check を再現できれば、特定 editor の状態だけに品質確認が依存しない。

後続の CI/CD では、

```bash
bash quality/quality-check.sh
```

と同じ入口を automation から呼び出すこともできる。

Unit 08 では、

```text
local で直す
↓
CLI で確認できる
↓
将来 CI でも同じ check を実行できる
```

という品質管理の流れを理解する。

## 実行・確認ポイント

### shfmt

- formatter は application logic の正しさではなく formatting を扱う。
- `shfmt -i 2 -w` で file を整形できる。
- `shfmt -i 2 -d` で file を変更せず formatting 差分を確認できる。
- format と format check の用途を区別する。
- local と automation で同じ formatting rule を使える状態にする。

### ShellCheck

- static analysis は Script を実行せず source code を解析する。
- warning には `SCxxxx` code と説明がある。
- code 番号の暗記より warning の理由を理解する。
- syntax が正しくても warning が出るコードはある。
- warning がないことだけで runtime correctness が保証されるわけではない。

### Representative warnings

- unquoted variable expansion と word splitting / glob expansion の関係を確認する。
- command substitution の output を word list として扱う危険を確認する。
- variable と glob を組み合わせる際、quote する部分と expansion させる部分を区別する。
- unused variable が typo / implementation omission の発見につながることを理解する。
- unchecked `cd` のように、failure 後も処理が続く pattern を確認する。

### Suppression

- warning の意味を理解する前に suppression しない。
- 通常の修正ができるなら修正を優先する。
- 意図的な pattern で必要な場合だけ利用する。
- suppression の対象をできるだけ狭くする。

### Quality workflow

- editor integration は早い feedback を得るために有効である。
- CLI は editor に依存せず check を再現できる。
- quality check を一つの command にまとめると local / CI で共有しやすい。
- 意図的な problem sample と通常の品質対象コードを区別する。

## 学習ポイント

### Formatter と static analysis は「どちらか一方」ではない

`shfmt` で整形されたコードでも、unquoted variable のような問題は残り得る。

逆に ShellCheck が warning を出さないコードでも、team 内で indentation や空白がばらばらになることはある。

```text
shfmt
→ consistency / readability

ShellCheck
→ Shell-specific problems / pitfalls
```

という別々の役割を組み合わせる。

### Tool の出力を理解することが品質改善の本体

ShellCheck を導入しても、

```text
warning が出る
↓
意味を読まずに suppression
```

では学習にも品質改善にもつながらない。

特に Shell は、

```text
quote
word splitting
glob
exit status
current directory
```

など、見た目だけでは挙動を誤解しやすい部分がある。

warning は「修正指示」だけではなく、Shell の挙動を学ぶ入口として利用できる。

### ShellCheck warning は context を考えて判断する

static analysis は runtime のすべてを知ることはできない。

そのため warning に対して、

```text
常に tool が正しい
```

とも、

```text
動いているから warning は無視してよい
```

とも考えない。

まず tool が何を懸念しているか理解し、その Script の input、execution environment、目的を踏まえて判断する。

### Quote は warning を消すためではなく data boundary を守るために使う

`"$value"` の double quote は、ShellCheck を満足させるための記号ではない。

```text
一つの variable value
↓
一つの command argument
```

として渡したいとき、その境界を守る意味がある。

一方 glob の `*.log` のように Shell に pathname expansion させたい部分まで quote すれば、今度は意図した expansion が行われない。

つまり「全部 quote」ではなく、**どの expansion を意図しているか**が重要である。

### Syntax check・static analysis・test は別の層

品質確認は一つの tool だけでは完結しない。

```text
bash -n
→ parse / syntax

shfmt
→ format

ShellCheck
→ static analysis

実際の実行 / test
→ runtime behavior
```

それぞれ検出できる問題が異なる。

後続 Unit 09 では Bats を利用した automated testing を扱うため、この Unit の static analysis と runtime test の違いがそのままつながる。

### Editor integration は品質ルールそのものではない

editor が保存時に自動 format してくれることは便利である。

しかし、

```text
自分の editor では warning が見える
```

だけでは、repository 全体の品質ルールとして再現できるとは限らない。

CLI command として再現可能にしておけば、

```text
different editor
another developer
CI
```

でも同じ rule を利用しやすくなる。

### Local と CI で同じ tool を使うと feedback のずれを減らせる

local では A という formatter、CI では B という formatter を使えば、developer が手元で通したコードが CI で失敗する可能性が増える。

```text
local
shfmt + ShellCheck

CI
shfmt + ShellCheck
```

のように同じ tool と設定を利用すれば、

```text
local で確認した結果
≈
CI で確認する結果
```

に近づけられる。

Unit 11 ではこの考え方を CI/CD pipeline へ接続する。

### Suppression は品質ルールの例外なので、理由が重要になる

suppression は悪い機能ではない。  
static analysis には false positive や、project 固有の意図と一致しない warning があり得る。

ただし suppression は、

```text
通常 rule
↓
この場所だけ例外
```

を意味する。

そのため「なぜ例外なのか」が分からない suppression が増えると、将来本当に問題のある warning まで見逃しやすくなる。
