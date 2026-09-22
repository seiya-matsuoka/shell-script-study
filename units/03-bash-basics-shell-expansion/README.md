# 03. Bash Script の基本と Shell 展開

## この Unit の目的

Bash の基本を改めて整理し、実用的な Shell Script を正しく読むための基礎を作り直す。  
この Unit では、Script の基本、variable、argument、parameter expansion、command substitution、arithmetic expansion、pathname expansion、quote、条件分岐、loop、function、出力、option parsing を扱う。  
個々の構文を暗記するだけではなく、Shell が文字列や variable をどのように展開し、最終的に command と argument として解釈するのかを意識しながらサンプルを読む。

特に quote は Shell Script の安全性・可読性に直結するため、unquoted / single quote / double quote、word splitting、glob の関係を重点的に確認する。  
また、Bash を本学習の主軸とする理由を整理し、POSIX `sh` との違いや Bash 固有機能の存在についても基本を確認する。

## 学習内容

### Script の基本

Bash Script は、Bash に複数の command や制御構文をまとめて実行させる text file である。  
この学習では Bash を主軸とするため、基本的な shebang として以下を利用する。

```bash
#!/usr/bin/env bash
```

shebang は Script file を直接実行するときに、どの interpreter を利用するかを OS 側へ伝えるための記述である。  
`/usr/bin/env bash` では、`env` が `PATH` から `bash` を探索して起動する。

たとえば execute permission がある Script を以下のように直接実行する場合、shebang が interpreter の選択に関係する。

```bash
./script.sh
```

一方、以下のように明示的に Bash を起動する場合は、Bash が指定した file を読み込んで実行する。

```bash
bash script.sh
```

この違いは Unit 02 で扱った execute permission ともつながる。

Bash の comment は `#` から始まり、通常その行の残りは実行対象にならない。

```bash
# comment
printf '%s\n' 'executed'
```

`exit` は Script / Shell process の実行を終了し、呼び出し元へ exit status を返す。

```bash
exit 0
```

`exit` より後ろの command は実行されない。  
`0` は一般的に成功を表し、non-zero は失敗やその他の状態を表す。この考え方は Unit 01 で確認した exit status と同じである。

### Variable と environment

Bash では以下のように Shell variable を定義する。

```bash
name='Bash'
```

代入では `=` の前後に空白を入れない。  
参照するときは `$name` や `${name}` を利用する。

```bash
printf '%s\n' "$name"
printf '%s\n' "${name}"
```

`readonly` を利用すると、それ以降の再代入を禁止できる。

```bash
readonly config_path='/path/to/config'
```

値を途中で変更すべきでないことを Script 上で明示できるため、意図しない再代入を防ぎたい場合に利用できる。

`export` した variable は、後から起動する child process の environment に渡される。

```bash
export APP_ENV='development'
```

この Unit では variable の基本構文として改めて確認するが、Shell variable と environment variable の process 間の関係自体は Unit 01 で扱った内容を前提とする。

### Script argument と positional parameter

Shell Script へ渡された argument は positional parameter として参照できる。

```text
$0  Script の呼び出し名
$1  1 番目の argument
$2  2 番目の argument
...
$#  positional parameter の個数
```

たとえば以下のように実行する。

```bash
bash script.sh alpha 'beta gamma'
```

Script 内では `$1` が `alpha`、`$2` が `beta gamma` になる。

#### `"$@"`

`"$@"` は、すべての positional parameter を、それぞれ独立した argument のまま展開する。

```bash
for argument in "$@"; do
  printf '<%s>\n' "$argument"
done
```

`beta gamma` のように空白を含む argument が渡されても、`"$@"` であれば一つの argument として保持される。  
Script が受け取った複数 argument をそのまま別の command や function へ渡すときにも重要な書き方である。

#### `"$*"`

`"$*"` も positional parameter 全体にアクセスする記法だが、double quote 内では全 argument を一つの文字列として展開する。  
そのため、個々の argument の境界を保持したい場面では、通常 `"$@"` を利用する方が適している。

#### `shift`

`shift` は先頭の positional parameter を取り除き、それ以降を一つずつ前へずらす。

```text
実行前:
$1 = alpha
$2 = beta
$3 = gamma

shift 後:
$1 = beta
$2 = gamma
```

option parsing などで処理済みの argument を除外するときに利用される。  
この Unit では基本的な動作だけを確認する。

#### `$?`

`$?` は直前の command の exit status を表す。

```bash
false
status=$?
```

Unit 01 でも確認したとおり、次の command を実行すると `$?` はその command の結果に更新されるため、必要な場合は直後に variable へ保存する。

### Parameter expansion

Shell では variable を参照するとき、単に値を取り出すだけでなく、parameter expansion によって default value や必須値の確認なども行える。

#### `$var` と `${var}`

単純な参照では以下のどちらも利用できる。

```bash
printf '%s\n' "$name"
printf '%s\n' "${name}"
```

`${...}` は variable 名の境界を明確にしたい場合に必要になる。

```bash
name='Bash'
printf '%s\n' "${name}_script"
```

`$name_script` と書くと、Shell は `name_script` という variable を参照しようとする。  
`${name}_script` と書けば、`name` の値に `_script` を続ける意図を明確にできる。

#### `${var:-default}`

`${var:-default}` は、`var` が unset または empty の場合に `default` を利用する。

```bash
value=${CONFIG_VALUE:-default}
```

設定値がなければ既定値を利用するような Script でよく使われる。

```text
unset  → default
empty  → default
value  → value
```

この展開自体は元の variable へ default value を代入するわけではない。  
「その展開結果として default を利用する」と捉える。

#### `${var:?message}`

`${var:?message}` は、`var` が unset または empty の場合に `message` を stderr へ出し、その Shell の処理を終了させる。

```bash
: "${REQUIRED_VALUE:?REQUIRED_VALUE is required}"
```

