# 05. ファイル・テキスト・ログ処理の頻出パターン

## この Unit の目的

Shell Script で頻繁に行われるファイル・テキスト・ログ処理について、多数の小さな実用パターンを通して理解する。  
この Unit では、Script の入口、file / directory 操作、text processing、file search、log processing、単純な CSV、Shell Script の適用判断を扱う。  
個々の Linux command を単独で暗記するのではなく、「何をしたいか」に対して複数の command をどのようにつなぎ、どの段階で data を絞り込み・変換・集計するかを読むことを重視する。

Unit 01～04 で扱った process、stdin / stdout / stderr、pipe、redirect、path、permission、quote、condition、loop、function、validation、cleanup、安全な file 操作などを前提として利用する。  
特に `grep`、`sed`、`awk`、`sort`、`uniq` などは単体の機能一覧として覚えるのではなく、pipeline の中でそれぞれがどの役割を担っているかを確認する。

また、Shell で実装できることと、Shell で実装するのが適切なことは同じではない。  
quoted comma や multiline field を含む複雑な CSV など、専用 parser を使うべき data processing へ無理に Bash を適用しない判断もこの Unit の学習対象とする。

## 学習内容

### Script の入口

実用的な Script では、本処理より前に前提条件を確認することが多い。  
Unit 04 で扱った validation を、この Unit では file / text processing Script の入口として利用する。

#### Argument validation

required argument を受け取る Script では、`$1` をそのまま使い始めるのではなく、存在と期待する種類を先に確認する。

```bash
input_file=${1:-}

if [[ -z $input_file ]]; then
  ...
fi

if [[ ! -f $input_file ]]; then
  ...
fi
```

これにより、後続の `grep` や `awk` が意味の分かりにくい error を返す前に、「input file がない」という本来の問題を入口で示せる。

#### Dependency check

text processing Script は複数の external command を組み合わせることが多い。

```bash
command -v grep
command -v awk
command -v sort
```

必要な command が利用できるかを処理開始前に確認すると、途中で `command not found` になるより原因を分かりやすくできる。

#### Environment check

environment variable から mode や path などを受け取る場合は、存在だけでなく許容値も確認する。

```bash
case "$UNIT05_MODE" in
  development|production)
    ...
    ;;
  *)
    ...
    ;;
esac
```

Unit 04 で学んだ validation を、実際の processing Script の入口へつなげる。

#### Configuration loading

Bash では `source` または `.` によって別 file を現在の Shell に読み込める。

```bash
source "$config_file"
```

ただし source される file は単なる key-value data として読むのではなく、Shell code として実行される。  
そのため、外部から任意に渡された untrusted file を configuration として安易に `source` しない。

この Unit では、自分で作成した trusted configuration file を読み込む基本だけを扱う。

#### Working directory の確定

relative path を多用する Script では、どの directory を基準に path を解釈するかが重要になる。

```bash
script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)
```

このように Script 自身の位置を基準に directory を求める方法もある。  
current working directory と Script directory は同じとは限らない。

### File / directory 処理

#### File / directory existence

file と directory は期待する種類を分けて確認する。

```bash
[[ -f $file_path ]]
[[ -d $directory_path ]]
```

単に `-e` で何かが存在することだけを見るより、本処理が何を期待しているかを明確にできる。

#### Directory creation

`mkdir -p` は parent directory も含めて作成でき、既存 directory がある場合でも通常 error にしない。

```bash
mkdir -p -- "$target_dir"
```

再実行される Script でも扱いやすい command の一つである。

#### File loop

特定 extension の file を順番に処理する場合、glob を利用できる。

```bash
for file_path in "$work_dir"/*.txt; do
  ...
done
```

固定した directory 部分を quote し、glob 部分は展開させる点に注意する。

#### Copy / move

`cp` は元 file を残したまま copy し、`mv` は path を移動する。

```bash
cp -- "$source" "$destination"
mv -- "$source" "$destination"
```

どちらも file path を扱うため、quote と `--` を基本にする。

#### Backup

backup を作る場合、単なる copy に加えて「どの世代の backup か」を区別する必要がある。

```bash
timestamp=$(date '+%Y%m%d-%H%M%S')
backup_file="$backup_dir/settings.conf.$timestamp.bak"
```

timestamp を file name へ含める方法は基本例の一つである。  
実運用では retention、timezone、同一秒での衝突、容量、復元方法なども考える。

#### Archive

複数 file / directory をまとめる基本として `tar` を利用する。

```bash
tar -czf "$archive_file" -C "$work_dir" data
```

`-C` を利用すると、archive 内へ不要な parent path を持ち込まずに対象 directory をまとめやすい。

archive 内容は以下のように確認できる。

```bash
tar -tzf "$archive_file"
```

#### Cleanup

一定条件に合う古い file を削除する処理では、`find` の timestamp predicate を利用できる。

```bash
find "$work_dir" \
  -type f \
  -name '*.log' \
  -mtime +7 \
  -print \
  -delete
```

