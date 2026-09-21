# 02. 標準入出力・パイプ・ファイル・権限

## この Unit の目的

Shell Script の根幹となる Linux の入出力モデルと、file / path / permission の基本的な仕組みを学ぶ。  
この Unit では、stdin / stdout / stderr、file descriptor、redirect、pipe、pipeline、absolute path / relative path、file の種類、owner / group / others、read / write / execute permission、`chmod`、temporary file / directory を扱う。  
redirect や pipe を単なる記号として暗記するのではなく、「process が持つ file descriptor がどこへ接続されているか」「stdout が次の command の stdin へどう渡るか」という観点から実際の挙動を確認する。

here document、here string、`umask`、0 / 1 / 2 以外の file descriptor についても、関連する基本事項として軽く扱う。  
ACL、SELinux、AppArmor、filesystem の内部構造は、この Unit の学習対象にはしない。

## 学習内容

### 標準入出力と file descriptor

Linux の process は、入力元や出力先を file descriptor と呼ばれる整数値で扱う。  
command や Shell Script を実行すると、通常は最初から以下の 3 つの file descriptor が利用できる。

```text
0 : stdin
1 : stdout
2 : stderr
```

stdin は standard input、stdout は standard output、stderr は standard error を表す。  
Terminal から command を実行した場合、通常は stdin が Terminal からの入力へ、stdout と stderr が Terminal への表示へ接続されている。

```text
Terminal
  │
  └─ stdin (fd 0)
       ↓
    process
       ├─ stdout (fd 1) ─→ Terminal
       └─ stderr (fd 2) ─→ Terminal
```

重要なのは、stdout と stderr が見た目上どちらも同じ Terminal に表示される場合でも、process から見ると別々の file descriptor であるという点である。  
そのため、stdout だけを file へ保存する、stderr だけを別 file へ保存するといった操作が可能になる。

Bash では、通常の command 出力は stdout へ送られる。  
明示的に `>&2` を利用すると、stdout として出す代わりに stderr へ出力できる。

```bash
printf '%s\n' 'normal output'
printf '%s\n' 'error output' >&2
```

file descriptor は 0 / 1 / 2 だけに限定されない。  
必要であれば 3 以降の番号も利用できるが、この Unit では「追加の file descriptor も存在し、明示的に open / close できる」という基本までを扱う。

### redirect

redirect は、command が利用する stdin / stdout / stderr などの接続先を Shell 側で変更する仕組みである。  
記号ごとに別の特殊機能として覚えるのではなく、どの file descriptor をどこへ向けるかとして考える。

#### `>` と `>>`

`>` は stdout を file へ向ける。

```bash
command > output.txt
```

file が存在しない場合は作成され、存在する場合は基本的に内容を上書きする。  
`>>` は stdout を file の末尾へ追記する。

```bash
command >> output.txt
```

どちらも stdout、つまり fd 1 の接続先を変更している。

#### `<`

`<` は file を command の stdin として接続する。

```bash
command < input.txt
```

command 側から見ると、stdin から読み取っている点は変わらない。  
Shell が fd 0 の接続先を Terminal などから file へ変更している。

#### `2>` と `2>>`

`2>` は stderr、つまり fd 2 を file へ向ける。

```bash
command 2> error.log
```

`2>>` は stderr を file の末尾へ追記する。

```bash
command 2>> error.log
```

stdout と stderr が別の file descriptor であるため、片方だけを保存し、もう片方を Terminal に残すことができる。

#### `2>&1`

`2>&1` は、stderr の fd 2 を「その時点で fd 1 が向いている接続先」と同じ場所へ向ける。

```bash
command > combined.log 2>&1
```

この場合は、最初に stdout を `combined.log` へ向け、その後 stderr をその stdout と同じ接続先へ向ける。  
結果として stdout と stderr の両方が同じ file に入る。

```text
最初:
fd 1 ─→ Terminal
fd 2 ─→ Terminal

> combined.log:
fd 1 ─→ combined.log
fd 2 ─→ Terminal

2>&1:
fd 1 ─→ combined.log
fd 2 ─→ combined.log
```

#### redirect の順序

redirect は左から順番に処理される。  
そのため、以下の 2 つは同じ意味ではない。

```bash
command > output.txt 2>&1
command 2>&1 > output.txt
```

後者では、まず fd 2 を「その時点の fd 1」、つまり通常は Terminal と同じ接続先へ向ける。  
その後で fd 1 だけを `output.txt` へ変更するため、stderr は Terminal 側へ残る。

```text
2>&1:
fd 1 ─→ Terminal
fd 2 ─→ Terminal

> output.txt:
fd 1 ─→ output.txt
fd 2 ─→ Terminal
```

この違いは redirect を理解する上で特に重要である。  
`2>&1` は「stdout と stderr を永久に一体化する記号」ではなく、実行された時点の fd 1 の接続先を fd 2 に複製する操作として捉える。

