# 01. Linux / Shell の実行モデル

## この Unit の目的

Shell Script や Docker、Linux Server 上の処理を理解するための前提として、Linux 上でプログラムや command がどのように実行されるのかを学ぶ。  
この Unit では、program / process / thread、PID / PPID、parent process / child process、Shell と command 実行、Shell builtin / external command、`PATH`、foreground / background、exit status、signal、Shell variable / environment variable、subshell、`source` を扱う。  
単に用語を覚えるのではなく、小さな Bash Script を読み、実際に実行し、process の状態や command の実行順序、終了結果、environment の継承などを観察しながら理解する。

Docker Container と process、Container の main process、PID 1、Container 停止時の signal についても、Linux process の知識とのつながりとして軽く扱う。  
Docker 自体の操作方法は、この Unit の学習対象にはしない。

## 学習内容

### プログラム・process・thread

program は、コンピューターに実行させる命令やデータを、実行可能ファイルや Script などの形で保持したものである。  
たとえば Bash、`sleep`、`ps` などは program としてファイルに存在し、Shell Script も Bash に読み込まれて実行される program として考えられる。

process は、program が実際に実行され、Linux によって管理されている状態を表す。  
同じ program を複数回実行した場合でも、それぞれは別の process となり、それぞれ異なる PID を持つことができる。

```text
sleep program
├─ process A
└─ process B
```

program は「実行内容そのもの」、process は「その program が実行中になったもの」と整理できる。  
PID は Process ID の略で、Linux が process を識別するための ID である。

thread は、一つの process 内で実行される処理の流れである。  
process は少なくとも一つの thread を持ち、Application によっては一つの process 内で複数の thread を利用する。

```text
program
  ↓ 実行
process
  ├─ thread
  ├─ thread
  └─ ...
```

process と thread は同じものではない。  
この Unit では thread programming や scheduler の詳細には踏み込まず、「process の内部に thread という実行単位がある」という関係までを扱う。

### PID / PPID と親子関係

多くの process は、別の process から起動される。  
process を起動した側を parent process、起動された側を child process として捉えることができる。

PPID は Parent Process ID の略で、その process の parent process の PID を表す。  
たとえば Bash から別の Bash を起動した場合、概念的には以下の関係になる。

```text
parent Bash
  ↓ 起動
child Bash
```

Bash では process を観察するときに、以下の値も利用する。

```bash
$$
$BASHPID
$PPID
```

`$BASHPID` は現在実行中の Bash process の PID、`$PPID` はその Bash の parent process の PID を表す。  
`$$` も Shell の PID として利用されるが、subshell では `$BASHPID` と異なる挙動を示すため、この Unit の後半で実際に比較する。

重要なのは、普段 command を入力している Bash 自体も Linux 上で動作する一つの process であるという点である。  
Shell が process の外側から Linux を操作しているのではなく、Shell 自身も process の一つとして別の process を起動している。

### Shell と command 実行

Bash などの Shell は、入力された command を解釈し、何を実行するかを決定する。  
external command を実行する場合の基本的な流れは、大まかに以下のように考えられる。

```text
command を入力
↓
Shell が command 名を解釈
↓
builtin / external command などを判定
↓
external command なら実行対象を探索
↓
program を process として実行
↓
foreground なら終了を待つ
↓
process が終了
↓
exit status を受け取る
```

実際の Bash の内部実装や system call の詳細は、この Unit では扱わない。  
ここでは、Shell が command を解決し、必要に応じて別の program を process として実行し、その終了結果を受け取るという基本構造を理解する。

#### Shell builtin と external command

Shell から利用できる command は、すべて同じ種類ではない。  
Shell builtin は Bash 自身が内部に持つ command で、代表例として `cd`、`printf`、`export`、`jobs`、`wait`、`source` などがある。

一方、`ls`、`sleep`、`ps` などは、Bash とは別に存在する executable file を実行する external command である。  
Bash が command 名をどのように解釈するかは、`type` や `command -v` で確認できる。