必須 environment variable や設定値が存在しない状態で処理を継続させたくない場合に利用できる。  
この Unit のサンプルでは、学習用 Script 自体まで終了しないよう child Bash の中で挙動を確認する。

### Command substitution

command substitution `$()` は、command の stdout を文字列として取り込む。

```bash
current_directory=$(pwd)
```

この場合、`pwd` の stdout が `current_directory` に代入される。

```text
command
↓ stdout
$()
↓
Shell variable
```

function の stdout を値として利用するときにも同じ仕組みを使う。  
後半の function のサンプルで改めて確認する。

旧来の backquote 記法 `` `command` `` も存在するが、本学習では読みやすく nest しやすい `$()` を基本とする。

### Arithmetic expansion

arithmetic expansion `$(( ))` は整数の算術式を評価する。

```bash
count=5
next=$((count + 1))
```

Bash の arithmetic context では、integer variable を `$count` と書かず `count` と参照できる場合がある。

```bash
total=$((count * 3))
```

条件式として `(( ... ))` を利用する書き方もあり、この Unit の `if` / `while` で使用する。

### Pathname expansion / glob

Bash では `*`、`?`、`[...]` などの pattern を利用して path を展開できる。  
この Unit では代表的な `*` を確認する。

```bash
for path in /tmp/example/*.txt; do
  ...
done
```

pattern に一致する file が存在すると、Shell が command を実行する前に matching path へ展開する。

```text
*.txt
↓ pathname expansion
alpha.txt beta.txt
```

この仕組みは command 自体の機能ではなく Shell expansion である。  
たとえば `ls *.txt` では、多くの場合 `ls` が `*.txt` を展開しているのではなく、Bash が展開後の path を `ls` の argument として渡している。

### Word splitting

unquoted の variable expansion などでは、展開結果が `IFS` に基づいて複数の word に分割される場合がある。

```bash
value='alpha beta gamma'
command $value
```

このとき、`command` には複数 argument として渡る可能性がある。

```text
$1 = alpha
$2 = beta
$3 = gamma
```

一方、double quote すると一つの argument として保持できる。

```bash
command "$value"
```

```text
$1 = alpha beta gamma
```

Shell Script で variable を扱うときに `"$variable"` を基本とする大きな理由の一つが、この word splitting を意図せず発生させないためである。

### Brace expansion

brace expansion は Bash が複数の word を生成する展開である。

```bash
file-{a,b,c}.txt
```

以下のように展開される。

```text
file-a.txt
file-b.txt
file-c.txt
```

連番も利用できる。

```bash
{1..3}
```

この Unit では基本形だけを確認する。  
parameter expansion の `${var}` と見た目が似ているが、brace expansion は variable を参照する機能ではない。

### Quote

Shell Script では quote の有無によって expansion の結果が大きく変わる。  
特に unquoted / single quote / double quote の違いを理解することが重要である。

#### Unquoted

variable を quote せずに展開すると、word splitting や pathname expansion の影響を受ける場合がある。

```bash
value='alpha beta'
command $value
```

意図的に splitting や glob を利用したい場合を除き、variable expansion を unquoted にすることには注意が必要である。

#### Single quote

single quote 内では、variable expansion や command substitution などが基本的に行われない。

```bash
name='Bash'
printf '%s\n' '$name'
```

出力は `$name` という文字列そのものになる。

#### Double quote

double quote 内では variable expansion や command substitution などが行われる一方、展開結果を一つの argument として保持しやすい。

```bash
name='Bash Script'
printf '%s\n' "$name"
```

そのため、Shell variable を argument として渡す場合は、基本的に double quote する。

```bash
command "$variable"
```

#### Quote と glob

glob pattern を variable に入れた場合も、quote の有無で挙動が変わる。

```bash
pattern='/tmp/*.txt'
```

unquoted で展開すると pathname expansion の対象になる。

```bash
command $pattern
```

double quote すると `*` を含む文字列そのものが一つの argument になる。

```bash
command "$pattern"
```

つまり double quote は「variable expansion を止める」のではなく、variable expansion は行いながら、その結果に対する word splitting や pathname expansion を抑える役割を持つ。

### 条件分岐

Bash では `if / elif / else` を利用して command の成功・失敗に応じた処理を記述できる。

```bash
if condition; then
  ...
elif other_condition; then
  ...
else
  ...
fi
```

Bash の `if` は一般的な programming language の boolean 値そのものを評価するというより、condition 部分で実行した command や conditional expression の exit status を基準に分岐すると考えると理解しやすい。

#### `[ ]`

`[ ... ]` は test command として条件判定に利用される。

```bash
if [ "$value" = 'expected' ]; then
  ...
fi
```

`[` と `]` も構文上の飾りではなく、argument として正しく分離して記述する必要がある。  
variable を利用するときは quote して argument 境界を守ることが重要である。

#### `[[ ]]`

`[[ ... ]]` は Bash の conditional expression である。

```bash
if [[ $value == 'expected' ]]; then
  ...
fi
```

Bash Script では、word splitting / pathname expansion の扱いや pattern matching などの面で `[ ]` より扱いやすい場面が多い。  
ただし Bash 固有機能であり、POSIX `sh` では利用できない。

#### String comparison

文字列の一致・不一致は、たとえば `[[ ... ]]` では以下のように書ける。

```bash
[[ $left == "$right" ]]
[[ $left != "$right" ]]
```

#### Numeric comparison

`[[ ... ]]` で `-gt`、`-lt`、`-eq` などを利用できる。

```bash
[[ $number -gt 5 ]]
```

Bash では arithmetic context として `(( ... ))` も利用できる。

```bash
((number > 5))
```

この Unit の単純な integer 条件では `(( ... ))` も使用する。

#### File test

`[[ ... ]]` や `[ ... ]` では file の状態を調べる operator が利用できる。