#### `/dev/null`

`/dev/null` は、書き込んだ data を破棄する特殊な file である。

```bash
command > /dev/null
command 2> /dev/null
```

不要な stdout や stderr を表示・保存したくない場合に利用できる。  
ただし、error message を無条件に捨てると問題の原因が分からなくなるため、「不要な出力であることが分かっている場合」に使うことが重要である。

#### `tee`

通常の `>` では stdout を file へ redirect すると、stdout は Terminal へ表示されなくなる。  
`tee` は stdin から受け取った data を stdout へ流しながら、同じ内容を file にも保存できる。

```text
command stdout
      ↓
     tee ─→ file
      ↓
   Terminal
```

```bash
command | tee output.txt
```

Terminal で結果を確認しつつ log や結果 file を残したい場合などに利用できる。

### pipe と pipeline

pipe (`|`) は、左側 command の stdout を右側 command の stdin へ接続する。

```bash
command1 | command2
```

概念的には以下のようになる。

```text
command1
  stdout
    │
    │ pipe
    ↓
  stdin
command2
```

複数の pipe をつなげることもできる。

```bash
command1 | command2 | command3
```

この一連の command を pipeline として考える。

```text
command1 stdout
        ↓
      pipe
        ↓
command2 stdin
command2 stdout
        ↓
      pipe
        ↓
command3 stdin
```

pipeline は単に一つの command の内部で順番に文字列処理をしているわけではない。  
複数の command がそれぞれ実行され、process 同士の stdin / stdout が pipe で接続される。

#### pipeline の exit status

Bash で `pipefail` が無効な通常状態では、pipeline 全体の exit status は基本的に最後の command の exit status になる。

```bash
false | true
```

途中の `false` は失敗していても、最後の `true` が成功するため、pipeline 全体の exit status は `0` になる。

一方、以下では最後の `false` が失敗する。

```bash
true | false
```

この場合は pipeline 全体も non-zero になる。

#### `pipefail`

`set -o pipefail` を有効にすると、pipeline の途中で失敗した command がある場合も、その失敗を pipeline 全体の exit status に反映できる。

```bash
set -o pipefail
false | true
```

この場合は、最後の `true` が成功していても pipeline 全体は non-zero になる。  
より正確には、複数の command が non-zero で終了した場合、右端側の non-zero status が pipeline の status になる。

`pipefail` は、pipeline の途中の失敗を見逃したくない Shell Script で重要になる。  
error handling 全体や `set -euo pipefail` の扱いは Unit 04 で詳しく学ぶ。

### file と path

Shell Script では、command だけでなく file / directory を path で正しく扱うことが重要になる。

#### absolute path と relative path

absolute path は `/` から始まり、filesystem 上の位置を root directory から表す。

```text
/tmp/example.txt
/home/user/data.txt
```

relative path は current working directory を基準に解釈される。

```text
data.txt
logs/app.log
../config.txt
```

同じ relative path でも current working directory が変われば、参照する対象が変わる可能性がある。

#### current working directory

process には current working directory がある。  
Bash では `pwd` で現在の working directory を確認でき、`cd` で変更できる。

```bash
pwd
cd /tmp
pwd
```

relative path を利用する Script では、「どの directory を基準に解釈されるか」を意識する必要がある。

#### regular file

通常の text file、Script file、binary file など、多くの file は regular file として扱われる。  
内容や用途が違っていても、filesystem 上の種類としては regular file である場合がある。

#### directory

directory は file や別の directory への entry を保持する。  
path を構成する階層として利用される。

#### symbolic link

symbolic link は、別の path を参照する link である。

```text
regular-link → regular.txt
```

link 自体と、その link が参照する対象は区別して考える。  
`ls -l` や `[[ -L ... ]]` などで symbolic link を確認できる。

#### hidden file

Linux では、basename が `.` から始まる file / directory を通常 hidden file / hidden directory と呼ぶ。

```text
.env
.gitignore
.config
```

hidden file は filesystem 上の特別な file type ではなく、名前による慣習である。  
通常の `ls` では表示されないが、`ls -a` などで表示できる。

#### executable file

「executable file」という独立した filesystem type があるわけではない。  
Shell Script などの regular file に execute permission が付与され、直接実行できる状態になっている場合などを、実用上 executable file と呼ぶ。

Shell Script の直接実行については、この Unit の permission の実践で確認する。

#### 空白を含む filename

Linux の filename には空白を含めることができる。

```text
report 2026.txt
```

Shell では空白が argument の区切りとして解釈されるため、variable に file path を保持している場合は quote が重要になる。

```bash
cat "$file_path"
```

quote しない場合、Shell expansion の結果が複数 argument に分かれる可能性がある。  
Shell expansion と quoting の詳細は Unit 03 で扱うため、この Unit では filename を安全に一つの argument として扱う必要があることを確認する。