`cd` のように現在の Shell 自身の状態を変更する必要がある処理は、builtin であることに意味がある。  
もし別 process で working directory を変更しても、その変更によって parent Shell の working directory を変更することはできない。

#### `PATH` による command 探索

external command を absolute path で指定しなくても実行できるのは、Shell が `PATH` を利用して実行対象を探索するためである。  
`PATH` には、command を探す directory が `:` 区切りで登録されている。

```bash
printf '%s\n' "$PATH"
```

たとえば `sample-command` と入力すると、Bash は `PATH` に登録された directory から実行対象を探す。  
実際にどの対象へ解決されるかは、以下のように確認できる。

```bash
command -v sample-command
```

`PATH` は後続 Unit の batch、cron、CI/CD でも重要になる。  
実行環境が変わったときに「普段の Terminal では動く command が別環境では見つからない」という現象を理解する土台にもなる。

### foreground / background と job

通常、Shell から command を実行すると、その command が終了するまで Shell は待機する。  
このような実行を foreground execution と考える。

```text
Shell
↓ command を実行
process 実行中
↓ process が終了
Shell が次へ進む
```

command の末尾に `&` を付けると、background で開始できる。

```bash
sleep 2 &
```

background で開始した場合、Shell はその process の終了を待たずに次の処理へ進む。  
Bash では background execution に関連して、以下を利用できる。

- `$!`
  - 直前に background で開始した process の PID
- `jobs`
  - 現在の Bash が管理している job の表示
- `wait`
  - background で動作している process / job の終了待ち

job と process は関連しているが、同じ概念ではない。  
`ps` が Linux 上の process を確認するのに対し、`jobs` は現在の Shell が管理している job を確認する。

### command の成功・失敗と exit status

Linux command や Shell Script は、終了時に整数値の exit status を返す。  
基本的には以下の意味で利用される。

```text
0        成功
non-zero 失敗・エラー・その他の状態
```

non-zero は必ず `1` になるわけではない。  
command や Script が、複数の失敗理由や状態を区別するために別の値を返す場合もある。

Bash では、直前に実行した command の exit status を `$?` で取得できる。

```bash
false
printf '%s\n' "$?"
```

`$?` が保持するのは「直前の command」の結果である。  
確認したい command と `$?` の間で別の command を実行すると、その別 command の exit status に更新される。

exit status は、Shell Script が command の結果を機械的に判断するための重要な仕組みである。  
後続 Unit の条件分岐、`&&` / `||`、error handling、CI/CD の success / failure などにもつながる。

### signal

signal は、Linux が process にイベントや要求を伝えるための仕組みである。  
process の終了に関係する代表的な signal として、この Unit では `SIGINT`、`SIGTERM`、`SIGKILL` を扱う。

#### `SIGINT`

`SIGINT` は、実行中の処理に中断を要求する signal である。  
Terminal で foreground process に対して `Ctrl + C` を入力した場合にも、通常は `SIGINT` が関係する。

process 側で signal handler や Bash の `trap` を用意していれば、`SIGINT` を受け取ったときの処理を定義できる。

#### `SIGTERM`

`SIGTERM` は、process に終了を要求するときに一般的に利用される signal である。  
process 側で捕捉できるため、終了前に cleanup などを行う機会を持てる。

「終了してほしい」という要求を process に伝え、process 側が終了処理を行えるという点が重要である。

#### `SIGKILL`

`SIGKILL` は process を強制的に終了させる signal である。  
process 側では捕捉・無視できないため、signal を受け取った後に独自の cleanup 処理を行うこともできない。

そのため、通常の終了方法で停止できない場合の強制的な手段として位置付ける。

#### `kill`

`kill` は、指定した process へ signal を送る command である。  
名前から「必ず process を強制終了する command」と捉えないことが重要である。

```bash
kill -TERM <PID>
```

送る signal によって、process 側が対応できるか、どのように終了するかが変わる。