destructive operation では、検索条件と対象 directory を十分に確認してから `-delete` などを利用する。

`-mtime +7` などの時間条件は、単純な「現在時刻から 7 × 24 時間を引く」と完全に同じ意味とは限らないため、実際に利用するときは `find` の仕様を確認する。

#### Temporary file / directory

複数の intermediate file が必要な場合、一つの temporary directory を workspace として利用できる。

```bash
temp_dir=$(mktemp -d)
```

cleanup は `trap` へまとめる。

```bash
trap cleanup EXIT
```

Unit 04 で扱った cleanup を、text processing の intermediate data へ応用する。

#### File timestamp を利用した処理

最新 file を選ぶ処理では、timestamp を数値として出して並べ替える方法がある。

```bash
find ... -printf '%T@ %p\n' |
  sort -nr |
  head -n 1
```

ここでは、

```text
find
→ candidate と timestamp を出す

sort
→ timestamp 順に並べる

head
→ 先頭 1 件を選ぶ

cut
→ timestamp 部分を外して path を取り出す
```

という pipeline 全体の役割を追う。

### Text processing

この Unit では以下の command を扱う。

- `grep`
- `sed`
- `awk`
- `cut`
- `sort`
- `uniq`
- `tr`
- `wc`
- `head`
- `tail`

重要なのは、それぞれをすべて単独で暗記することではない。  
目的に対して、どの command がどの stage を担当しているかを理解する。

#### `grep`

`grep` は行を pattern で絞り込む用途で頻繁に使われる。

```bash
grep '^ERROR ' "$input_file"
```

pipeline の前段で対象 data を減らし、その後の processing を必要な行だけに限定できる。

#### `sed`

`sed` は stream editor として、文字列の置換や行単位の変換に利用できる。

```bash
sed 's/^ERROR //'
```

この Unit では、prefix の除去や whitespace の normalization など、小さな text transformation として扱う。

#### `awk`

`awk` は field-based な text processing、condition、集計などを一つの program として書ける。

```bash
awk -F ',' '$2 == "engineering" { total += $3 } END { print total }'
```

単純な field extraction だけなら `cut` で足りることもあるが、条件と計算を組み合わせる場合は `awk` が適することがある。

#### `cut`

単純な delimiter-separated data から特定 field を取り出す用途に利用できる。

```bash
cut -d ',' -f 2
```

ただし、quoted comma を理解する CSV parser ではない。  
delimiter が単純に field separator として扱える data に向いている。

#### `sort`

行を並べ替える。

```bash
sort
sort -n
sort -nr
```

`uniq` と組み合わせる場合は、同じ値を隣接させるために先に `sort` することが多い。

#### `uniq`

連続する重複行をまとめる。

```bash
sort "$input_file" | uniq
```

件数も付ける場合は `-c` を利用する。

```bash
sort "$input_file" | uniq -c
```

全体の grouping で `sort | uniq -c` が頻出する理由は、`uniq` が離れた位置の同一行を直接 grouping する command ではないためである。

#### `tr`

character 単位の変換や連続文字の圧縮などに利用できる。

```bash
tr '[:upper:]' '[:lower:]'
```

```bash
tr -s '[:blank:]' ' '
```

大文字小文字変換、whitespace normalization などの単純な character transformation に向いている。

#### `wc`

行数・word 数・byte 数などを数える。

```bash
wc -l
```

pipeline の結果件数や log の総行数を集計するときに利用できる。

#### `head` / `tail`

file や pipeline の先頭 / 末尾の一部を取得する。

```bash
head -n 3
tail -n 3
```

大きな log の一部確認や、sort 後の上位 / 下位の取得などにも利用できる。

#### 複数 command の組み合わせ

たとえば log から ERROR 行の service を件数順に集計する場合、

```bash
grep ' ERROR ' "$input_file" |
  awk '{ print $3 }' |
  sort |
  uniq -c |
  sort -nr
```

と書ける。

処理を stage ごとに分解すると、

```text
grep
→ ERROR 行だけへ絞る

awk
→ service field だけへ変換

sort
→ 同じ service を隣接させる

uniq -c
→ service ごとに件数を付ける

sort -nr
→ 件数の多い順へ並べる
```

となる。

このように「command 名」より data flow を読む。

### File search と `find`

#### Basic `find`

directory tree から条件に一致する path を探索する。

```bash
find "$work_dir" -type f -name '*.txt' -print
```

`-type f` で regular file、`-name` で filename pattern を指定する。

#### `-exec`

find result を別 command へ渡す。

```bash
find ... -exec wc -l -- {} +
```

`{}` が find result の path に置き換わる。

末尾の `+` では、可能な範囲で複数 path をまとめて command arguments として渡す。  
1 件ごとに command を起動する `\;` とは実行方法が異なる。

#### `xargs`

stdin から受け取った data を command arguments として組み立てる。

```bash
find ... -print0 |
  xargs -0 ...
```

file path を扱う場合は delimiter の安全性が重要になる。