### permission

Linux の基本的な permission は、誰に対する permission かという区分と、何を許可するかという区分の組み合わせで考える。

```text
対象:
owner
group
others

permission:
read
write
execute
```

`ls -l` では、たとえば以下のような形式で確認できる。

```text
-rwxr-xr--
```

先頭の 1 文字は file type を表し、その後の 9 文字が owner / group / others の permission を 3 文字ずつ表す。

```text
- rwx r-x r--
  │   │   └─ others
  │   └───── group
  └───────── owner
```

#### read / write / execute

regular file に対する基本的な意味は以下のように整理できる。

- read (`r`)
  - file の内容を読み取る。
- write (`w`)
  - file の内容を変更する。
- execute (`x`)
  - file を program / Script として直接実行する。

directory に対する `r` / `w` / `x` の意味は regular file と完全には同じではない。  
この Unit では細かな組み合わせには深入りせず、permission は file だけでなく directory にも設定されることを押さえる。

#### `chmod`

`chmod` は file / directory の permission を変更する command である。  
指定方法として symbolic notation と numeric notation がある。

symbolic notation では、誰に対してどの permission を操作するかを記号で表す。

```bash
chmod u+x script.sh
chmod u-x script.sh
```

代表的な対象は以下である。

```text
u : user / owner
g : group
o : others
a : all
```

操作には `+`、`-`、`=` などを利用する。

numeric notation では、read / write / execute を数値で表す。

```text
read    = 4
write   = 2
execute = 1
```

permission を足し合わせて owner / group / others の順に指定する。

```text
640
││└─ others: 0 = ---
│└── group:  4 = r--
└─── owner:  6 = rw-

755
││└─ others: 5 = r-x
│└── group:  5 = r-x
└─── owner:  7 = rwx
```

#### Shell Script の execute permission

Shell Script を直接実行する場合は、Script file 自体に execute permission が必要になる。

```bash
./script.sh
```

この形式では、OS が executable file として Script を起動し、先頭の shebang などを利用して interpreter を決定する。

```bash
#!/usr/bin/env bash
```

一方、以下では executable である Bash 自体を先に起動し、Bash に Script file を読み込ませる。

```bash
bash script.sh
```

この場合、Script file 自体に execute permission がなくても、Bash が読み取れる permission があれば実行できる。

```text
./script.sh
→ Script file 自体を直接実行
→ execute permission が必要
→ shebang が interpreter 選択に関係

bash script.sh
→ Bash を実行し、Script を入力 file として読み込む
→ Script file 自体の execute permission は不要
```

#### `umask`

`umask` は、新しく作成される file / directory の初期 permission から、許可しない permission bit を除外するための設定である。  
一般的な作成時の基準は、regular file が `666`、directory が `777` であり、そこから `umask` の bit が除外される。

たとえば `umask 022` の場合、一般的には以下のようになる。

```text
file      666 → 644
directory 777 → 755
```

`umask 077` では、group / others の permission が除外される。

```text
file      666 → 600
directory 777 → 700
```

この Unit では、`umask` が新規作成時の permission に影響する仕組みを確認するところまでとする。

### temporary file / directory

Shell Script では、一時的な中間 data、作業 file、展開先などを必要とする場合がある。  
Linux では `/tmp` が temporary data の保存先としてよく利用される。

ただし、temporary file の名前を固定して自分で組み立てると、同名 file との衝突や予期しない既存 file の利用などにつながる。  
`mktemp` を利用すると、衝突しにくい unique な名前で temporary file を作成できる。

```bash
temp_file=$(mktemp)
```

temporary directory は `-d` で作成できる。

```bash
temp_dir=$(mktemp -d)
```

作成された temporary file / directory も通常の file / directory であり、利用後は不要であれば削除する。  
この Unit のサンプルでは実行の最後に cleanup しているが、Script が途中で終了した場合にも cleanup する仕組みとして `trap` が利用できる。`trap` を使った安全な cleanup は Unit 04 で扱う。

### here document / here string

here document と here string は、command の stdin へ data を渡す方法である。

here document は複数行の data を記述できる。

```bash
cat <<'TEXT'
first line
second line
TEXT
```

here string は一つの文字列を stdin として渡せる。

```bash
read -r value <<< 'sample'
```

この Unit では stdin の接続方法の一つとして基本形だけを確認する。

### この Unit で扱わない詳細

この Unit では、Shell Script の入出力・file・permission を理解するための基本までを扱う。  
以下は対象外とする。

- ACL
- SELinux
- AppArmor
- filesystem の内部構造

これらを扱わなくても、stdin / stdout / stderr、redirect、pipe、path、permission の基本的な挙動は理解できる。

## 使用するもの

この Unit では、主に以下を利用する。