### Shell variable と environment variable

Bash で以下のように variable を定義すると、その値は現在の Shell で利用できる。

```bash
UNIT01_VALUE='sample'
```

この段階では、通常その variable は child process の environment には含まれない。  
`export` すると、後から起動する child process へ environment として渡せる。

```bash
export UNIT01_VALUE
```

または以下のように定義と export を同時に行える。

```bash
export UNIT01_VALUE='sample'
```

Bash の観点では、Shell variable に export 属性を付け、その値が child process の environment に含まれると考えると整理しやすい。  
学習上は、現在の Shell 内だけで利用する値と、child process へ渡される environment の値の違いを意識する。

environment の継承は基本的に parent から child の方向である。

```text
parent process
  ↓ environment を渡す
child process
```

child process が自分の variable を変更しても、その変更が parent process へ自動的に戻るわけではない。

### subshell

Bash では丸括弧を利用して command group を subshell で実行できる。

```bash
(
  cd /tmp
  SAMPLE_VALUE='changed'
)
```

subshell 内で variable や working directory を変更しても、subshell が終了した後の parent Shell には基本的にその変更が残らない。

```text
parent Shell
│
├─ subshell
│   ├─ variable を変更
│   └─ working directory を変更
│
└─ subshell 終了
    → parent Shell の状態は元のまま
```

subshell を観察するときは、`$$` と `$BASHPID` の違いにも注目する。  
`$$` は subshell 内でも parent 側と同じ値として展開される一方、`$BASHPID` は現在実行中の Bash process を表すため、subshell 内では異なる値になる。

### Script の通常実行と `source`

Shell Script を以下のように実行すると、現在操作している Shell とは別の Bash process で Script が実行される。

```bash
bash script.sh
```

その Script 内で variable を定義・変更しても、Script の process が終了した後にその変更が parent Shell へ残るわけではない。

一方、`source` は file の内容を現在の Shell 自身で実行する。

```bash
source script.sh
```

短縮形として以下も利用できる。

```bash
. script.sh
```

違いを大まかに表すと以下になる。

```text
bash script.sh
↓
別の Bash process で実行
↓
そこで variable を変更
↓
process 終了
↓
現在の Shell には変更が残らない
```

```text
source script.sh
↓
現在の Shell 自身で file 内容を実行
↓
現在の Shell の variable を変更
↓
変更が残る
```

`source` は現在の Shell の variable、function、working directory などへ直接影響できる。  
便利な一方、別 process に隔離された実行ではないことを理解して利用する必要がある。

### Docker Container と process の関係

この Unit では Docker command を使ったハンズオンは行わないが、Linux process の理解は Docker の理解にもつながる。  
Container の中でも process が動作しており、Container には中心となる main process が存在する。

Container 内から見ると、その main process は PID 1 として扱われる。  
Host 側から見える PID と Container 内から見える PID は同じとは限らないが、この Unit では process namespace の詳細には踏み込まない。

Container の停止にも signal が関係する。  
Container の main process が終了要求を適切に受け取り、必要な終了処理を行えるかどうかは、Container を正常に停止することとも関係する。

この Unit では以下を押さえればよい。

- Container の中でも Linux process が動いている。
- Container には main process がある。
- Container 内では main process が PID 1 として見える。
- Container の停止と signal は関係している。

Docker 自体の操作方法、namespace、cgroups、Container runtime の内部実装は、この Unit の対象外とする。

### この Unit で扱わない詳細

この Unit では、Shell Script の理解に必要な実行モデルの土台までを扱う。  
以下は対象外とする。

- Kernel 内部
- scheduler
- context switch の詳細
- system call の内部実装
- thread programming

これらを知らなくても、今回扱う process、command 実行、exit status、signal、environment の基本的な関係は理解できる。

## 使用するもの

この Unit では、主に以下を利用する。