```bash
[[ -f $path ]]
```

`-f` は regular file が存在するかを確認する。  
ほかにも directory などを確認する test があるが、この Unit では基本的な file test の利用方法を確認する。

#### `case`

`case` は、一つの値を複数の pattern と照合して処理を分岐するときに利用しやすい。

```bash
case "$command_name" in
  start)
    ...
    ;;
  stop)
    ...
    ;;
  *)
    ...
    ;;
esac
```

option や command 名、状態名など、候補が明確な値を分岐する場合に読みやすい。

#### Bash regex

Bash の `[[ ... ]]` では `=~` による regular expression match も利用できる。

```bash
[[ $value =~ ^user-[0-9]+$ ]]
```

この Unit では存在と基本的な読み方だけを確認し、複雑な regex の設計は対象にしない。

### Loop

Bash では `for`、`while`、`until` などで繰り返し処理を記述できる。

#### `for`

argument や list を順番に処理する場合に `for` を利用できる。

```bash
for argument in "$@"; do
  ...
done
```

`"$@"` と組み合わせると、Script が受け取った各 argument の境界を保ったまま順番に処理できる。

#### `while`

条件が成功している間、処理を繰り返す。

```bash
while ((count <= 3)); do
  ...
done
```

counter だけでなく、command が成功している間の retry や、入力を読み続ける処理などにも利用される。

#### `while IFS= read -r`

text file や stdin を 1 行ずつ安全に読む基本形として、以下の書き方がよく利用される。

```bash
while IFS= read -r line; do
  ...
done < input.txt
```

`IFS=` は `read` が入力行の先頭・末尾の IFS whitespace を取り除かないようにするために利用する。  
`read -r` は backslash を escape として解釈せず、そのまま読み取る。

単純な text file を「行の内容をなるべくそのまま」処理したい場合に重要な組み合わせである。

#### `until`

`until` は condition が失敗している間、処理を繰り返す。

```bash
until ((count > 3)); do
  ...
done
```

`while` と反対向きの条件として読むことができる。  
利用頻度は `while` より低いことも多いため、この Unit では基本形だけを確認する。

### Function

Bash では一連の処理を function としてまとめられる。

```bash
show_message() {
  ...
}
```

function を利用すると、繰り返し使う処理や意味のある処理単位に名前を付けられる。

#### Function の positional parameter

function に argument を渡すと、その function 内では `$1`、`$2` などとして参照できる。

```bash
format_name() {
  local first_name=$1
  local last_name=$2
}
```

Script 自体の positional parameter と同じ記法だが、function 実行中はその function へ渡した argument が対象になる。

#### `local`

Bash function 内では `local` を利用して、その function の scope で使う variable を宣言できる。

```bash
local name=$1
```

function 内部だけで利用する値を global な Shell variable と区別しやすくなり、意図しない上書きを避けるためにも役立つ。

#### `return`

`return` は function の実行を終了し、status を呼び出し元へ返す。

```bash
return 0
return 1
```

Shell function の `return` は、Java などの `return "value"` のように任意の data を返す用途とは異なる。  
返す数値は function の exit status として扱われる。

そのため、成功・失敗を function の結果として利用する場合は、以下のように `if` から直接 function を評価できる。

```bash
if is_valid; then
  ...
fi
```

#### `return` と `exit`

`return` は function から戻る。  
`exit` は Script / Shell process 全体を終了する。

```text
return
→ function を終了
→ caller の処理へ戻る

exit
→ Script / Shell process を終了
→ 後続処理へ戻らない
```

function 内で不用意に `exit` を使うと、その function だけでなく Script 全体が終了する点に注意する。

#### stdout を値として扱う

Shell function で data を呼び出し元へ渡したい場合、stdout に結果を出力し、command substitution で受け取る方法がある。

```bash
build_message() {
  printf '%s\n' 'result'
}

value=$(build_message)
```

この場合、function の stdout が値として利用される。  
そのため、function が「返り値」として stdout を利用する設計では、debug message などを同じ stdout へ混ぜると取得する値にも混ざる。

```text
stdout
→ caller が値として利用する data

stderr
→ diagnostic message
```

という使い分けが重要になる場合がある。

### `echo` と `printf`

`echo` は簡単な文字列出力に利用できる。

```bash
echo 'hello'
```

一方、option のように見える文字列や backslash escape の扱いは実装や状況によって分かりにくくなる場合がある。  
format と argument を明示したい場合は `printf` が予測しやすい。

```bash
printf 'name=%s count=%d\n' "$name" "$count"
```

この学習でも、出力形式を明確にしたい箇所では基本的に `printf` を利用する。  
ただし `echo` 自体を禁止するわけではなく、単純な用途で利用されている Script を読めることも必要である。

### Option parsing と `getopts`

Script の入力には、位置によって意味を持つ positional argument と、`-v` や `-n value` のような option がある。

```bash
script.sh input.txt
script.sh -v -n Bash input.txt
```

単純な Script では自前で `$1`、`$2` を読むこともできるが、short option の解析には Bash builtin の `getopts` を利用できる。

```bash
while getopts ':vn:' option; do
  ...
done
```

option string の意味を以下のように読む。

```text
v   → -v は argument なし
n:  → -n は argument が必要
```

option argument は `$OPTARG` から取得する。  
`getopts` の解析位置は `$OPTIND` で管理される。

解析後に以下を実行すると、処理済み option を positional parameter から取り除ける。

```bash
shift $((OPTIND - 1))
```

その後は残った positional argument を `$1` などから通常どおり参照できる。

この Unit では short option の基本的な解析までを扱う。  
long option、複雑な CLI interface、subcommand parser などは対象外とする。

### Bash と POSIX `sh`

Shell Script には Bash を前提とする Script と、POSIX `sh` で動作することを意識した Script がある。  
この学習では Bash を主軸とする。