- WSL 2 上の Linux
- Bash
- `printf`
- `read`
- `cat`
- `ls`
- `stat`
- `grep`
- `tr`
- `sed`
- `tee`
- `mkdir`
- `rmdir`
- `rm`
- `touch`
- `ln`
- `chmod`
- `mktemp`
- `pwd`
- `cd`
- `exec`
- `umask`
- `/proc`
- `/dev/null`

追加 package や外部 library は使用しない。

## 事前準備

Unit 01 が完了し、Linux process、exit status、Shell builtin / external command などの基本を確認済みであることを前提とする。  
Bash が利用できることを確認する。

```bash
bash --version
```

リポジトリ root から Unit 02 へ移動する。

```bash
cd units/02-standard-io-pipes-files-permissions
```

成果物を確認する。

```bash
find . -maxdepth 3 -type f | sort
```

以下の構成になっていることを確認する。

```text
02-standard-io-pipes-files-permissions/
├─ README.md
└─ examples/
   ├─ file-path/
   │  ├─ 01-absolute-relative-current-directory.sh
   │  ├─ 02-file-types.sh
   │  └─ 03-filename-with-spaces.sh
   ├─ permission/
   │  ├─ 01-owner-group-permissions.sh
   │  ├─ 02-chmod-symbolic.sh
   │  ├─ 03-chmod-numeric.sh
   │  ├─ 04-execute-permission.sh
   │  └─ 05-umask.sh
   ├─ pipe/
   │  ├─ 01-stdout-to-stdin.sh
   │  ├─ 02-pipeline-processes.sh
   │  ├─ 03-pipeline-status.sh
   │  └─ 04-pipefail.sh
   ├─ redirect/
   │  ├─ 01-stdout-stdin-redirect.sh
   │  ├─ 02-stderr-redirect.sh
   │  ├─ 03-merge-and-order.sh
   │  ├─ 04-dev-null.sh
   │  └─ 05-tee.sh
   ├─ standard-io/
   │  ├─ 01-stdin-stdout-stderr.sh
   │  ├─ 02-file-descriptor-0-1-2.sh
   │  ├─ 03-here-input.sh
   │  └─ 04-additional-file-descriptor.sh
   └─ temporary-file/
      ├─ 01-mktemp-file.sh
      └─ 02-mktemp-directory.sh
```

各 Script は temporary file / directory を必要に応じて作成し、通常終了時に削除する。  
学習中に `Ctrl + C` などで途中終了した場合は temporary data が `/tmp` などに残る可能性がある。途中終了時も確実に cleanup する `trap` の利用は Unit 04 で扱う。

この Unit でも、実行過程や展開後の command を確認する価値がある場合は `bash -x` を利用する。  
ただし redirect や stdout / stderr 自体を観察するサンプルでは、`bash -x` の trace が stderr に追加されることで結果が分かりにくくなる場合があるため、通常実行を基本とする。

## 学習・実践

### 1. 標準入出力と file descriptor を確認する

まず、stdin / stdout / stderr が別々の入出力経路であることを確認する。

```bash
bash examples/standard-io/01-stdin-stdout-stderr.sh
```

実行後、任意の文字列を 1 行入力して Enter を押す。  
`read` が stdin から入力を受け取り、その値が stdout へ、入力文字数が stderr へ出力される。

通常の Terminal では stdout と stderr の両方が同じ画面へ表示されるため、見た目だけでは違いが分かりにくい。  
しかし Script 内では stdout が fd 1、stderr が fd 2 として別々に扱われており、後の redirect で別々の接続先へ変更できる。

続いて、現在の Bash が持つ fd 0 / 1 / 2 を確認する。

```bash
bash examples/standard-io/02-file-descriptor-0-1-2.sh
```

`/proc/<PID>/fd/` 配下に `0`、`1`、`2` が存在し、それぞれ何らかの対象への symbolic link として見えることを確認する。  
Terminal、IDE、pipe、実行環境などによって link 先は異なるため、特定の表示内容そのものを覚える必要はない。

ここで重要なのは、stdin / stdout / stderr が抽象的な「入力・出力の名前」だけではなく、process が持つ fd 0 / 1 / 2 として実際の接続先に結び付いていることである。

#### here document / here string

stdin へ data を渡す別の方法として、here document と here string を確認する。

```bash
bash examples/standard-io/03-here-input.sh
```

here document の複数行が `cat` の stdin へ渡され、here string の文字列が `read` の stdin へ渡される。  
この Unit では構文を使いこなすことより、「Terminal や file 以外からも stdin へ data を接続できる」という位置付けを理解する。

#### 0 / 1 / 2 以外の file descriptor

追加の file descriptor を軽く確認する。

```bash
bash -x examples/standard-io/04-additional-file-descriptor.sh
```

`exec 3> "$output_file"` で fd 3 を file への書き込み用として open し、`>&3` でその fd へ出力している。  
最後に `exec 3>&-` で fd 3 を close する。