#### 空白を含む filename

次のような書き方は危険である。

```bash
for path in $(find ...); do
  ...
done
```

command substitution の output が whitespace で分割されるため、

```text
report 2026.txt
```

のような file が複数の word に壊れる可能性がある。

#### Null delimiter

Linux filename は newline を含むこともできるため、単純な line delimiter では完全に安全な path transport にならない場合がある。

`find` では NUL delimiter を出せる。

```bash
find ... -print0
```

`xargs` では対応する `-0` を利用する。

```bash
find ... -print0 |
  xargs -0 ...
```

Bash で 1 件ずつ読む場合は、以下のような形を利用できる。

```bash
while IFS= read -r -d '' file_path; do
  ...
done < <(find ... -print0)
```

ここでは、

```text
find -print0
→ path を NUL-delimited で出す

read -d ''
→ NUL までを 1 record として読む
```

という対応関係を確認する。

### Log processing

#### ERROR 行などの抽出

log level が一定 format で記録されているなら `grep` で絞れる。

```bash
grep ' ERROR ' "$log_file"
```

#### 件数集計

対象行数を数える。

```bash
grep -c ' ERROR ' "$log_file"
```

または pipeline と `wc -l` を組み合わせる方法もある。

#### Grouping

service や error type など特定 field ごとに集計する。

```bash
awk '{ print $2 }' |
  sort |
  uniq -c |
  sort -nr
```

#### 日付による絞り込み

行頭の日付 format が一定なら、

```bash
grep "^${target_date} " "$log_file"
```

のような単純な方法でも絞れる。

ただし real-world log では timezone、multiline message、JSON log、複数 format などもあり得る。  
この Unit では固定 format の simple log を対象にする。

#### Log file の解析

単なる一行抽出だけでなく、

```text
total line count
error count
error grouping
```

など複数の指標を組み合わせて report を作る。

Shell はこのような「text stream を少しずつ絞って集計する」処理と相性がよい。

#### Script 自身の logging

Script 自身も、一定 format で log を出しておくと後から解析しやすい。

```text
timestamp level message
```

たとえば、

```bash
printf '%s %-5s %s\n' \
  "$(date '+%Y-%m-%dT%H:%M:%S%z')" \
  "$level" \
  "$message"
```

のように format を固定する。

`tee -a` を利用すれば、Terminal へ表示しながら log file へ追記できる。

```bash
... | tee -a "$log_file"
```

### CSV

#### 単純な CSV

field 内に comma、newline、quote が存在しない単純な data であれば、`IFS=','` と `read` で小さく処理できる。

```bash
while IFS=',' read -r name score active; do
  ...
done
```

CSV row を field ごとの variable に分け、その値を別 function へ渡すこともできる。

```bash
process_record "$name" "$department" "$points"
```

#### 複雑な CSV の危険性

一般的な CSV では field 自体に comma を含めることができる。

```text
"Doe, John",90
```

単純な、

```bash
IFS=',' read -r field1 field2 field3
```

は CSV quote rule を理解しないため、

```text
field1 = "Doe
field2 =  John"
field3 = 90
```

のように誤って分割する。

multiline field もあり得る。

```text
1,"first line
second line"
```

通常の `read` は physical line 単位で読むため、quoted newline を含む一つの logical CSV record を正しく判断できない。

さらに CSV には escaped quote などもある。  
そのため real-world CSV を正しく扱う必要がある場合、Bash で parser を自作するのではなく、Python の `csv` module など仕様を扱える parser を利用する方が適切である。

### Shell Script の適用判断

Shell は以下のような処理に向いている。

- external command を順番に呼び出す
- file / directory を操作する
- stdout / stdin を pipeline でつなぐ
- simple text data を filter / transform する
- log を抽出・集計する
- OS command を glue code として組み合わせる
- batch / automation の小さな orchestration を行う

一方、以下のような処理は別言語を検討する。

- complex CSV
- deeply nested data structure
- complicated business logic
- large-scale data transformation
- complex error recovery
- extensive state management
- strong typing や大規模 testability が重要な処理

「Bash で書ける」ことだけを理由に Bash を選ばない。  
Shell の強みは external command / text stream / filesystem operation の組み合わせにある。

### Python 等へ任せる判断

たとえば以下の単純 CSV なら Bash でも理解しやすい。

```text
alice,engineering,120
bob,sales,95
```

一方、

```text
"Doe, John","line1
line2",90
```

のようになった時点で、CSV specification を正しく扱う parser の方が適している。

Shell では、

```text
Shell
→ file discovery
→ Python program を起動
→ result を次の command へ渡す
```

のように、Shell 自身がすべての data processing を担当せず、適切な tool / language を orchestrate する役割を持たせることもできる。

## 使用するもの

この Unit では、主に以下を利用する。

- WSL 2 上の Linux
- Bash
- `grep`
- `sed`
- `awk`
- `cut`
- `sort`
- `uniq`
- `tr`
- `wc`
- `head`
- `tail`
- `find`
- `xargs`
- `cp`
- `mv`
- `tar`
- `date`
- `touch`
- `mkdir`
- `mktemp`
- `tee`
- `basename`
- `dirname`
- `seq`