理由は、実務上広く利用され、基本的な Shell Script に加えて以下のような Bash の機能を利用できるためである。

- `[[ ... ]]`
- array
- `local`
- Bash arithmetic
- `getopts`
- `pipefail`
- その他の Bash 固有機能

たとえば Bash array は以下のように利用する。

```bash
items=('alpha' 'beta gamma')

for item in "${items[@]}"; do
  ...
done
```

array はこの Unit では基本形だけを確認する。

一方、`#!/bin/sh` の Script では、実行環境の `/bin/sh` が Bash とは限らない。  
Ubuntu などでは `/bin/sh` が `dash` である場合もある。

そのため、Bash 固有機能を利用する Script を `/bin/sh` 前提で書くと動作しない可能性がある。

```text
#!/usr/bin/env bash
→ Bash を前提にして Bash 機能を利用する

#!/bin/sh
→ POSIX sh を意識した構文を利用する
```

本学習では無理に POSIX `sh` へ合わせず、Bash Script として明示しながら Bash の基本と安全な書き方を学ぶ。

## 使用するもの

この Unit では、主に以下を利用する。

- WSL 2 上の Linux
- Bash
- POSIX `sh`
- `printf`
- `echo`
- `pwd`
- `false`
- `cat`
- `touch`
- `mktemp`
- `rm`
- `rmdir`
- `getopts`
- `shift`
- `read`

追加 package や外部 library は使用しない。

## 事前準備

Unit 01・02 が完了し、process / exit status、stdin / stdout / stderr、file / path / permission の基本を確認済みであることを前提とする。  
Bash と `/bin/sh` が利用できることを確認する。

```bash
bash --version
```

```bash
sh -c 'printf "%s\n" "$0"'
```

リポジトリ root から Unit 03 へ移動する。

```bash
cd units/03-bash-basics-shell-expansion
```

成果物を確認する。

```bash
find . -maxdepth 3 -type f | sort
```

以下の構成になっていることを確認する。

```text
03-bash-basics-shell-expansion/
├─ README.md
└─ examples/
   ├─ bash-posix-sh/
   │  ├─ 01-bash-specific-features.sh
   │  └─ 02-posix-sh-compatible.sh
   ├─ condition/
   │  ├─ 01-if-elif-else.sh
   │  ├─ 02-test-single-double-brackets.sh
   │  ├─ 03-string-numeric-file-tests.sh
   │  ├─ 04-case.sh
   │  └─ 05-bash-regex.sh
   ├─ function/
   │  ├─ 01-function-local-parameters.sh
   │  ├─ 02-return-status.sh
   │  ├─ 03-return-vs-exit.sh
   │  └─ 04-stdout-as-value.sh
   ├─ loop/
   │  ├─ 01-for.sh
   │  ├─ 02-while-counter.sh
   │  ├─ 03-while-read.sh
   │  └─ 04-until.sh
   ├─ option-parsing/
   │  └─ 01-getopts.sh
   ├─ output/
   │  └─ 01-echo-printf.sh
   ├─ parameter-expansion/
   │  ├─ 01-basic-braces.sh
   │  ├─ 02-default-value.sh
   │  └─ 03-required-value.sh
   ├─ quoting/
   │  ├─ 01-unquoted-single-double.sh
   │  ├─ 02-word-splitting.sh
   │  ├─ 03-quote-and-glob.sh
   │  └─ 04-why-quote-variables.sh
   ├─ script-basics/
   │  └─ 01-shebang-exit.sh
   ├─ shell-expansion/
   │  ├─ 01-command-substitution.sh
   │  ├─ 02-arithmetic-expansion.sh
   │  ├─ 03-pathname-expansion.sh
   │  └─ 04-brace-expansion.sh
   └─ variables-arguments/
      ├─ 01-variable-readonly-export.sh
      ├─ 02-positional-parameters.sh
      ├─ 03-dollar-star-and-shift.sh
      └─ 04-last-exit-status.sh
```

この Unit では expansion や quote の実行結果を比較することが重要なため、各 Script の source code と実行結果を対応させながら進める。  
`bash -x` は展開後の command を観察する補助として有用だが、trace 自体が output の比較を見づらくする場合もあるため、通常実行を基本とし、必要な箇所だけ追加で利用する。

## 学習・実践

### 1. Script の基本・variable・argument を確認する

まず shebang、comment、`exit` の基本を確認する。

```bash
bash examples/script-basics/01-shebang-exit.sh
```

`script started` が出力された後、`exit 0` によって Script が終了する。  
`exit` より後ろにある `this line is not executed` が表示されないことを確認する。

続いて、execute permission が付いている状態では直接実行も確認できる。

```bash
./examples/script-basics/01-shebang-exit.sh
```

この場合は file 先頭の `#!/usr/bin/env bash` が interpreter 選択に利用される。

次に variable、`readonly`、`export` を確認する。

```bash
bash examples/variables-arguments/01-variable-readonly-export.sh
```

通常の Shell variable を参照できること、`readonly` で固定した値を利用していること、`exported_value` が child Bash から参照できることを確認する。  
`readonly` の再代入エラー自体をこの Script では発生させず、「変更させない variable を宣言できる」という基本を source code から確認する。

positional parameter を確認する。

```bash
bash examples/variables-arguments/02-positional-parameters.sh alpha 'beta gamma'
```

`$0` には Script の path、`$#` には `2` が表示される。  
`"$@"` を loop すると、`alpha` と `beta gamma` がそれぞれ一つの argument として保持されていることを確認する。

`"$*"` と `shift` も軽く確認する。

```bash
bash examples/variables-arguments/03-dollar-star-and-shift.sh alpha 'beta gamma' delta
```

`"$*"` では positional parameter 全体が一つの文字列として出力される。  
その後 `shift` を実行すると、先頭の `alpha` が取り除かれ、`$1` が `beta gamma` になる。