- WSL 2 上の Linux
- Bash
- `ps`
- `sleep`
- `type`
- `command`
- `jobs`
- `wait`
- `true`
- `false`
- `mktemp`
- `cat`
- `chmod`
- `rm`
- `rmdir`
- `env`
- `grep`
- `kill`

追加 package や外部 library は使用しない。  
一部の Script では `chmod` を利用するが、permission や executable permission の詳細は Unit 02 で扱う。

## 事前準備

Unit 01 開始前の環境構築・事前準備が完了していることを前提とする。  
Bash が利用できることを確認する。

```bash
bash --version
```

リポジトリ root から Unit 01 へ移動する。

```bash
cd units/01-linux-shell-execution-model
```

成果物を確認する。

```bash
find . -maxdepth 3 -type f | sort
```

以下の構成になっていることを確認する。

```text
01-linux-shell-execution-model/
├─ README.md
└─ examples/
   ├─ command-execution/
   │  ├─ 01-builtin-external.sh
   │  ├─ 02-path-lookup.sh
   │  └─ 03-foreground-background.sh
   ├─ environment/
   │  ├─ 01-variable-inheritance.sh
   │  ├─ 02-child-cannot-change-parent.sh
   │  ├─ 03-subshell.sh
   │  └─ 04-source-target.sh
   ├─ exit-status/
   │  ├─ 01-exit-status.sh
   │  └─ 02-last-command-status.sh
   ├─ process/
   │  ├─ 01-program-process.sh
   │  ├─ 02-parent-child.sh
   │  ├─ 03-shell-process-info.sh
   │  └─ 04-process-thread-view.sh
   └─ signal/
      └─ 01-signal-target.sh
```

この Unit では、Script 内で実際に実行される command や variable 展開後の値を確認するため、一部の Script を `bash -x` で実行する。  
`bash -x` では、Bash が実行する command が `+` から始まる trace として主に stderr へ出力される。Script のソースコードをそのまま表示する機能ではなく、実行時に展開された command を追跡するための機能である。  
debugging 機能としての詳細や注意点は Unit 04 で扱うため、この Unit では「実行過程を観察する方法」として利用する。

## 学習・実践

### Process の実行モデルを確認する

まず、同じ program から複数の process が実行される様子を確認する。

```bash
bash -x examples/process/01-program-process.sh
```

この Script では、同じ `sleep` program を 2 回 background で起動している。  
`first_pid` と `second_pid` に異なる PID が入り、`ps` でも別の process として表示されることを確認する。  
「同じ program を使っていること」と「同じ process であること」は別であり、program と process の違いを実行結果から確認する。

続いて、parent process と child process の関係を確認する。

```bash
bash -x examples/process/02-parent-child.sh
```

現在の Bash から別の Bash を起動し、`ps` の PID / PPID を比較する。  
child Bash の PPID が parent Bash の PID と対応していることを確認する。  
また、`$!` に直前に background で起動した process の PID が入ることも trace から確認する。

Shell 自体が process として動いていることも確認する。

```bash
bash examples/process/03-shell-process-info.sh
```

`$$`、`$BASHPID`、`$PPID` と `ps` の結果を比較する。  
この Script の top level では `$$` と `$BASHPID` が同じ値として見えることが多いが、後で subshell を実行すると違いを観察できる。

最後に、process と thread の見え方を確認する。

```bash
bash examples/process/04-process-thread-view.sh
```

`ps -T` では、指定した process に属する thread を表示できる。  
今回の Bash が一つの thread で動作している場合、PID と SPID が同じ値として表示される。ここでは複数 thread を作るのではなく、Linux が process と thread を別の識別情報で扱えることを確認する。

### Shell による command の解決と実行を確認する

Shell builtin と external command の違いから確認する。

```bash
bash examples/command-execution/01-builtin-external.sh
```

`type` の結果から、`cd`、`printf`、`export` が Bash builtin として扱われること、`ls`、`sleep`、`ps` が external command として解決されることを確認する。  
`command -v` の結果も比較し、builtin の場合と external command の場合で表示される内容が異なることを見る。