追加 library は使用しない。  
CSV の複雑な case については「Bash で正しく parse しない」こと自体を学習し、Python parser の実装まではこの Unit では行わない。

## 事前準備

Unit 01～04 が完了し、以下の基本を確認済みであることを前提とする。

- stdin / stdout / stderr
- redirect / pipe / `pipefail`
- file / directory / path
- permission
- variable / expansion / quote
- condition / loop / function
- argument / option
- validation
- temporary file / cleanup
- safe file operation

利用する主要 command を確認する。

```bash
for command_name in \
  grep sed awk cut sort uniq tr wc head tail \
  find xargs cp mv tar date touch tee
do
  command -v "$command_name"
done
```

リポジトリ root から Unit 05 へ移動する。

```bash
cd units/05-file-text-log-processing
```

成果物を確認する。

```bash
find . -maxdepth 3 -type f | sort
```

以下の構成になっていることを確認する。

```text
05-file-text-log-processing/
├─ README.md
└─ examples/
   ├─ csv/
   │  ├─ 01-simple-csv-read.sh
   │  ├─ 02-csv-pass-to-function.sh
   │  ├─ 03-complex-csv-limit.sh
   │  └─ 04-multiline-csv-limit.sh
   ├─ file-directory/
   │  ├─ 01-existence-and-create.sh
   │  ├─ 02-file-loop.sh
   │  ├─ 03-copy-and-move.sh
   │  ├─ 04-backup.sh
   │  ├─ 05-archive.sh
   │  ├─ 06-cleanup-by-timestamp.sh
   │  ├─ 07-temporary-workspace.sh
   │  └─ 08-newest-file.sh
   ├─ file-search/
   │  ├─ 01-find-basic.sh
   │  ├─ 02-find-exec.sh
   │  ├─ 03-find-xargs-null.sh
   │  ├─ 04-find-while-read-null.sh
   │  └─ 05-unsafe-vs-safe-filename.sh
   ├─ log-processing/
   │  ├─ 01-error-extraction.sh
   │  ├─ 02-error-count.sh
   │  ├─ 03-grouping.sh
   │  ├─ 04-filter-by-date.sh
   │  ├─ 05-log-analysis-report.sh
   │  └─ 06-script-logging.sh
   ├─ script-entry/
   │  ├─ 01-argument-validation.sh
   │  ├─ 02-dependency-check.sh
   │  ├─ 03-environment-check.sh
   │  ├─ 04-configuration-loading.sh
   │  └─ 05-working-directory.sh
   └─ text-processing/
      ├─ 01-filter-transform.sh
      ├─ 02-field-extraction.sh
      ├─ 03-sort-uniq-count.sh
      ├─ 04-head-tail.sh
      ├─ 05-multi-command-report.sh
      └─ 06-normalize-whitespace.sh
```

すべてのサンプルは学習用の temporary file / directory を基本としている。  
file deletion、timestamp cleanup、archive などを変更して試す場合も、実際の user data や repository 内の必要 file を対象にせず、用意した temporary directory の範囲で確認する。

## 学習・実践

### 1. Script の入口を整える

まず required argument の validation を確認する。

学習用 input file を一つ作る。

```bash
input_file=$(mktemp)
printf '%s\n' 'sample' > "$input_file"
```

正常系を実行する。

```bash
bash examples/script-entry/01-argument-validation.sh "$input_file"
```

`validated input=...` が表示される。

argument なしの場合も確認する。

```bash
bash examples/script-entry/01-argument-validation.sh
```

usage が stderr に表示され、non-zero で終了する。

存在しない path も試す。

```bash
bash examples/script-entry/01-argument-validation.sh /tmp/unit05-not-found
```

`input file not found` として入口で拒否される。

学習用 file を削除する。

```bash
rm -f -- "$input_file"
```

dependency check を実行する。

```bash
bash examples/script-entry/02-dependency-check.sh
```

この Script では `grep`、`awk`、`sort` が利用可能かを `command -v` で確認する。

environment check を確認する。

```bash
UNIT05_MODE=development bash examples/script-entry/03-environment-check.sh
```

```bash
UNIT05_MODE=production bash examples/script-entry/03-environment-check.sh
```

許容していない値も確認する。

```bash
UNIT05_MODE=unknown bash examples/script-entry/03-environment-check.sh
```

environment variable の存在だけでなく、想定した候補に含まれるかも確認している。

configuration loading を実行する。

```bash
bash examples/script-entry/04-configuration-loading.sh
```

temporary configuration file が source され、`APP_NAME` / `LOG_LEVEL` が現在の Shell context に読み込まれる。

ここでは `source` が「config parser」ではなく Shell code の実行であることを意識する。  
untrusted file を source する方法として覚えない。

working directory と Script directory を確認する。

```bash
bash examples/script-entry/05-working-directory.sh
```