この例から、0 / 1 / 2 は代表的な標準 file descriptor であり、file descriptor 自体が 3 種類だけに制限されているわけではないことを確認する。

### 2. Redirect で入出力先を変更する

stdout / stdin の基本的な redirect から確認する。

```bash
bash examples/redirect/01-stdout-stdin-redirect.sh
```

最初の `>` で stdout が `output.txt` へ書き込まれ、次の `>>` で同じ file の末尾へ追記される。  
その file を `<` で `cat` の stdin へ接続することで、保存された 2 行が stdout に表示される。

次に stderr だけを file へ redirect する。

```bash
bash examples/redirect/02-stderr-redirect.sh
```

child Bash が stderr へ出した 1 行目を `2>` で file へ保存し、2 行目を `2>>` で追記している。  
実行中は error message が直接 Terminal に表示されず、最後の `cat` で file に保存された 2 行が表示されることを確認する。

stdout と stderr が別の fd だからこそ、stdout はそのままにして stderr だけを別の場所へ向けることができる。

#### `2>&1` と redirect の順序

redirect の順序によって結果が変わることを確認する。

```bash
bash examples/redirect/03-merge-and-order.sh
```

case A は以下の順序である。

```bash
> "$case_a" 2>&1
```

stdout を先に file へ向け、その後 stderr をその stdout と同じ場所へ向けるため、stdout / stderr の両方が `case-a.txt` に入る。

case B は以下の順序である。

```bash
2>&1 > "$case_b"
```

最初に stderr を現在の stdout、つまり Terminal と同じ場所へ向ける。  
その後 stdout だけを file へ変更するため、`stderr from case B` は Terminal に表示され、`case-b.txt` には stdout だけが残る。

この結果を、単に「順番によって変わる」と暗記するのではなく、fd 1 / fd 2 が各段階でどこへ接続されているかを追って説明できるようにする。

#### `/dev/null`

不要な出力を破棄する例を確認する。

```bash
bash examples/redirect/04-dev-null.sh
```

stdout を `/dev/null` へ向けた出力と、stderr を `/dev/null` へ向けた出力は表示されず、redirect していない `visible output` だけが Terminal に表示される。

`/dev/null` は便利だが、必要な error message まで無条件に破棄しないようにする。

#### `tee`

stdout を画面に残しながら file にも保存する例を確認する。

```bash
bash examples/redirect/05-tee.sh
```

最初の `line through tee` は `tee` 自身の stdout として Terminal に表示され、同じ内容が temporary file にも保存される。  
その後 `cat` でも保存内容を表示するため、同じ文字列が 2 回見える。

この結果から、`tee` が「表示する command」なのではなく、stdin を stdout へ流しながら file にも複製していることを確認する。

### 3. Pipe と pipeline の動作を確認する

まず、pipe が stdout と stdin をつなぐことを確認する。

```bash
bash examples/pipe/01-stdout-to-stdin.sh
```

data は以下のように流れる。

```text
printf
  ↓ stdout
grep '^a'
  ↓ stdout
tr '[:lower:]' '[:upper:]'
  ↓ stdout
Terminal
```

`printf` が出した複数行のうち、`grep` で `a` から始まる行だけが残り、`tr` で大文字へ変換される。  
temporary file を介さず、前の command の stdout が次の command の stdin として使われている。

#### pipeline 内の process

pipeline の各 stage が process として動いていることを確認する。

```bash
bash examples/pipe/02-pipeline-processes.sh
```

parent Bash、stage 1、stage 2 で異なる `BASHPID` が表示されることを確認する。  
PID の表示は stderr に出しているため pipeline の data には混ざらず、stdout の `alpha` / `beta` だけが `tr`、`sed` へ流れる。

Unit 01 で扱った process の知識と接続すると、pipeline は一つの process 内の文字列変換ではなく、複数 process の標準入出力を pipe でつないだものとして理解できる。

#### pipeline の exit status

通常の pipeline の exit status を確認する。

```bash
bash examples/pipe/03-pipeline-status.sh
```

結果は以下の関係になる。

```text
false | true  -> 0
true  | false -> non-zero
```

`pipefail` が無効な通常状態では、基本的に最後の command の exit status が pipeline 全体の結果になる。  
そのため、途中の command が失敗していても、最後が成功すれば pipeline 全体は `0` になり得る。

#### `pipefail`

同じ pipeline を `pipefail` の無効・有効で比較する。

```bash
bash examples/pipe/04-pipefail.sh
```

`false | true` に対して、`pipefail` が無効な場合は `0`、有効な場合は non-zero になることを確認する。

pipeline を利用した Script で途中の処理失敗も検知したい場合、最後の command だけを見る通常の挙動では不十分なことがある。  
`pipefail` はその問題に対処する Bash の option である。

### 4. File・path・filename の基本を確認する