最後に `$?` を確認する。

```bash
bash examples/variables-arguments/04-last-exit-status.sh
```

`false` の直後に `$?` を保存しているため、non-zero の status が出力される。

### 2. Parameter expansion を確認する

まず `$var` と `${var}` の基本を確認する。

```bash
bash examples/parameter-expansion/01-basic-braces.sh
```

`$name` で値を参照できることに加え、`${name}_script` と書くことで variable 名の境界を明示して `Bash_script` のような文字列を作れることを確認する。

次に default value を確認する。

```bash
bash examples/parameter-expansion/02-default-value.sh
```

`${configured_value:-default value}` の結果を、unset / empty / value 設定済みの 3 状態で比較する。

```text
unset
→ default value

empty
→ default value

configured
→ configured
```

最後に必須値の確認を行う。

```bash
bash examples/parameter-expansion/03-required-value.sh
```

child Bash 内で `REQUIRED_VALUE` を unset にしたまま `${REQUIRED_VALUE:?REQUIRED_VALUE is required}` を展開する。  
message が stderr に出力され、child Bash が non-zero で終了することを確認する。

このサンプルでは stderr を temporary file へ redirect してから表示しているため、parameter expansion の error message と child process の exit status の両方を確認できる。

### 3. Command・arithmetic・pathname・brace expansion を確認する

command substitution から確認する。

```bash
bash examples/shell-expansion/01-command-substitution.sh
```

`pwd` の stdout が `$()` によって取得され、`current_directory` に入っていることを確認する。

次に arithmetic expansion を確認する。

```bash
bash examples/shell-expansion/02-arithmetic-expansion.sh
```

`count=5` に対して `$((count + 1))` が `6`、`$((count * 3))` が `15` になる。  
通常の文字列展開ではなく、integer の算術式として評価される。

pathname expansion を確認する。

```bash
bash examples/shell-expansion/03-pathname-expansion.sh
```

temporary directory に `alpha.txt`、`beta.txt`、`gamma.log` を作成し、`"$work_dir"/*.txt` に一致する `.txt` file だけが loop の対象になる。

source code では `*.txt` という pattern だが、実際に loop body が受け取る `path` は matching した実 file path である。  
Shell が command / loop の実行前に pathname expansion を行っていることを意識する。

brace expansion を軽く確認する。

```bash
bash examples/shell-expansion/04-brace-expansion.sh
```

`file-{a,b,c}.txt` が 3 つの word に、`number-{1..3}` が連番の word に展開される。  
`${var}` と `{a,b}` は見た目が似ていても別の機能であることを区別する。

### 4. Quote・word splitting・glob の関係を確認する

まず unquoted / single quote / double quote を比較する。

```bash
bash examples/quoting/01-unquoted-single-double.sh
```

`value='hello world'` を unquoted で `set -- $value` に渡すと、word splitting によって positional parameter が 2 つになる。  
single quote の `'$value'` は variable expansion されず、そのまま `$value` と表示される。  
double quote の `"$value"` は variable expansion される一方、`hello world` を一つの値として扱える。

次に word splitting を argument 数として比較する。

```bash
bash examples/quoting/02-word-splitting.sh
```

unquoted の `show_arguments $value` では 3 arguments、double quote した `show_arguments "$value"` では 1 argument になる。  
画面上の文字列だけでなく、受け取る側から見た argument の数が実際に変わっていることを確認する。

続いて quote と glob を比較する。

```bash
bash examples/quoting/03-quote-and-glob.sh
```

`pattern` には `.../*.txt` という文字列が入っている。

unquoted の場合、

```bash
show_arguments $pattern
```

variable expansion 後の `*.txt` が pathname expansion され、matching した 2 file が別々の arguments として渡る。

double quote した場合、

```bash
show_arguments "$pattern"
```

pathname expansion は行われず、`*.txt` を含む文字列そのものが 1 argument として渡る。

最後に、実際の file path を variable で扱う場合を確認する。

```bash
bash examples/quoting/04-why-quote-variables.sh
```

空白を含む `report 2026.txt` の path を `"$file_path"` として `cat` に渡すことで、path 全体を一つの argument として正しく処理できる。

この一連の比較から、「variable は常に quote しなければならない」と機械的に覚えるのではなく、**unquoted expansion では word splitting と pathname expansion が起こり得るため、意図がなければ `"$variable"` を基本にする**と理解する。

### 5. 条件分岐と test を確認する

`if / elif / else` から確認する。

```bash
bash examples/condition/01-if-elif-else.sh 85
```

`85` では `high` が出力される。

入力を変えて比較する。

```bash
bash examples/condition/01-if-elif-else.sh 70
bash examples/condition/01-if-elif-else.sh 40
```

それぞれ `middle`、`low` になることを確認する。  
この Script では `(( ... ))` の arithmetic condition を利用している。

次に `[ ]` と `[[ ]]` を比較する。

```bash
bash examples/condition/02-test-single-double-brackets.sh
```

どちらも `hello world` との一致を判定するが、source code 上の quote の扱いに注目する。

```bash
[ "$value" = 'hello world' ]
[[ $value == 'hello world' ]]
```

`[ ]` では variable を quote して一つの argument として保持している。  
`[[ ]]` は Bash の conditional expression で、word splitting / pathname expansion の扱いが異なる。

string / numeric / file test を確認する。

```bash
bash examples/condition/03-string-numeric-file-tests.sh
```

以下の 3 種類の判定が行われる。

```text
string:
$left != "$right"

numeric:
$number -gt 5

file:
-f $temp_file
```

同じ `[[ ... ]]` の中でも、目的に応じた operator が利用されることを確認する。

`case` を確認する。

```bash
bash examples/condition/04-case.sh start
bash examples/condition/04-case.sh stop
bash examples/condition/04-case.sh restart
```