別 directory から同じ Script を実行して比較してもよい。

```bash
(
  cd /tmp
  bash "$OLDPWD/examples/script-entry/05-working-directory.sh"
)
```

current working directory と Script 自身の directory が別の概念であることを確認する。

### 2. File / directory の作成・copy・backup・archive・cleanup を確認する

file / directory existence と creation を確認する。

```bash
bash examples/file-directory/01-existence-and-create.sh
```

`mkdir -p` で output directory を作成し、その中へ result file を作る。  
`-d` / `-f` をそれぞれ directory / regular file の確認に利用している。

file loop を確認する。

```bash
bash examples/file-directory/02-file-loop.sh
```

temporary directory に `.txt` と `.log` を作り、`*.txt` だけを loop で処理する。

```bash
for file_path in "$work_dir"/*.txt; do
```

固定 directory 部分が quote され、glob 部分は展開されている点に注目する。

copy / move を比較する。

```bash
bash examples/file-directory/03-copy-and-move.sh
```

`cp` 後は source が残り、`mv` 後は元 path から file がなくなることを確認する。

backup を確認する。

```bash
bash examples/file-directory/04-backup.sh
```

timestamp 付き backup file が作成される。  
file name に時間を含めるだけでも複数世代を区別できるが、real operation では retention policy などが別途必要になる。

archive を確認する。

```bash
bash examples/file-directory/05-archive.sh
```

`tar -czf` で archive を作成し、`tar -tzf` で内容を確認する。

timestamp を利用した cleanup を確認する。

```bash
bash examples/file-directory/06-cleanup-by-timestamp.sh
```

学習用に recent / old の 2 file を作り、old file だけ `find ... -mtime +7 -delete` の対象にする。

実行結果で、

```text
recent remains=yes
old remains=no
```

となることを確認する。

`find -delete` は destructive operation なので、実際の Script で利用するときはまず `-print` だけで対象を確認してから delete 条件を追加する考え方が重要である。

temporary workspace を確認する。

```bash
bash examples/file-directory/07-temporary-workspace.sh
```

一つの temporary directory に input / output をまとめ、`trap cleanup EXIT` でまとめて削除する。

最後に timestamp から最新 file を選ぶ。

```bash
bash examples/file-directory/08-newest-file.sh
```

pipeline は以下のように読む。

```text
find
↓
mtime + path

sort -nr
↓
新しい順

head -n 1
↓
最新 1 件

cut
↓
path だけ
```

`newest=new.txt` が表示されることを確認する。

### 3. Text processing command を組み合わせる

まず filter → transform の流れを確認する。

```bash
bash examples/text-processing/01-filter-transform.sh
```

pipeline は、

```text
grep
→ ERROR 行だけ抽出

sed
→ ERROR prefix を除去

tr
→ lowercase 化
```

という役割になっている。

field extraction と aggregation を確認する。

```bash
bash examples/text-processing/02-field-extraction.sh
```

前半では `cut` で department field を取り出し、`sort -u` で unique な department を出す。

後半では `awk` で、

```text
department == engineering
```

の record だけを対象に points を合計する。

同じ delimiter-separated data でも、単純な field extraction と condition + aggregation で tool を使い分けている。

`sort` / `uniq` / `wc` を確認する。

```bash
bash examples/text-processing/03-sort-uniq-count.sh
```

`uniq -c` の前に `sort` がある理由に注目する。

```text
sort
→ 同じ level を隣接

uniq -c
→ 件数を付ける

sort -nr
→ 件数順
```

総行数は `wc -l` で確認する。

`head` / `tail` を確認する。

```bash
bash examples/text-processing/04-head-tail.sh
```

10 行の file から先頭 3 行と末尾 3 行だけを取得する。

複数 command を使った小さな report を確認する。

```bash
bash examples/text-processing/05-multi-command-report.sh
```

ERROR log だけを対象に service 別件数を集計する。

最後に whitespace normalization を確認する。

```bash
bash examples/text-processing/06-normalize-whitespace.sh
```

`sed` で行頭・行末 whitespace を除去し、`tr -s` で連続 horizontal whitespace を一つへまとめる。

重要なのは command 名を個別に覚えることより、

```text
入力
↓
filter
↓
field extraction
↓
normalization
↓
grouping
↓
count / sort
```

のような processing pipeline を組み立てて読むことである。

### 4. `find`・`-exec`・`xargs`・NUL delimiter を確認する

basic `find` を実行する。

```bash
bash examples/file-search/01-find-basic.sh
```

subdirectory を含めて `.txt` regular file が探索される。

`-exec` を確認する。

```bash
bash examples/file-search/02-find-exec.sh
```

find result が `wc -l` の arguments として渡される。

```bash
-exec wc -l -- {} +
```

`{}` が result path に置き換わることを確認する。

次に NUL delimiter と `xargs` を確認する。

```bash
bash examples/file-search/03-find-xargs-null.sh
```

`report 2026.txt` のような空白を含む filename が、1 path のまま `printf` へ渡る。