absolute path / relative path / current working directory の関係を確認する。

```bash
bash -x examples/file-path/01-absolute-relative-current-directory.sh
```

Script は temporary directory を作成してその中へ `cd` し、同じ `sample.txt` を relative path と absolute path の両方で読み込む。  
relative path の `subdir/sample.txt` は current working directory を基準に解釈される一方、`"$work_dir/subdir/sample.txt"` は `/` から始まる absolute path である。

`pwd` の結果と path を照らし合わせ、relative path が常に同じ対象を表すわけではないことを確認する。

#### file の種類と状態

regular file、directory、symbolic link、hidden file、execute permission を持つ Script を確認する。

```bash
bash examples/file-path/02-file-types.sh
```

`[[ -f ... ]]`、`[[ -d ... ]]`、`[[ -L ... ]]`、`[[ -x ... ]]` の結果と `ls -la` の表示を比較する。

ここでは、hidden file と executable file の位置付けにも注意する。

- hidden file
  - `.` から始まる filename による慣習であり、独立した filesystem type ではない。
- executable file
  - 今回の `run.sh` は regular file に execute permission が付いている状態であり、「executable」という別の file type ではない。
- symbolic link
  - link 自体が別の path を参照する filesystem 上の種類である。

#### 空白を含む filename

filename に空白がある場合の quote の重要性を確認する。

```bash
bash examples/file-path/03-filename-with-spaces.sh
```

最初の `show_arguments "$filename"` では `report 2026.txt` 全体が 1 argument として渡る。  
次の `show_arguments $filename` では、quote していないため `report` と `2026.txt` の 2 arguments に分かれる。

後半では、実際に空白を含む path の file を `"$file_path"` と quote して読み書きする。  
Shell expansion の詳細は Unit 03 で扱うが、file path を variable から利用するときに quote が重要になる理由を実際の argument 数から確認する。

### 5. Permission と Script の実行条件を確認する

まず、file の owner / group / permission 表示を確認する。

```bash
bash examples/permission/01-owner-group-permissions.sh
```

`stat` では owner、group、numeric notation の mode を確認し、`ls -l` では symbolic notation の permission と owner / group を確認する。

実行環境によって実際の user / group 名は異なるため、特定の名前を覚える必要はない。  
owner / group / others という区分と、それぞれに read / write / execute permission が設定される構造を見る。

#### symbolic notation

`chmod` の symbolic notation を確認する。

```bash
bash examples/permission/02-chmod-symbolic.sh
```

`chmod u+x` で owner に execute permission が追加され、`chmod u-x` で削除される。  
各操作後の `ls -l` を比較し、owner 部分の `x` が変化することを確認する。

#### numeric notation

numeric notation を確認する。

```bash
bash examples/permission/03-chmod-numeric.sh
```

まず `640` を設定する。

```text
owner  = 6 = 4 + 2 = rw-
group  = 4         = r--
others = 0         = ---
```

続いて `755` を設定する。

```text
owner  = 7 = 4 + 2 + 1 = rwx
group  = 5 = 4 + 1     = r-x
others = 5 = 4 + 1     = r-x
```

`stat` の numeric 表示と symbolic 表示を比較し、同じ permission を別の notation で表していることを確認する。

#### `./script.sh` と `bash script.sh`

Shell Script の execute permission が実行方法によってどう関係するか確認する。

```bash
bash examples/permission/04-execute-permission.sh
```

最初に `sample.sh` を `644` にして execute permission を外した状態で直接実行する。  
この実行は失敗し、一般的な Linux 環境では exit status `126` と Permission denied の error が確認できる。

続いて以下に相当する実行を行う。

```bash
bash sample.sh
```

この場合は Bash 自体を実行し、Bash が readable な Script file を読み込むため、Script file 自体に execute permission がなくても実行できる。

最後に `chmod +x` を行った後、同じ Script を直接実行できることを確認する。  
これにより、`./script.sh` と `bash script.sh` は単なる書き方の違いではなく、OS に何を直接実行させているかが異なることを理解する。

#### `umask`

新規作成時の permission に影響する `umask` を軽く確認する。

```bash
bash examples/permission/05-umask.sh
```

`umask 022` で作成した file / directory と、`umask 077` で作成したものの mode を比較する。

一般的には以下の結果になる。

```text
umask 022:
file      644
directory 755

umask 077:
file      600
directory 700
```

file と directory で結果が異なるのは、作成時に基準となる permission が一般的に file は `666`、directory は `777` と異なるためである。  
この Script は最後に元の `umask` へ戻し、学習用の変更を残さない。

### 6. Temporary file / directory を安全に作成する

`mktemp` で temporary file を作成する。

```bash
bash examples/temporary-file/01-mktemp-file.sh
```

表示された path が `/tmp/...` などの unique な temporary file になっていることを確認する。  
その file に data を書き込み、読み取った後で削除している。