一つの値を複数の pattern へ分岐する形を確認する。

対象外の値も試す。

```bash
bash examples/condition/04-case.sh unknown
```

stderr に unknown command が出力され、Script が non-zero で終了する。  
必要であれば直後に以下で status を確認する。

```bash
printf '%s\n' "$?"
```

最後に Bash regex を軽く確認する。

```bash
bash examples/condition/05-bash-regex.sh
```

`user-123` が `^user-[0-9]+$` に match し、`regex matched` が表示される。  
この Unit では `=~` が Bash の `[[ ]]` で利用できることを確認するまでとする。

### 6. Loop の基本を確認する

`for` と `"$@"` の組み合わせから確認する。

```bash
bash examples/loop/01-for.sh alpha 'beta gamma' delta
```

3 arguments がそれぞれ独立した値として順番に処理され、`beta gamma` も一つの argument のまま保持される。

次に `while` を確認する。

```bash
bash examples/loop/02-while-counter.sh
```

`count` が `1` から `3` まで出力される。  
`((count <= 3))` が成功している間 loop が続き、各 iteration で `((count += 1))` によって値を増やしている。

text file を 1 行ずつ読む基本形を確認する。

```bash
bash examples/loop/03-while-read.sh
```

以下の入力が 1 行ずつ読み取られる。

```text
first line
second line with spaces
backslash \ stays
```

source code の以下の部分に注目する。

```bash
while IFS= read -r line; do
  ...
done < "$input_file"
```

`IFS=` と `read -r` によって、空白や backslash を含む行を余計に変換せず読み取ろうとしている。  
Shell Script で line-oriented な text を処理するときの重要な基本形として覚えておく。

最後に `until` を軽く確認する。

```bash
bash examples/loop/04-until.sh
```

`count > 3` が成立するまで loop が続くため、結果として `1`、`2`、`3` が表示される。  
`while` と条件の向きが逆であることを確認する。

### 7. Function・`local`・`return` を確認する

function の argument と `local` から確認する。

```bash
bash examples/function/01-function-local-parameters.sh
```

`format_name 'Seiya' 'Matsuoka'` に渡した 2 arguments が、function 内では `$1` / `$2` として参照される。  
それぞれを `local` variable に代入して利用していることを確認する。

次に function の `return` を確認する。

```bash
bash examples/function/02-return-status.sh
```

`is_even` は偶数なら `return 0`、奇数なら `return 1` としている。  
呼び出し側では function の status を `if` や `!` で条件として利用している。

```text
return 0
→ success
→ if 側へ進む

return 1
→ failure
→ ! で反転すると condition success
```

`return` と `exit` の違いを確認する。

```bash
bash examples/function/03-return-vs-exit.sh
```

`return_example` は `return 0` で function を終了するため、その後 Script は継続し、`script continues after return` が表示される。

一方、`exit 7` は child Bash の中で実行し、child process 全体が終了する。  
親側ではその exit status を取得し、`child exit status=7` と確認する。

最後に stdout を値として扱う例を確認する。

```bash
bash examples/function/04-stdout-as-value.sh
```

`build_message` が stdout へ出した `hello Bash` を、以下の command substitution が受け取る。

```bash
message=$(build_message 'Bash')
```

function の stdout を data として利用する場合は、不要な説明や debug 出力を stdout に混ぜると値にも混ざることを意識する。

### 8. `echo` と `printf` の基本を確認する

出力方法を比較する。

```bash
bash examples/output/01-echo-printf.sh
```

`echo` でも単純な文字列は表示できる。  
`printf` では format string に `%s`、`%d` などを指定し、argument を明確に当てはめて出力できる。

```bash
printf 'name=%s count=%d\n' 'Bash' 3
```

この学習では、出力形式や argument の境界を明確にしやすいため `printf` を中心に利用する。  
ただし、既存 Script で `echo` を見たときに意味を追えることも必要である。

### 9. `getopts` で option を解析する

short option と positional argument を組み合わせた Script を確認する。

```bash
bash examples/option-parsing/01-getopts.sh -v -n Seiya input.txt
```

`-v` によって verbose が有効になり、`-n Seiya` の `Seiya` が `$OPTARG` として取得される。  
option 解析後、`shift $((OPTIND - 1))` によって処理済み option が除外され、残った `input.txt` が `$1` になる。

実行結果として以下の情報を確認する。

```text
name=Seiya
argument=input.txt
```

`-n` の argument を省略した場合も確認する。

```bash
bash examples/option-parsing/01-getopts.sh -n
```

stderr に不足している option argument と usage が表示され、non-zero で終了する。

unknown option も確認する。

```bash
bash examples/option-parsing/01-getopts.sh -x
```

unknown option と usage が stderr に表示される。

ここでは `getopts` の内部を暗記するより、以下の流れを把握する。

```text
getopts で option を 1 つずつ読む
↓
case で option ごとの処理
↓
$OPTARG から option argument を取得
↓
$OPTIND を使って処理済み option を shift
↓
残った positional argument を処理
```

### 10. Bash と POSIX `sh` の違いを確認する

まず Bash 固有機能を利用する Script を確認する。

```bash
bash examples/bash-posix-sh/01-bash-specific-features.sh
```

この Script では以下を利用している。

- array
- `"${items[@]}"`
- `[[ ... ]]`
- `local`

`beta gamma` が array の一要素として保持されることや、`[[ ]]` が Bash で利用できることを確認する。

shebang が Bash を指定しているため、直接実行もできる。

```bash
./examples/bash-posix-sh/01-bash-specific-features.sh
```

次に POSIX `sh` を意識した Script を確認する。

```bash
sh examples/bash-posix-sh/02-posix-sh-compatible.sh
```