```text
find -print0
↓
NUL-delimited path

xargs -0
↓
NUL で arguments を再構成
```

Bash loop で処理する方法も確認する。

```bash
bash examples/file-search/04-find-while-read-null.sh
```

`read -d ''` によって NUL-delimited data を 1 path ずつ受け取る。

最後に unsafe / safe を比較する。

```bash
bash examples/file-search/05-unsafe-vs-safe-filename.sh
```

unsafe な、

```bash
for path in $(find ...); do
```

では `report 2026.txt` が whitespace で分割され、2 files しかないのに loop count が増える。

結果として、

```text
unsafe loop count=3
safe loop count=2
```

となる。

file path は任意の text として扱う必要があるため、`find` output を単純な whitespace splitting に流さない理由を、この差から理解する。

### 5. Log を抽出・集計・grouping する

ERROR 行の抽出から確認する。

```bash
bash examples/log-processing/01-error-extraction.sh
```

`grep ' ERROR '` で ERROR level の行だけを抽出する。

件数を確認する。

```bash
bash examples/log-processing/02-error-count.sh
```

`grep -c` によって ERROR line count を取得する。

grouping を確認する。

```bash
bash examples/log-processing/03-grouping.sh
```

ERROR log の service field を `awk` で抽出し、`sort | uniq -c | sort -nr` で件数順に並べる。

日付による絞り込みを確認する。

```bash
bash examples/log-processing/04-filter-by-date.sh
```

固定 format の log なので、行頭 `2026-09-24` を `grep` して対象日だけ取り出す。

複数の集計をまとめた report を確認する。

```bash
bash examples/log-processing/05-log-analysis-report.sh
```

以下を一つの Script で行う。

```text
total line count
ERROR count
ERROR by service
```

最後に Script 自身の logging を確認する。

```bash
bash examples/log-processing/06-script-logging.sh
```

`log` function が、

```text
timestamp level message
```

の一定 format で stdout へ出し、`tee -a` で同時に log file へ保存する。

logging は「表示する」だけでなく、後で machine processing しやすい一定 format を設計することも重要になる。

### 6. 単純な CSV を扱い、Bash の限界を確認する

まず単純 CSV を読む。

```bash
bash examples/csv/01-simple-csv-read.sh
```

header を 1 行読み飛ばし、残りを、

```bash
IFS=',' read -r name score active
```

で 3 fields に分ける。

この方法が成立する前提は、

```text
field 内に comma がない
field 内に newline がない
CSV quote rule を必要としない
```

という非常に単純な data である。

CSV row の data を別 function へ渡す例を確認する。

```bash
bash examples/csv/02-csv-pass-to-function.sh
```

`read` で分けた fields を、

```bash
process_record "$name" "$department" "$points"
```

として別処理へ渡している。

次に quoted comma を含む CSV を確認する。

```bash
bash examples/csv/03-complex-csv-limit.sh
```

以下の record がある。

```text
"Doe, John",90
```

単純な `IFS=','` では quote を理解しないため、`Doe, John` 内の comma でも分割される。

これは「少し quote を追加すれば直る」という問題ではなく、CSV grammar を parse する必要があることを示している。

最後に multiline field を確認する。

```bash
bash examples/csv/04-multiline-csv-limit.sh
```

一つの field が複数 physical lines を含んでいる。

```text
1,"first line
second line"
```

単純な `read` loop では physical line ごとに別 record として扱ってしまう。

この 2 サンプルから、

```text
単純 CSV
→ Bash で小さく扱える場合あり

quoted comma / escaped quote / multiline
→ dedicated CSV parser を使う
```

という適用判断を確認する。

### 7. Shell Script を使う範囲を判断する

ここまでのサンプルを、Shell が向いている処理として整理する。

```text
file を探す
→ find

特定行へ絞る
→ grep

field を取り出す
→ cut / awk

文字列を変換
→ sed / tr

並べ替え・grouping
→ sort / uniq

件数を数える
→ wc / uniq -c

複数 command をつなぐ
→ pipeline

file / directory を操作
→ cp / mv / tar / find

処理を自動化
→ Bash Script
```

このように既存 command が処理の主体で、Shell がそれらをつなぐ場合は Bash の強みを生かしやすい。

一方、以下のような方向へ進んだ場合は別言語を検討する。

```text
CSV parser を自作し始める
nested data を大量に管理する
複雑な validation rule が増える
business logic が増える
大きな in-memory data transformation が必要
state management が複雑
```

「Shell でできるか」ではなく、

```text
Shell で書いたときに
安全で
読みやすく
変更しやすく
test しやすいか
```

まで考えて適用範囲を決める。

## 実行・確認ポイント

### Script の入口

- required argument は本処理前に validation する。
- dependency を `command -v` で確認できる。
- environment variable は存在だけでなく許容値も検証できる。
- `source` する configuration file は Shell code として実行されるため trusted file に限定する。
- current working directory と Script directory は別の概念である。