固定名を `/tmp/sample.txt` のように決め打ちするより、`mktemp` に名前生成を任せることで、同名 file との衝突を避けやすくなる。

続いて temporary directory を作成する。

```bash
bash examples/temporary-file/02-mktemp-directory.sh
```

`mktemp -d` で unique な directory を作成し、その配下に 2 つの temporary file を作成している。  
複数の中間 file を一つの作業単位として扱う場合、temporary directory を一つ作り、その配下へまとめる方法が利用できる。

どちらのサンプルも最後に明示的な cleanup を行っている。  
実務では Script の途中失敗や signal でも cleanup が必要になる場合があり、そのための `trap` は Unit 04 で改めて扱う。

## 実行・確認ポイント

### 標準入出力

- stdin / stdout / stderr は、それぞれ fd 0 / 1 / 2 として別々に扱われる。
- Terminal 上では stdout と stderr が同じ場所へ表示されても、process 内では別の出力経路である。
- `/proc/<PID>/fd/` から process が持つ file descriptor の接続先を確認できる。
- here document / here string も stdin へ data を渡す方法である。
- 0 / 1 / 2 以外の file descriptor も利用できる。

### Redirect

- `>` / `>>` は stdout、`2>` / `2>>` は stderr の接続先を変更する。
- `<` は file を stdin へ接続する。
- `2>&1` は fd 2 を、その時点の fd 1 と同じ接続先へ向ける。
- redirect は左から順番に処理されるため、`> file 2>&1` と `2>&1 > file` は結果が異なる。
- `/dev/null` へ redirect した data は破棄される。
- `tee` は stdin を stdout へ流しながら file にも保存できる。

### Pipe / Pipeline

- `|` は左側 command の stdout と右側 command の stdin を接続する。
- pipeline 内では複数の command / process が動作する。
- `pipefail` が無効な通常状態では、pipeline 全体の exit status は基本的に最後の command の結果になる。
- `pipefail` を有効にすると、途中の command の失敗も pipeline 全体の失敗として扱える。

### File / Path

- absolute path は `/` から始まり、relative path は current working directory を基準に解釈される。
- process には current working directory があり、`pwd` / `cd` で確認・変更できる。
- regular file / directory / symbolic link は異なる種類として確認できる。
- hidden file は `.` から始まる名前の慣習であり、独立した filesystem type ではない。
- executable file は、regular file などに execute permission が付いた状態として扱われる場合がある。
- 空白を含む filename / path を variable から扱う場合は quote が重要になる。

### Permission

- basic permission は owner / group / others と read / write / execute の組み合わせで考える。
- `chmod` では symbolic notation と numeric notation の両方を利用できる。
- `r=4`、`w=2`、`x=1` を組み合わせて numeric permission を表せる。
- `./script.sh` では Script file 自体の execute permission が必要になる。
- `bash script.sh` では Bash が Script file を読み込むため、Script file 自体の execute permission は不要である。
- `umask` は新規 file / directory の初期 permission に影響する。

### Temporary file / directory

- `/tmp` は temporary data の保存先としてよく利用される。
- `mktemp` は unique な temporary file を作成できる。
- `mktemp -d` は unique な temporary directory を作成できる。
- temporary data は不要になったら cleanup する。

## 学習ポイント

### Redirect は「data を移動する記号」ではなく file descriptor の接続先を変更する仕組み

`>`、`2>`、`<`、`2>&1` などを一つずつ独立した記号として暗記すると、少し複雑な redirect になったときに挙動を説明しにくくなる。  
今回の実践では、stdin / stdout / stderr が fd 0 / 1 / 2 として存在し、redirect によってその接続先が変更されることを確認した。

たとえば以下は、「stdout と stderr を file に保存する魔法の組み合わせ」ではない。

```bash
command > output.txt 2>&1
```

処理を段階に分けると、

```text
fd 1 を output.txt へ変更
↓
fd 2 を現在の fd 1 と同じ output.txt へ変更
```

となる。

この理解があれば、順序を逆にしたときに stderr が Terminal へ残る理由も説明できる。  
redirect を読むときは、「どの fd を」「その時点でどこへ向けたか」を順番に追うことが基本になる。

### stdout と stderr を分けることには実務上の意味がある

stdout と stderr は Terminal では同じ画面に見えることが多いが、役割を分けることで Script や tool を組み合わせやすくなる。

```text
stdout
→ 正常な data / 次の処理へ渡したい結果

stderr
→ error / warning / diagnostic information
```

すべての command が厳密にこの使い分けをしているとは限らないが、この役割分担を意識すると pipe や redirect の設計が理解しやすい。

たとえば command の正常な data だけを pipe で次へ渡し、diagnostic message は stderr として Terminal に残すことができる。  
`02-pipeline-processes.sh` で PID 情報を stderr に出したのも、pipeline を流れる stdout の data と観察用情報を混ぜないためである。