次に、`PATH` を利用した command 探索を確認する。

```bash
bash -x examples/command-execution/02-path-lookup.sh
```

Script 内では、一時 directory に `unit01-hello` という executable file を作り、その directory を `PATH` の先頭へ追加している。  
`command -v unit01-hello` で探索結果を確認し、absolute path を指定せず `unit01-hello` という command 名だけで実行できることを確認する。

この Script では、一時的に作成した file を executable にするため `chmod +x` を利用している。  
ここでは「実行できる状態にするために必要な操作」として使用し、permission の仕組み自体は Unit 02 で扱う。

続いて、foreground / background と job control の基本を確認する。

```bash
bash -x examples/command-execution/03-foreground-background.sh
```

最初の `sleep 1` は foreground で実行されるため、終了するまで次へ進まない。  
次の `sleep 2 &` は background で開始され、Shell はその終了を待たず `background_pid=$!`、`jobs -l` などへ進む。

`bash -x` の trace は background process と parent Shell から並行して出力されるため、source code と完全に同じ見た目の順序で trace が並ばない場合がある。  
これは background で処理が並行して進んでいることによるもので、`&` を付けた処理を Shell が同期的に最後まで待っているわけではないことともつながる。

`jobs -l` では現在の Shell が管理している job を確認し、最後に `wait` で background process の終了を待つ。  
`wait` の exit status が `0` になっていることも確認する。

### Exit Status を確認する

command が終了時に返す exit status を確認する。

```bash
bash -x examples/exit-status/01-exit-status.sh
```

`true`、`false`、`exit 7` の結果が、それぞれ variable に保存される過程を trace で確認する。  
最終的な出力から、成功時の `0` と non-zero の違い、さらに non-zero が `1` に固定されているわけではないことを見る。

続いて、`$?` が直前の command の結果だけを表すことを確認する。

```bash
bash -x examples/exit-status/02-last-command-status.sh
```

`false` の直後では non-zero の値を取得できるが、その後に `printf` が正常終了すると、次の `$?` は `printf` の結果である `0` になる。  
確認したい command の exit status は、その command の直後に取得する必要があることを実行結果から理解する。

### Signal と process 終了を確認する

signal は、学習用の `01-signal-target.sh` だけを対象として確認する。  
用途が分からない system process や他の process へ `kill` を実行しない。

まず Terminal A で以下を実行する。

```bash
bash examples/signal/01-signal-target.sh
```

以下のように、この Script を実行している Bash の PID が表示される。

```text
PID=<PID>
```

#### `SIGINT`

最初は Terminal A で `Ctrl + C` を入力する。  
`received SIGINT` が表示されて Script が終了することを確認する。

Terminal で foreground process に対して `Ctrl + C` を入力する操作と `SIGINT` が関係していること、Bash の `trap` で受信時の処理を定義できることを見る。

#### `SIGTERM`

再度 Terminal A で Script を起動し、表示された PID を確認する。

```bash
bash examples/signal/01-signal-target.sh
```

別の Terminal B から、表示された PID に対して以下を実行する。

```bash
kill -TERM <PID>
```

Terminal A に `received SIGTERM` が表示されて終了することを確認する。  
`SIGTERM` は process 側で捕捉できるため、終了前に処理を行えることを見る。

#### `SIGKILL`

もう一度 Terminal A で Script を起動し、表示された PID を確認する。  
Terminal B から以下を実行する。

```bash
kill -KILL <PID>
```

この場合は `received ...` のような `trap` の出力は行われず、process が強制終了する。  
Script には `SIGKILL` 用の `trap` がないのではなく、`SIGKILL` 自体を process 側で捕捉できないことが理由である。

この実践を通して、`kill` は「常に強制終了する command」ではなく、指定した signal を process へ送る command であることを確認する。

### Variable・Environment・実行 Context を確認する

まず、Shell variable と child process の environment の違いを確認する。

```bash
bash -x examples/environment/01-variable-inheritance.sh
```