### File / directory

- `-f` / `-d` で期待する file type を確認できる。
- `mkdir -p` は directory creation と再実行性の両方で便利な場合がある。
- glob を file loop に利用できる。
- `cp` / `mv` の違いを確認する。
- timestamp を backup name に利用できる。
- `tar` で archive を作成・一覧確認できる。
- `find` の timestamp predicate で古い file を選べる。
- destructive cleanup は対象確認を優先する。
- `mktemp -d` と `trap` で temporary workspace を管理できる。
- timestamp + `sort` + `head` で最新 file を選択できる。

### Text processing

- `grep` で対象行を filter する。
- `sed` で line-oriented な transformation を行う。
- `awk` で field、condition、aggregation を扱える。
- `cut` は simple delimiter-separated data の field extraction に向く。
- `sort` で grouping 前の並べ替えを行える。
- `uniq -c` で連続した同一行を count できる。
- `tr` で character transformation / squeeze ができる。
- `wc -l` で line count を取得できる。
- `head` / `tail` で先頭・末尾の一部を取得できる。
- command を単体で覚えるより pipeline 内の役割を追う。

### File search

- `find` で directory tree を条件検索できる。
- `-exec ... {} +` で result を別 command へ渡せる。
- `xargs` で stdin から command arguments を組み立てられる。
- file path を whitespace delimiter に任せると空白を含む filename が壊れる。
- `find -print0` / `xargs -0` で NUL delimiter を利用できる。
- Bash では `read -d ''` で NUL-delimited path を読める。
- `for path in $(find ...)` のような pattern は file path 処理では避ける。

### Log processing

- `grep` で ERROR 行を抽出できる。
- `grep -c` / `wc -l` で件数を集計できる。
- `awk | sort | uniq -c` で grouping ができる。
- fixed format なら日付 field で filter できる。
- 複数指標を組み合わせて小さな report を作れる。
- Script 自身の logging も一定 format にすると解析しやすい。
- `tee -a` で表示と file 保存を同時に行える。

### CSV

- simple CSV は `IFS=',' read -r` で扱える場合がある。
- read した fields を function や別 command へ渡せる。
- `IFS=','` は CSV quote rule を理解しない。
- quoted comma を含む CSV は単純 split では壊れる。
- multiline field は line-by-line `read` では logical record を判定できない。
- complex CSV は dedicated parser を持つ別言語へ任せる。

### Shell の適用判断

- filesystem / command orchestration / simple text stream processing は Shell の得意領域である。
- parsing rule や business logic が複雑になった場合は別言語を検討する。
- 「Shell で実装可能」と「Shell が適切」は区別する。
- Shell は別言語や tool を起動・接続する orchestration layer としても利用できる。

## 学習ポイント

### Unit 05 の中心は command の暗記ではなく data flow を読むこと

`grep`、`awk`、`sort`、`uniq` などを一つずつ覚えても、実際の Script を読むときには複数 command が pipeline でつながっている。

たとえば、

```bash
grep ' ERROR ' "$log_file" |
  awk '{ print $3 }' |
  sort |
  uniq -c |
  sort -nr
```

は、command 名の列として読むのではなく、

```text
raw log
↓
ERROR だけ
↓
service name だけ
↓
同じ service を隣接
↓
件数へ変換
↓
件数順
```

という data transformation として読む。

各 stage の stdout が次の stage の stdin になるという Unit 02 の理解が、そのまま text processing の実用パターンにつながっている。

### 小さな command を組み合わせることが Shell の強み

Shell では、一つの巨大 command や複雑な function にすべてを書かず、既存 command の役割を組み合わせられる。

```text
探索
→ find

filter
→ grep

field processing
→ awk / cut

transform
→ sed / tr

group
→ sort / uniq

count
→ wc / uniq -c
```

この構成は、一つ一つの stage を Terminal で単独実行して確認しやすいという利点もある。

pipeline が期待どおり動かない場合は、

```text
最初の command だけ
↓
2 stage まで
↓
3 stage まで
```

と段階的に結果を確認できる。

Unit 04 の debugging の考え方ともつながる。

### `grep`・`cut`・`awk` は重なる機能があっても役割が同じではない

一つの処理を複数の command で実装できることがある。

単純な delimiter-separated data の 2 field 目を取り出すだけなら、

```bash
cut -d ',' -f 2
```

は分かりやすい。

一方、

```text
department が engineering の行だけ
+
points を合計
```

のようになると `awk` の方が処理意図をまとめやすい。

「どちらの command でもできるからどちらでもよい」と考えるより、処理の複雑さと読みやすさに合う tool を選ぶ。

### `sort | uniq -c` は grouping の仕組みを理解して使う

`uniq` は file 全体から同じ行を探して grouping する command ではない。  
隣接する同一行をまとめる。

そのため、

```bash
sort |
uniq -c
```

という組み合わせがよく使われる。

```text
入力:
ERROR
INFO
ERROR

uniq -c のみ:
別位置の ERROR は別 group

sort 後:
ERROR
ERROR
INFO

uniq -c:
2 ERROR
1 INFO
```