### Pipe は text 処理の記号ではなく process 間の入出力接続

Shell では `grep | sort | ...` のような書き方をよく見るため、pipe を「text を次の command に渡す記号」とだけ覚えやすい。  
しかし実際には、左側 process の stdout と右側 process の stdin を接続している。

Unit 01 の process の知識と合わせると、以下のように整理できる。

```text
process A
fd 1
  ↓
pipe
  ↓
fd 0
process B
```

pipeline が複数 process で動くことを理解すると、exit status、stderr の扱い、途中 failure、performance などを考える土台にもなる。

### Pipeline の最後が成功していても、途中の処理が成功したとは限らない

`false | true` が通常 `0` になることは、pipeline を扱う上で重要な落とし穴である。  
pipeline 全体が成功に見えても、途中の command が失敗している可能性がある。

`pipefail` は、この途中 failure を pipeline の結果へ反映するための仕組みである。  
Unit 04 で error handling を学ぶ際には、単体 command の exit status だけでなく pipeline の status をどう扱うかという観点につながる。

### Path は文字列ではなく「どの基準から対象を指しているか」を意識する

relative path は短く書けて便利だが、current working directory に依存する。  
そのため同じ `data/file.txt` という文字列でも、どこから Script を実行しているかによって別の対象を指したり、見つからなかったりする。

```text
absolute path
→ filesystem root から対象を指定

relative path
→ current working directory から対象を指定
```

Shell Script で path に関する不具合が起きたときは、「その file が存在するか」だけでなく、「現在どの directory を基準に path が解釈されているか」を確認することが重要になる。

### File の「種類」「名前」「permission」は別の観点

`02-file-types.sh` では regular file、directory、symbolic link、hidden file、executable file を並べて確認したが、これらはすべて同じ分類軸ではない。

```text
filesystem 上の種類:
regular file / directory / symbolic link ...

名前の慣習:
.hidden

permission / 実行可能性:
execute permission を持つ regular file
```

hidden file が特別な file type ではないことや、Shell Script が「executable file」という別種類になるわけではないことを区別すると、`ls -l` や test command の結果も理解しやすくなる。

### Permission は「誰に」「何を許可するか」の組み合わせとして読む

`rwxr-xr--` のような表記を一つの文字列として暗記するより、owner / group / others の 3 組へ分けて考える。

```text
rwx | r-x | r--
owner group others
```

さらに各組の `r` / `w` / `x` を read / write / execute として読む。  
numeric notation も別の permission system ではなく、同じ permission を `4 / 2 / 1` の和で表しているだけである。

この対応関係を理解していれば、`chmod 755` と `chmod u+x` のような異なる notation も同じ permission 操作として捉えられる。

### `./script.sh` と `bash script.sh` は「実行主体」が異なる

execute permission のサンプルでは、同じ Script file でも実行方法によって結果が変わった。

```text
./script.sh
→ OS に Script file 自体の実行を要求
→ execute permission が必要
→ shebang が interpreter の決定に関係

bash script.sh
→ executable である Bash を起動
→ Bash が Script file を読み込む
→ Script file 自体の execute permission は不要
```

この違いを理解すると、「Script の内容は正しいのに Permission denied になる」「`bash script.sh` なら動くのに `./script.sh` では動かない」といった現象を permission と execution model から説明できる。

### Temporary file は名前を自分で決めるより `mktemp` に任せる

temporary data が必要だからといって、`/tmp/work.txt` のような固定名を毎回使うと、別実行との衝突や既存 file の利用につながる可能性がある。  
`mktemp` は unique な file / directory を作成し、その path を Script で利用できるようにする。

また、「temporary だから自動的にすぐ消える」と考えるのではなく、自分の Script が作成した temporary data をいつ cleanup するかも考える必要がある。  
この Unit では正常終了時に削除したが、Unit 04 では `trap` を利用して途中終了も含めた cleanup へ発展させる。

### この Unit の概念は後続の Shell Script 全体の土台になる

stdin / stdout / stderr、redirect、pipe、path、permission は、特定の一つの Script だけで使う知識ではない。  
今後扱う text / log 処理、API、batch、DB、Docker、CI/CD でも同じ仕組みが繰り返し登場する。

たとえば、

```text
API response を jq へ渡す
→ pipe

log を file に保存する
→ redirect / tee

error log を分ける
→ stderr

batch 用 Script を直接実行する
→ execute permission / shebang

temporary data を扱う
→ mktemp

CI で command failure を判定する
→ exit status / pipefail
```

というように、後続 Unit の実用的な処理も今回の基礎の組み合わせとして理解できる。  
この Unit では個々の記号や command の暗記より、「process の入出力がどこにつながっているか」「file / path / permission がどう解釈されているか」を意識することが重要である。