`UNIT01_SHELL_ONLY` と `UNIT01_EXPORTED` を現在の Shell で定義した後、最初の child Bash から `env` を確認する。  
この段階ではどちらも export されていないため、`UNIT01_` で始まる値は child process の environment から確認できない。

その後 `export UNIT01_EXPORTED` を実行してから別の child Bash を起動すると、今度は `UNIT01_EXPORTED` が environment から確認できる。  
現在の Shell に variable が存在することと、child process へ environment として渡されることは別であると確認する。

Script 内の `grep` は一致しない場合に exit status `1` を返すため、ここでは `|| true` によって child Bash 全体の結果を成功扱いにしている。  
`||` を利用した制御の詳細は後続 Unit で扱うため、ここでは「一致しないこと自体が今回の正常な観察結果であるため、実行結果を単純にしている」と捉えればよい。

次に、child process 側の変更が parent process へ戻らないことを確認する。

```bash
bash -x examples/environment/02-child-cannot-change-parent.sh
```

parent 側で `UNIT01_DIRECTION='parent value'` を export し、child Bash で `child value` へ変更する。  
child 内では変更後の値が出力される一方、child が終了した後の parent 側では `parent value` のままであることを確認する。

environment の継承は、parent から child へ「同じ variable を共有する」というより、child が起動するときに environment が渡されるものとして捉えると理解しやすい。  
その後 child が自分の状態を変更しても、parent の状態を直接書き換えているわけではない。

続いて subshell を確認する。

```bash
bash -x examples/environment/03-subshell.sh
```

subshell の中では `UNIT01_SUBSHELL_VALUE` を変更し、working directory を `/tmp` へ変更している。  
subshell 内では変更後の値が確認できるが、subshell 終了後の parent Shell では variable と working directory の両方が元の状態であることを見る。

同時に `$$` と `$BASHPID` を比較する。  
`$$` は parent と subshell で同じ値として表示される一方、`$BASHPID` は subshell 内で別の値になる。この違いから、subshell が別の Bash execution context で動作していることを観察する。

最後に、通常実行と `source` の違いを確認する。  
この確認は、現在操作している Bash の状態が変わることを観察するため、`bash -x` ではなく順番に command を実行する。

最初に学習用 variable が現在の Shell に残っていない状態にする。

```bash
unset UNIT01_SOURCE_VALUE
```

通常実行する。

```bash
bash examples/environment/04-source-target.sh
```

現在の Shell から値を確認する。

```bash
printf 'current shell=%s\n' "${UNIT01_SOURCE_VALUE-<unset>}"
```

以下のように `<unset>` となることを確認する。

```text
current shell=<unset>
```

次に同じ file を `source` する。

```bash
source examples/environment/04-source-target.sh
```

再度、現在の Shell から値を確認する。

```bash
printf 'current shell=%s\n' "${UNIT01_SOURCE_VALUE-<unset>}"
```

今度は以下の値が確認できる。

```text
current shell=set-by-source-target
```

確認後、学習用 variable を削除する。

```bash
unset UNIT01_SOURCE_VALUE
```

通常実行では別の Bash process で variable が設定されるため parent Shell に残らず、`source` では現在の Shell 自身で file の内容が実行されるため値が残る。  
これは単に「environment variable が child から parent へ戻るか」という話ではなく、そもそも `source` では別 child process を作って同じ方法で実行しているわけではないという違いである。

### Docker Container とのつながりを整理する

ここまでの実践で確認した process と signal の考え方は、Docker Container の動作にもつながる。  
この Unit では Docker command を実行せず、以下の関係だけ整理する。

```text
Container
└─ main process
   └─ Container 内では PID 1
```

Container の中でも Linux process が動いており、中心となる main process が存在する。  
Container 内から見ると main process は PID 1 となり、その process の終了は Container の実行状態と強く関係する。