frequent pattern でも、なぜその順序なのかを説明できることが重要である。

### File path を text line と同一視しない

Linux filename には空白だけでなく newline も含められる。

そのため、

```bash
for path in $(find ...)
```

のように find output を whitespace splitting へ渡すと、path boundary が壊れる可能性がある。

file path の transport では、

```text
find -print0
+
xargs -0
```

または、

```text
find -print0
+
read -d ''
```

のように NUL delimiter を利用できる。

これは「特殊な filename に過剰対応する」というより、**path と text line は別の data として考える**ことにつながる。

### `find` は search command であると同時に operation の入口にもなる

`find` は path を表示するだけでなく、

```bash
-exec
-delete
```

などを利用して result に対して operation を行える。

便利な一方で、condition を誤ると大量の file を対象にする可能性がある。

特に destructive operation では、

```text
find ... -print
↓
対象を確認

find ... -delete
↓
条件が妥当と確認してから実行
```

のように段階を分ける考え方が重要になる。

Unit 04 の safe destructive operation を、実際の file cleanup へ応用する場面である。

### Timestamp 処理は「時間」という追加の複雑さを持つ

backup name、old file cleanup、newest file selection では timestamp を利用した。

一見単純でも、real operation では、

- timezone
- clock
- timestamp precision
- boundary
- filename collision
- retention period

などを考える可能性がある。

この Unit のサンプルは basic pattern を理解するためのものであり、「timestamp を使えば backup / cleanup policy が完成する」わけではない。

### Log は一定 format にすると Shell で扱いやすくなる

Shell の text processing は、input format が一定であるほど扱いやすい。

```text
timestamp level service message
```

のような規則があれば、

```bash
grep
awk
sort
uniq
```

で小さな analysis を組み立てやすい。

逆に free-form multiline log、JSON、stack trace、複数 format が混在する場合は、単純な field-based processing が壊れやすくなる。

log を出す側でも、後から machine processing することを意識した format を設計する価値がある。

### Script 自身の logging でも stdout / stderr の役割を考える

Script が data を stdout へ返す設計の場合、operational log を同じ stdout に混ぜると caller が扱いにくくなる。

```text
stdout
→ processing result

stderr
→ diagnostics / operational message
```

のように役割を分ける場合もある。

今回の logging sample は `tee` の基本を示すため stdout を利用しているが、実際の CLI / batch では「何を data とし、何を log とするか」を設計する。

Unit 02・03 の stdout / function return-value の考え方がここでもつながる。

### CSV は delimiter-separated text より複雑

`IFS=','` は comma で split するだけであり、CSV parser ではない。

simple data:

```text
alice,90,true
```

なら十分な場合がある。

しかし、

```text
"Doe, John",90
```

では comma が data の一部なのか delimiter なのかを quote rule から判断する必要がある。

さらに、

```text
1,"first line
second line"
```

のような multiline field も存在する。

ここまで来ると、

```text
read line
↓
comma で split
```

という Shell の単純な processing model では不足する。

### 「Bash で parser を作る」より適切な parser を利用する

複雑な CSV を Bash で処理しようとすると、

```text
quoted comma
escaped quote
multiline field
empty field
encoding
```

などの case を自分で再実装することになる。

Python には CSV parser があり、他の言語にも同様の library がある。  
既に仕様を扱う tool が存在するなら、それを利用した方が安全で読みやすい。

Shell Script はその parser を起動する orchestration を担当できる。

```text
Shell
↓
対象 file を find
↓
Python CSV processor
↓
result を archive / upload
```

すべてを一つの言語で書く必要はない。

### Shell の適用範囲は「code size」だけでは決まらない

短い Script でも parsing rule が複雑なら Shell に向かない場合がある。  
逆に少し長くても、existing commands の orchestration が中心なら Shell が自然な場合もある。

判断材料として、

```text
処理の主体は external command か
data structure は単純か
state は少ないか
failure path は理解しやすいか
専用 parser / library が必要か
test / maintenance が複雑になっていないか
```

を見る。

この判断は「Shell を使わない」ためではなく、Shell の得意領域で使うために重要である。

### Unit 05 は後続 Unit の data processing の土台になる

後続 Unit では、この Unit の pattern が別の対象と組み合わさる。

```text
Unit 06 HTTP / API / JSON
→ API response の filter / extraction
→ file 保存
→ command pipeline

Unit 07 batch / cron
→ log
→ backup
→ cleanup
→ timestamp
→ file loop

Unit 10 DB / Docker / Application
→ command output processing
→ CSV / file input
→ log analysis

Unit 11 CI/CD
→ build log
→ artifact
→ command output
→ report
```

今後は `grep` や `find` の syntax だけではなく、

```text
どんな data が入るか
↓
どの command が何を担当するか
↓
どこで failure し得るか
↓
Shell で扱う範囲は適切か
```

という観点で Script を読むことが重要になる。