こちらでは `[ ]`、通常の variable、`for`、`printf` など基本的な構文だけを利用し、Bash array や `[[ ]]` は使用していない。

直接実行する場合は `#!/bin/sh` が利用される。

```bash
./examples/bash-posix-sh/02-posix-sh-compatible.sh
```

この比較から、Shell Script を読むときは「Shell Script だからすべて同じ構文が使える」と考えず、どの interpreter を前提にしているかを確認する。

この学習では Bash を主軸とするため、Bash 固有機能を無理に避けることはしない。  
Bash Script であることを shebang などで明示し、利用する Shell と構文を一致させることを重視する。

## 実行・確認ポイント

### Script・variable・argument

- `#!/usr/bin/env bash` が Bash Script の shebang として利用されている。
- `exit` を実行すると、それ以降の Script 処理は実行されない。
- Shell variable は `name=value` で代入し、`$name` / `${name}` で参照できる。
- `readonly` で再代入させない variable を宣言できる。
- `export` した variable は child process の environment へ渡される。
- `$0`、`$1` など、`$#`、`"$@"` が positional parameter と関係している。
- `"$*"` と `"$@"` では arguments の保持方法が異なる。
- `shift` で先頭 positional parameter を取り除ける。
- `$?` は直前の command の exit status である。

### Parameter / Shell expansion

- `$var` と `${var}` で variable を参照できる。
- `${var}` は variable 名の境界を明確にできる。
- `${var:-default}` は unset / empty の場合に default value を利用する。
- `${var:?message}` は必須値がない場合に error として扱える。
- `$()` は command の stdout を値として取り込む。
- `$(( ))` は integer arithmetic を評価する。
- glob は Shell が matching path へ展開する。
- brace expansion は複数の word を生成する。

### Quote

- unquoted variable expansion は word splitting / pathname expansion の影響を受ける場合がある。
- single quote 内では variable expansion が行われない。
- double quote 内では variable expansion を行いながら、展開結果の argument 境界を保持できる。
- `"$variable"` を基本とするのは、意図しない splitting / glob を避けるためである。
- quote の有無は表示文字列だけでなく、command が受け取る argument 数にも影響する。

### Condition

- `if / elif / else` で条件分岐できる。
- `[ ]` と `[[ ]]` は同じものではない。
- `[[ ]]` は Bash 固有の conditional expression である。
- string / numeric / file test には目的に応じた operator がある。
- `case` は一つの値を複数 pattern へ分岐するときに利用できる。
- Bash の `[[ ]]` では `=~` による regex match も利用できる。

### Loop

- `for` で argument / list を順番に処理できる。
- `while` は condition が成功している間繰り返す。
- `while IFS= read -r` は text を 1 行ずつ読む基本形として利用される。
- `until` は condition が失敗している間繰り返す。

### Function

- function 内では function 自身に渡された positional parameter を `$1` などで参照できる。
- `local` で function 内の variable を宣言できる。
- `return` は function の status を返して caller へ戻る。
- `exit` は Script / Shell process 全体を終了する。
- function の stdout を command substitution で値として取得できる。

### Output / Option parsing

- `echo` は簡単な出力に利用できる。
- `printf` は format と argument が明確で、予測可能な出力を書きやすい。
- `getopts` で short option を解析できる。
- `$OPTARG` から option argument、`$OPTIND` から解析位置を扱える。
- `shift $((OPTIND - 1))` で解析済み option を positional parameter から除外できる。

### Bash / POSIX `sh`

- Bash Script と POSIX `sh` 向け Script では利用できる構文が異なる。
- `[[ ]]`、array、`local` などは Bash を前提に利用する機能である。
- `/bin/sh` が Bash であるとは限らない。
- この学習では Bash を主軸とし、Bash を利用することを明示して Bash 機能を利用する。

## 学習ポイント

### Shell Script を読むときは「構文」だけでなく expansion の結果まで追う

Bash Script は、source code に書かれた文字列がそのまま command の argument になるとは限らない。  
variable expansion、command substitution、word splitting、pathname expansion などを経て、最終的に command へ arguments が渡される。

たとえば以下は見た目上 1 行である。

```bash
command $value
```

しかし `value='alpha beta'` で unquoted なら、実際には複数 arguments へ分かれる可能性がある。

```text
source code:
command $value

variable expansion:
command alpha beta

word splitting:
argument 1 = alpha
argument 2 = beta
```

Shell Script を正しく読むには、「この行に何が書いてあるか」だけでなく、「Shell の展開後に command が何を受け取るか」まで考えることが重要である。

### `"$variable"` は単なる style ではなく argument 境界を守るための基本

今回、quote なし / ありで同じ variable を渡し、受け取る argument 数そのものが変わることを確認した。

```bash
show_arguments $value
show_arguments "$value"
```

これは見た目を整えるための coding style の違いではない。  
unquoted expansion では word splitting や pathname expansion が起こり得るため、data の内容によって Script の意味が変化する可能性がある。

そのため、variable を一つの値・一つの path・一つの argument として扱いたい場合は、

```bash
"$variable"
```

を基本とする。

一方、glob を意図的に展開したい場合など、quote しないこと自体に意味がある場面も存在する。  
「常に quote するという暗記」ではなく、「Shell に splitting / glob をさせたいのか」を判断できることが重要である。

### Single quote と double quote は「文字列の種類」ではなく expansion の制御

Java などでは single quote と double quote が異なる data type と結び付く場合があるが、Shell ではその理解を持ち込まない方がよい。

```text
'...'
→ 内容をほぼ literal として扱う
→ variable expansion しない

"..."
→ variable / command substitution などは行う
→ word splitting / pathname expansion を抑える
```

Bash の quote は、「Shell がその文字列をどこまで解釈・展開するか」を制御するものとして捉える。

### Positional parameter と `"$@"` は Script を CLI として扱う基本