また、Container を停止するときにも signal が関係する。  
この Unit で確認した `SIGTERM` のような終了要求を Application が適切に扱えることは、Container 内の process が必要な終了処理を行うことにもつながる。

ここでは Docker の操作方法や内部実装を覚える必要はない。  
「Container も Linux process と signal の考え方の延長上にある」と捉えることを目的とする。

## 実行・確認ポイント

### Program / Process / Thread

- program は実行内容そのもので、process は program が実行中になった状態である。
- 同じ program から複数の process を起動でき、それぞれ別の PID を持つ。
- child process の PPID から parent process との関係を確認できる。
- Bash 自体も PID を持つ process として動いている。
- thread は process 内部の実行単位であり、process と同じ概念ではない。

### Shell と command 実行

- Shell builtin と external command は、同じ「command」という見た目でも実体が異なる。
- `type` と `command -v` で、Shell が command 名をどのように解決するか確認できる。
- `PATH` に directory を追加すると、absolute path を書かずに executable file を探索できる。
- foreground では command の終了を待ち、background では `&` によって終了を待たず次へ進める。
- `$!`、`jobs`、`wait` が background execution と関係している。
- job と process は関連するが同じ概念ではない。

### Exit Status

- 基本的に `0` は成功、non-zero は失敗やその他の状態を表す。
- non-zero は `1` だけではなく、別の値も利用される。
- `$?` は直前に実行した command の exit status である。
- 別の command を実行すると `$?` はその結果へ更新される。

### Signal

- signal は process へイベントや要求を伝える仕組みである。
- `Ctrl + C` と `SIGINT` が関係している。
- `SIGINT` と `SIGTERM` は process 側で捕捉できる。
- `SIGKILL` は process 側で捕捉できない。
- `kill` は指定した signal を process へ送る command である。

### Variable / Environment / Execution Context

- Shell に variable を定義しただけでは、通常 child process の environment には渡らない。
- `export` した variable は、後から起動する child process へ渡される。
- child process が自分の値を変更しても parent process の値は変わらない。
- subshell 内の variable や working directory の変更は、終了後の parent Shell に基本的に残らない。
- subshell では `$$` と `$BASHPID` が同じ挙動をしない。
- `bash script.sh` と `source script.sh` では、file を実行する context が異なる。

### Docker との接続

- Container の中でも process が動作している。
- Container には main process が存在する。
- Container 内では main process が PID 1 として見える。
- Container の停止と process への signal は関係している。

## 学習ポイント

### Shell は process を操作する外部の存在ではなく、自身も process である

Terminal から見ると、Shell は Linux の command を操作するための入口のように見える。  
しかし今回 `BASHPID` や `ps` を確認したように、Bash 自体も Linux 上で動作する一つの process である。

その Bash が別の program を実行し、child process を作り、その終了を待ち、exit status を受け取る。  
この視点を持つと、Shell Script は単なる command の羅列ではなく、「一つの process が他の process を起動・監視しながら処理を進めるもの」として見られるようになる。

後続 Unit で background process、`trap`、batch、Application 起動、Docker などを扱うときにも、この捉え方が土台になる。

### Program・process・thread は異なるレイヤーの概念として整理する

`01-program-process.sh` では、一つの `sleep` program から PID の異なる二つの process を起動した。  
この結果から、program と process を同一視しないことが重要である。

```text
program
↓ 実行される
process
↓ 内部で処理を進める
thread
```

program は保存されている実行内容、process は実行中の instance、thread はその process 内部の実行単位である。  
今回は thread を操作していないが、用語をこの階層で区別できれば十分である。

### Command の実行前には「何を実行するか」の解決がある

Shell で `cd` や `ls` と入力すると、見た目上はどちらも command を一つ実行している。  
しかし `type` の結果で確認したように、一方は Shell builtin、もう一方は external command であり、実体は異なる。

external command ではさらに `PATH` を使って executable file を探すという段階がある。  
今回の実践を一つの流れとしてまとめると、以下のように整理できる。

```text
command 名
↓
Shell が種類・実体を解決
↓
external command なら PATH から探索
↓
program を process として実行
↓
終了
↓
exit status を Shell が受け取る
```

この流れを理解しておくと、「command が見つからない」「同名の別 command が実行された」「別環境だけ動かない」といった問題も、単なる暗記ではなく command resolution の問題として考えられる。

### Job control は「process を background にした」だけでは終わらない

`&` を付けると Shell は command の終了を待たず次へ進める。  
一方で Bash は、その background execution を job として管理し、`jobs` や `wait` から扱える。

ここでは process と job を完全に同じものとして捉えないことが重要である。  
process は Linux が管理する実行単位であり、job は Shell が command execution を管理するための概念である。

`bash -x` の trace が background process の実行によって前後して見える場合があることも、複数の処理が同じ順番で同期的に進んでいるわけではないことを観察する一例になる。

### Exit Status は人間向けの表示とは別の「処理結果の interface」である

command が stdout に何を表示したかと、その command が成功したかどうかは別の情報である。  
Shell が後続処理を判断するときには、主に exit status を利用する。

```text
人間が見る結果
→ stdout / stderr

Shell が処理判断に使う結果
→ exit status
```

もちろん実際には stderr と失敗が必ず一対一になるわけではないが、まずこの役割の違いを持っておくと整理しやすい。  
後続 Unit で `if`、`&&`、`||`、error handling、ShellCheck、CI workflow などを扱うときにも、command の成否が exit status で伝わることが前提になる。

### Signal では「終了を依頼すること」と「強制的に止めること」を区別する

`SIGTERM` と `SIGKILL` は、どちらも最終的には process の終了につながり得るが、意味は同じではない。  
`SIGTERM` は process 側が受け取り、必要な処理を行って終了できる。一方、`SIGKILL` は process 側で捕捉できず、終了前の cleanup の機会もない。

そのため、process を停止するときに最初から強制終了だけを考えるのではなく、まず正常な終了機会を与えるという考え方が重要になる。  
この違いは Server Application、batch、Docker Container などの停止処理を理解するときにも再登場する。

### Environment の継承は parent から child への方向で考える

`export` の実践では、parent Shell に存在する variable のうち export されたものだけが child Bash の environment から確認できた。  
さらに child 側で値を書き換えても、parent 側の値は変化しなかった。

この関係は以下のように整理できる。

```text
parent
  ↓ environment を渡す
child

child で変更
  ×
parent の状態を直接変更するわけではない
```

「親子 process が同じ environment variable を共有している」と考えるより、child が起動するときに environment を受け取ると考える方が、今回の挙動を説明しやすい。

### Subshell と `source` は「どの execution context を変更しているか」で理解する

subshell の中で variable や working directory を変更しても、parent 側には残らなかった。  
通常の `bash script.sh` も別の Bash process で実行されるため、そこで行った variable の変更は現在の Shell に残らない。

一方、`source` では現在の Shell 自身が file の内容を実行するため、variable の変更がそのまま現在の Shell に残る。

```text
別 process / subshell
→ その execution context の状態を変更
→ parent には基本的に残らない

source
→ 現在の Shell の状態を直接変更
→ 変更が残る
```

`source` を「child process から parent へ値を戻す特殊な方法」と捉えるのではなく、「そもそも別 process で実行していない」と理解することが重要である。

### Docker の process・PID 1・signal も Linux の基本概念からつながる

Docker Container を学ぶと、main process、PID 1、stop signal などの言葉が登場する。  
これらは Docker 独自の暗記事項として切り離すのではなく、今回学んだ Linux process と signal の延長で捉えることができる。

Container の中にも process があり、main process が終了することは Container の実行状態と強く関係する。  
また、Container 停止時に Application が終了要求を適切に扱えるかどうかも signal と関係する。

この Unit で Docker 操作を行わないのは、まず Linux / Shell 側の実行モデルを理解し、その後に Container の動作を同じ概念から理解できるようにするためである。