Shell Script は、固定処理だけでなく command-line argument を受け取る小さな CLI として利用されることが多い。

```text
Script
↓
$1 / $2 / ...
↓
"$@"
↓
getopts
```

`"$@"` によって caller が渡した argument 境界を保持できることは特に重要である。  
file path や user input に空白が含まれていても、各 argument を個別に処理しやすくなる。

`getopts` もこの positional parameter の延長上にあり、option を解析した後に `shift` して残りの argument を処理する。

### Parameter expansion は小さな設定処理を Shell 自体で表現できる

`${var:-default}` と `${var:?message}` は、単なる variable 参照より一歩進んだ parameter expansion である。

```text
default が必要
→ ${var:-default}

必須値として検証したい
→ ${var:?message}
```

たとえば environment variable から設定を受け取る Script では、複雑な `if` を何行も書かず、parameter expansion 自体に意図を表現できる場合がある。

ただし、一行で多くの意味を持たせられるため、読み手が理解しにくくなるほど複雑な expansion を詰め込まないことも重要である。

### `if` は最終的に success / failure を評価している

Bash の条件式は Java の `boolean` と同じ感覚だけで捉えるより、Unit 01 の exit status と接続すると理解しやすい。

```text
condition / command を実行
↓
exit status 0
→ true として then

non-zero
→ false として else
```

function の `return 0 / 1` を `if` から利用できるのも、同じ仕組みにつながる。

```bash
if is_even 8; then
  ...
fi
```

つまり command、test、function、pipeline などの success / failure が、Shell の control flow を組み立てる共通の土台になっている。

### `[ ]` と `[[ ]]` は見た目が似ていても同一ではない

`[ "$value" = ... ]` と `[[ $value == ... ]]` は似た目的で利用できるが、同じ構文の別表記ではない。

`[ ]` は traditional な test command として POSIX `sh` でも利用される。  
`[[ ]]` は Bash の conditional expression であり、Bash 固有の parsing rules や pattern / regex 機能を利用できる。

本学習では Bash を主軸とするため、Bash Script 内では `[[ ]]` が読みやすく扱いやすい場面で利用してよい。  
一方、既存の `[ ]` を読めることや、POSIX `sh` では `[[ ]]` を前提にできないことも理解しておく。

### `while IFS= read -r` は複数の Shell の仕組みを組み合わせた定型形

以下は一見すると記号が多く、初見では意味を取りにくい。

```bash
while IFS= read -r line; do
  ...
done < "$input_file"
```

しかし分解すると、これまで学んだ内容の組み合わせである。

```text
< "$input_file"
→ file を loop の stdin へ接続

read
→ stdin から 1 行読む

IFS=
→ whitespace を余計に削らない

-r
→ backslash をそのまま読む

while
→ read が成功している間繰り返す
```

複雑に見える Shell Script でも、このように小さな仕組みに分解すると読みやすくなる。

### Function の「結果」は status と stdout を分けて考える

Shell function では、一般的な programming language の `return` と同じ感覚で data を返すわけではない。

```text
return
→ function の success / failure を表す status

stdout
→ command substitution などで data として受け取れる
```

たとえば validation function は status を返す設計が自然である。

```bash
if is_valid "$value"; then
  ...
fi
```

一方、文字列を生成する function では stdout を利用できる。

```bash
result=$(build_value)
```

この区別を持つと、function 内で stdout / stderr のどちらに何を出すべきかも考えやすくなる。

### `exit` と `return` の違いは処理範囲の違い

`return` は現在の function から caller へ戻るが、`exit` は Shell process 全体を終了する。  
function の中だから `exit` も function だけを終わらせる、と考えないことが重要である。

共通 function から不用意に `exit` すると、その function を利用している Script 全体を終了させる可能性がある。  
処理の責任範囲を意識して `return` / `exit` を使い分ける。

### `printf` を基本にする理由は出力を明示的に扱いやすいため

`echo` は簡単でよく使われる一方、出力内容によっては option や escape sequence と解釈される可能性を意識する必要がある。

`printf` では、

```bash
printf '%s\n' "$value"
```

のように format string と data を分けられる。  
「この値を文字列として 1 行出す」という意図が明確で、variable の値が `-n` のような文字列でも format argument として扱える。

このため、学習用 Script でも実務 Script でも、予測可能な出力を重視する場合は `printf` が使いやすい。

### Bash と POSIX `sh` は「どちらが優れているか」ではなく前提を一致させる

Bash には `[[ ]]`、array、`local` など便利な機能があり、本学習では Bash を主軸として利用する。  
一方、POSIX `sh` を要求する環境では Bash 固有機能を前提にできない。

重要なのは、Bash の機能を使うこと自体を避けることではなく、Script の interpreter と利用する構文を一致させることである。

```text
Bash 機能を使う
→ Bash Script として明示

POSIX sh compatibility が必要
→ POSIX sh の範囲で記述
```

「Shell Script」という名前だけで interpreter を決めつけず、shebang や実行方法から前提となる Shell を確認する。

### Unit 03 は今後の Script を読むための共通語彙になる

後続 Unit では、安全性、text / log 処理、API、batch、DB / Docker、CI/CD など、より実用的な Script を扱う。  
その中では、この Unit の構文を毎回一から説明せず組み合わせて利用していく。

```text
argument / getopts
→ Script への入力

parameter expansion
→ default / required setting

quote
→ argument / path を安全に扱う

if / case
→ 分岐

for / while
→ 繰り返し

function
→ 処理単位の整理

command substitution
→ command の結果を値として利用

exit status / return
→ success / failure の伝達
```

Unit 03 の到達点は、これらを暗記して何も見ずに書けることではない。  
実際の Bash Script を読んだときに「これは argument」「ここで expansion される」「quote に意味がある」「この function は status を返している」と処理の意味を追い、必要な細部を調べながら理解できる土台を作ることである。
