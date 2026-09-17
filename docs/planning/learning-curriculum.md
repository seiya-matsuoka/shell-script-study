# Shell Script Study - Learning Curriculum

## 1. 学習目的

本リポジトリでは、Shell Script について体系的に学習し、汎用的・基本的な内容であれば、必要に応じて調べながら安全に読み書きできるための土台を身につけることを目的とする。

単に Bash の構文や Linux コマンドを暗記するのではなく、Shell Script が Linux 上でどのように実行されるか、標準入出力・プロセス・環境変数・権限・終了ステータスなどの仕組みを理解し、その上で実務で頻出するパターン、安全な書き方、品質管理、自動テスト、外部システムとの連携、CI/CD での利用まで段階的に学ぶ。

学習ではコードリーディングを中心としつつ、実際に Script を実行し、stdout / stderr、終了ステータス、生成ファイル、API レスポンス、テスト結果などを確認することで、コードと実際の挙動を結び付けて理解する。  
また、正しい書き方だけでなくアンチパターンも確認し、「なぜその書き方が推奨されるのか」「どのような場合に問題が起きるのか」まで理解することを重視する。

## 2. 到達目標

本カリキュラム完了時に、以下の状態を目指す。

- Shell Script が Linux 上でどのように実行されるか、プロセス・標準入出力・環境変数・終了ステータスなどの基本概念と関連付けて説明できる。
- Bash Script の基本構文、変数、引数、展開、クォート、条件分岐、ループ、関数などを読んで理解できる。
- 汎用的・基本的な Shell Script であれば、必要に応じて調べながら安全に作成・修正できる。
- Shell Script で起こりやすいクォート漏れ、word splitting、glob、エラー処理不足などの問題を理解し、安全な書き方を選択できる。
- exit status、`set -euo pipefail`、`trap`、cleanup、入力検証、再実行性など、堅牢な Script を作るための基本的な観点を理解できる。
- `grep`、`sed`、`awk`、`find`、`xargs` などを、単独コマンドとしてではなく Shell Script の中で組み合わせて利用する代表的なパターンを理解できる。
- `curl` と `jq` を利用した基本的な HTTP / API / JSON 処理を理解できる。
- cron などで定期実行される Script に必要な logging、終了ステータス、PATH、再実行性、二重実行対策などの基本的な設計観点を理解できる。
- shfmt と ShellCheck の役割を理解し、Shell Script の format と static analysis を実行できる。
- Bats を利用して、Shell Script に対する基本的な自動テストを読み書きし、正常系・異常系・出力・終了ステータスなどを確認できる。
- Shell Script から API、DB、Docker Container、Application などを操作・連携する基本的なイメージを持てる。
- CI/CD の基本的な流れを理解し、ShellCheck や Bats などの品質確認が CI の中でどのように利用されるか説明できる。
- Shell Script が適している処理と、Python など別の言語を選択した方がよい処理を大まかに判断できる。

## 3. 学習方針

### 3.1 Bash を主軸とする

本カリキュラムでは Bash を主軸として学習する。

POSIX `sh` を別体系として深く学ぶことはしないが、`[[ ]]`、array、`local` など Bash 固有の機能については、必要に応じて `sh` との違いを補足する。

### 3.2 Linux の重要概念も扱う

Shell Script の構文だけを切り離して学習せず、以下のような Linux / Shell の重要概念を関連付けて扱う。

- プロセス
- 標準入力・標準出力・標準エラー
- file descriptor
- signal
- 環境変数
- PATH
- ファイル・ディレクトリ
- 権限
- 終了ステータス

ただし、`ls`、`cp`、`mv` などの単純な基本コマンドを最初から学び直すことは目的としない。

### 3.3 コードリーディングを起点に実行・検証する

コードリーディングは、Script の内容を見るだけではなく、以下まで含めた学習とする。

1. コードの目的と処理内容を確認する。
2. 実際に Script やコマンドを実行する。
3. stdout / stderr / exit status / 生成ファイルなどを確認する。
4. 必要に応じて入力や条件を変更して再実行する。
5. コードと実際の挙動を結び付けて理解する。

概念中心の Unit でも、可能な限り実際に動作・観察できる Script やコマンドを用いて確認する。

### 3.4 小さな基本形から発展させる

最初から複雑な Script を扱わず、以下の流れを基本とする。

1. 最小限の基本形
2. 少し現実的な例
3. 複数の要素を組み合わせた例
4. 実務を意識した利用例

### 3.5 アンチパターンと改善例を扱う

安全性や品質に関係する重要なテーマでは、必要に応じて以下の流れで学習する。

1. 単純な実装
2. 問題のある書き方・アンチパターン
3. 問題が発生する条件
4. 問題の理由
5. 改善版
6. 必要に応じて ShellCheck や Bats による確認

正しい書き方を暗記するのではなく、その意図と理由を理解することを重視する。

### 3.6 Shell Script の適用範囲を意識する

Shell Script で実装可能かどうかだけではなく、Shell Script が適切な処理かどうかも学習対象とする。

コマンドの組み合わせ、ファイル操作、簡単なバッチ、自動化、外部コマンドの orchestration などは Shell Script が得意とする領域として扱う。

一方、複雑なデータ構造、大規模な business logic、高度な CSV / JSON 処理、複雑な error handling などは、Python など別の言語を検討する判断も扱う。

### 3.7 前の Unit の内容を後続 Unit で再利用する

各 Unit は個別のテーマを持つが、前の Unit で学んだ概念・構文・安全性の考え方を後続 Unit で再利用する。

たとえば、Unit 01 で学んだ process / signal は Unit 07 や Unit 10 で再登場し、Unit 04 で学んだ error handling は Unit 06、Unit 07、Unit 10、Unit 11 で繰り返し利用する。

## 4. Unit の重み付け

各 Unit の学習量には以下の相対的な重み付けを設ける。

### 厚め

- Unit 01
- Unit 02
- Unit 03
- Unit 04
- Unit 05

今回の学習全体を支える土台として、必要な内容をしっかり扱う。  
ただし、詳細を無制限に深掘りする意味ではなく、今回のカリキュラムにおける標準的な主要 Unit として扱う。

### やや厚め

- Unit 09
- Unit 11

今回新しく経験する自動テストや、関心のある CI/CD との接続を通常の Unit よりやや丁寧に扱う。

### 標準

- Unit 06
- Unit 07
- Unit 08
- Unit 10

必要な基礎・実用例を押さえつつ、学習全体が大規模になりすぎないよう比較的コンパクトに扱う。

この重み付けは文章量やファイル数を機械的に決めるものではなく、学習内容の重要度と必要な説明量を調整するための相対的な目安とする。

## 5. 学習対象範囲

本カリキュラムでは、主に以下を学習対象とする。

### 5.1 Linux / Shell の実行モデル

- プログラム
- プロセス
- スレッド
- PID / PPID
- 親プロセス / 子プロセス
- Shell 自体のプロセス
- Shell builtin
- 外部コマンド
- PATH
- foreground / background
- exit status
- signal
- 環境変数
- subshell
- `source`

### 5.2 標準入出力・ファイル・権限

- stdin / stdout / stderr
- file descriptor
- redirect
- pipe
- `/dev/null`
- `tee`
- absolute path / relative path
- current working directory
- symbolic link
- owner / group / others
- read / write / execute
- temporary file

### 5.3 Bash Script の基本

- shebang
- variable
- environment variable
- argument
- parameter expansion
- command substitution
- arithmetic expansion
- glob
- word splitting
- quote
- condition
- loop
- function
- `local`
- `return` / `exit`
- `printf`
- `getopts`

### 5.4 安全性・エラー処理・デバッグ

- exit status
- `set -euo pipefail`
- validation
- dependency check
- `trap`
- cleanup
- temporary file
- idempotency
- retry
- timeout
- lock
- secrets
- destructive operation
- `bash -n`
- `bash -x`
- `set -x`

### 5.5 ファイル・テキスト・ログ処理

- ファイル・ディレクトリ操作
- backup / cleanup
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
- `while read`
- log extraction / aggregation
- 単純な CSV

### 5.6 HTTP / API / JSON

- `curl`
- HTTP GET / POST
- header
- request body
- HTTP status code
- timeout
- retry
- authentication token
- JSON
- `jq`
- application health check

### 5.7 バッチ・定期実行

- batch processing
- cron
- crontab
- non-interactive execution
- PATH
- working directory
- logging
- timestamp
- exit status
- retry
- timeout
- cleanup
- idempotency
- lock
- systemd service / timer の基本

### 5.8 品質管理

- shfmt
- ShellCheck
- static analysis
- formatter
- warning の読み方
- editor / CLI / CI での利用

### 5.9 自動テスト

- Bats
- 正常系 / 異常系
- exit status
- stdout / stderr
- file creation / contents
- setup / teardown
- test isolation
- mock / stub の基本

### 5.10 外部システム連携

- PostgreSQL / `psql`
- SQL file
- CSV import
- Docker Container 操作
- Application 起動
- health check
- API / DB / Container の連携

### 5.11 CI/CD・開発運用

- CI / CD
- workflow
- job / step
- runner
- trigger
- format / lint / test
- artifact
- environment variable
- secrets
- ShellCheck / Bats と CI の連携
- GitHub Actions を利用した基本的な品質確認

## 6. 学習対象外

本カリキュラムでは、Shell Script と Linux の基礎から実用入口までを対象とし、以下は深く扱わない。

- Linux Kernel 内部の詳細
- scheduler の詳細
- context switch の詳細
- system call の内部実装
- thread programming
- ACL の詳細
- SELinux / AppArmor の詳細
- filesystem 内部構造
- POSIX Shell の体系的な学習
- 高度な Bash programming
- 高度な systemd 設定・運用
- Shell test framework の比較
- 高度な mocking
- test coverage の詳細
- Kubernetes
- Container orchestration の実践
- Infrastructure as Code の実践
- configuration management の実践
- 本格的な deployment pipeline
- release engineering
- 本格的な monitoring / alerting / observability 基盤
- 本格的な Production 向け security hardening

## 7. 学習カリキュラム

### Unit 01. Linux / Shell の実行モデル

**重み付け：厚め**

#### 目的

Shell Script や Docker、Linux Server 上の処理を理解するための前提として、Linux 上でプログラムやコマンドがどのように実行されるのかを理解する。

#### 主な学習内容

##### プログラム・プロセス・スレッド

- プログラムとは何か
- プロセスとは何か
- スレッドとは何か
- プログラムとプロセスの違い
- プロセスとスレッドの違い
- PID / PPID
- 親プロセス / 子プロセス
- Shell 自体もプロセスであること

##### Shell とコマンド実行

- Shell が外部コマンドを実行する基本的な流れ
- Shell builtin
- 外部コマンド
- builtin と外部コマンドの違い
- `PATH` によるコマンド探索
- foreground / background
- `&`
- `jobs`
- `wait`

##### 終了ステータス

- command の成功・失敗
- exit status
- `0` と non-zero
- `$?`

##### signal

- signal の役割
- `SIGINT`
- `SIGTERM`
- `SIGKILL`
- `kill`
- process 終了との関係

##### 変数・環境・実行コンテキスト

- Shell variable
- environment variable
- `export`
- 子プロセスへの環境変数の継承
- subshell
- `source`
- Script を別 process で実行する場合と `source` する場合の違い

#### 軽く扱う内容

- Docker Container と process の関係
- Container の main process
- PID 1
- Container 停止時の signal

Docker 自体の操作方法はこの Unit の学習対象にはしない。

#### 対象外

- Kernel 内部
- scheduler
- context switch の詳細
- system call の内部実装
- thread programming

#### 到達状態

Shell からコマンドを実行したときに Linux 上で何が起きているのかを、process、親子関係、exit status、environment などの概念を使って大まかに説明できる。

### Unit 02. 標準入出力・パイプ・ファイル・権限

**重み付け：厚め**

#### 目的

Shell Script の根幹となる Linux の入出力モデルと、ファイル・パス・権限の仕組みを理解する。

#### 主な学習内容

##### 標準入出力

- stdin
- stdout
- stderr
- file descriptor
- stdin = `0`
- stdout = `1`
- stderr = `2`

##### redirect

- `>`
- `>>`
- `<`
- `2>`
- `2>>`
- `2>&1`
- redirect の順序
- `/dev/null`
- `tee`

##### pipe

- `|`
- stdout と stdin の接続
- pipeline 内で複数 process が動くこと
- pipeline の終了ステータス
- `pipefail`

##### ファイル・パス

- absolute path
- relative path
- current working directory
- regular file
- directory
- symbolic link
- hidden file
- executable file
- 空白などを含む filename を扱う際の注意点

##### 権限

- owner
- group
- others
- read
- write
- execute
- `chmod`
- numeric notation
- symbolic notation
- Shell Script の execute permission
- `./script.sh` と `bash script.sh` の違い

##### temporary file

- `/tmp`
- temporary file / directory
- `mktemp`

#### 軽く扱う内容

- `umask`
- here document
- here string
- `0 / 1 / 2` 以外の file descriptor の存在

#### 対象外

- ACL
- SELinux
- AppArmor
- filesystem 内部構造

#### 到達状態

redirect や pipe を記号として暗記するのではなく、stdin / stdout / stderr と file descriptor の関係から基本的な挙動を説明できる。

### Unit 03. Bash Script の基本と Shell 展開

**重み付け：厚め**

#### 目的

過去に学習した Bash の基本を改めて整理し、実用的な Shell Script を正しく読むための基礎を作り直す。

#### 主な学習内容

##### Script の基本

- shebang
- `#!/usr/bin/env bash`
- Bash Script の実行
- comment
- `exit`

##### 変数

- Shell variable
- environment variable
- `export`
- `readonly`
- 代入と参照

##### 引数

- `$0`
- `$1` などの positional parameter
- `$#`
- `"$@"`
- `$?`

##### parameter expansion

- `$var`
- `${var}`
- `${var:-default}`
- `${var:?message}`

##### その他の展開

- command substitution `$()`
- arithmetic expansion `$(( ))`
- pathname expansion / glob
- word splitting
- brace expansion の基本

##### quote

- unquoted
- single quote
- double quote
- quote と variable expansion
- quote と word splitting
- quote と glob
- `"$variable"` を基本とする理由

##### 条件分岐

- `if / elif / else`
- `[ ]`
- `[[ ]]`
- string comparison
- numeric comparison
- file test
- `case`

##### loop

- `for`
- `while`
- `while IFS= read -r`

##### function

- function
- positional parameter
- `local`
- `return`
- `exit` と `return` の違い
- stdout を値として扱う場合の考え方

##### 出力

- `echo`
- `printf`
- より予測可能な出力に `printf` を使う考え方

##### option parsing

- positional argument
- option
- `getopts` の基本

##### Bash と POSIX `sh`

- Bash を主軸とする理由
- Bash 固有機能の存在
- `[[ ]]`
- array
- `local`
- `/bin/sh` では利用できない場合があること

#### 軽く扱う内容

- `$*`
- `shift`
- array
- brace expansion
- `until`
- Bash の regex 機能

#### 到達状態

頻出する Bash の構文、展開、クォート、条件分岐、ループ、関数を読んで意味を追うことができ、基本的な Script であれば必要に応じて調べながら理解できる。

### Unit 04. 安全な Shell Script・エラー処理・デバッグ

**重み付け：厚め**

#### 目的

正常系で動くだけの Script ではなく、不正入力、command failure、異常終了、再実行などを考慮した安全で堅牢な Script の基本を理解する。

#### 主な学習内容

##### command failure と exit status

- exit status
- `exit`
- `return`
- `&&`
- `||`
- `if command; then`
- command failure を明示的に扱う考え方

##### `set`

- `set -e`
- `set -u`
- `set -o pipefail`
- `set -euo pipefail`
- strict mode と呼ばれる書き方
- `set -e` の注意点
- `set -euo pipefail` を指定すれば自動的に安全になるわけではないこと

##### validation

- required argument
- option
- numeric value
- file
- directory
- environment variable
- dependency
- `command -v`

##### cleanup

- `trap`
- `EXIT`
- signal
- cleanup function
- temporary file
- `mktemp`
- 異常終了時にも cleanup する考え方

##### 再実行性

- idempotency
- 既存状態を考慮した処理
- 重複処理を避ける考え方
- partial failure
- 中途半端に失敗した状態からの再実行

##### 二重実行

- 同じ batch / Script が重複して動く問題
- lock の考え方
- `flock` の基本

##### 外部処理の失敗

- timeout
- retry
- retry 回数
- `sleep`
- 単純な backoff の考え方

##### 安全なファイル・コマンド操作

- quote
- `--`
- wildcard
- 空文字
- destructive operation
- 意図しない `rm`
- working directory の確認
- relative path 依存の危険性

##### secrets

- password / token を Script に hard-code しない
- environment variable
- file
- CI secrets
- `set -x` で秘密情報が出力される危険

##### デバッグ

- `bash -n`
- `bash -x`
- `set -x`
- `set +x`
- debug output
- 問題箇所を段階的に切り分ける考え方

#### 軽く扱う内容

- `flock` の高度な利用
- retry の高度な backoff 戦略

#### 学習上の重点

この Unit では、アンチパターン、問題が発生する入力、改善版を比較し、単に安全な書き方を暗記するのではなく、その理由を理解する。

#### 到達状態

基本的な Shell Script について、正常に動くかだけでなく、どのように失敗する可能性があるかを考え、代表的な対策を判断できる。

### Unit 05. ファイル・テキスト・ログ処理の頻出パターン

**重み付け：厚め**

#### 目的

Shell Script で頻繁に行われるファイル・テキスト・ログ処理について、多数の小さな実用パターンを通して理解する。

#### 主な学習内容

##### Script の入口

- argument validation
- dependency check
- environment check
- configuration loading
- working directory の確定

##### ファイル・ディレクトリ処理

- file existence
- directory existence
- directory creation
- file loop
- copy / move
- backup
- archive の基本
- cleanup
- file timestamp を利用した処理
- temporary file / directory

##### テキスト処理

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

個々の command を単独で暗記するのではなく、目的に対して複数の command を組み合わせて利用する。

##### ファイル探索

- `find`
- `-exec`
- `xargs`
- `while read`
- 空白を含む filename
- null delimiter

##### ログ処理

- ERROR 行などの抽出
- 件数集計
- grouping
- 日付による絞り込み
- log file の解析
- Script 自身の logging

##### CSV

- 単純な CSV
- `IFS`
- `read`
- CSV のデータを別処理へ受け渡す
- quoted comma や multiline を含む複雑な CSV を単純な Bash 処理で扱う危険性

##### Shell Script の適用判断

- Shell が向いている処理
- Shell で実装可能でも別言語が適している処理
- 複雑な CSV / data processing を Python 等へ任せる判断

#### 到達状態

基本的なファイル・テキスト・ログ処理について、複数の Linux command を組み合わせた Shell Script を読み、処理の流れを理解できる。

### Unit 06. HTTP / API / JSON の実用パターン

**重み付け：標準**

#### 目的

Shell Script を外部サービスと連携させる代表的な例として、HTTP / API / JSON を扱う。

#### 主な学習内容

##### HTTP / API

- HTTP の最低限の理解
- `curl`
- GET
- POST
- request header
- request body
- response
- HTTP status code

##### failure handling

- connection failure
- HTTP error
- timeout
- retry
- exit status

##### authentication

- authentication token
- environment variable
- token を Script に直接記載しない
- token を log へ出力しない

##### JSON

- `jq`
- property 取得
- array
- filter
- Shell variable との連携

##### Application

- health check
- API response を利用した状態確認
- 起動完了の判定

#### 対象外

- HTTP protocol の詳細
- OAuth 等の認証方式の詳細
- 高度な `jq` programming

#### 到達状態

API を呼び出し、JSON response から必要な値を取得し、その結果に応じて別の処理へつなげる基本的な Shell Script を理解できる。

### Unit 07. バッチ・cron・定期実行と運用設計

**重み付け：標準**

#### 目的

人間が手動で実行する Script と、cron などから無人で定期実行される Script の違いを理解する。

#### 主な学習内容

##### batch processing

- batch processing の基本的な位置づけ
- 対話操作に依存しない Script
- unattended execution

##### cron

- cron
- crontab
- schedule syntax
- cron daemon
- user crontab

##### 実行環境

- cron の environment
- PATH
- working directory
- absolute path
- environment variable

##### logging

- stdout
- stderr
- log file
- timestamp
- log level の基本
- 後から原因を追跡できる出力

##### 運用を意識した Script

- exit status
- retry
- timeout
- cleanup
- idempotency
- partial failure
- 二重実行
- lock

##### systemd

- service
- timer
- cron との大まかな違い
- process supervision
- restart の考え方

#### 到達状態

定期実行される Shell Script について、単に cron へ登録するだけでなく、PATH、logging、exit status、再実行性、二重実行などの基本的な運用上の注意点を説明できる。

### Unit 08. shfmt / ShellCheck とコード品質

**重み付け：標準**

#### 目的

Shell Script の formatter と static analysis を、エディタの便利機能ではなく品質管理の仕組みとして理解する。

#### 主な学習内容

##### shfmt

- formatter の役割
- formatting と static analysis の違い
- CLI での実行
- editor integration
- format
- format check
- local と CI で同じ formatter を利用する意味

##### ShellCheck

- static analysis
- syntax error との違い
- warning
- quote に関する問題
- word splitting
- glob
- unused variable
- error-prone pattern
- warning message の読み方
- 必要な場合の suppression
- CLI
- editor integration
- CI での利用

#### 学習上の重点

問題のある Shell Script に ShellCheck を実行し、warning の意味を理解して改善する流れを扱う。

#### 到達状態

shfmt と ShellCheck の役割の違いを説明でき、ShellCheck の代表的な warning について原因を理解して基本的な修正ができる。

### Unit 09. Bats による Shell Script の自動テスト

**重み付け：やや厚め**

#### 目的

Shell Script に対してもテストコードを書き、自動的に期待する動作を確認できることを理解・経験する。

#### 主な学習内容

##### 自動テストの基本

- Shell Script に対して自動テストを書く目的
- Bats
- `.bats`
- `@test`
- `run`
- `$status`
- `$output`
- `$lines`

##### テストケース

- 正常系
- 異常系
- argument validation
- exit status
- stdout
- stderr
- file creation
- file contents
- command failure

##### テスト環境

- `setup`
- `teardown`
- temporary directory
- test isolation
- test fixture の基本

##### テストしやすい Script

- 大きな main 処理
- function 分割
- side effect
- dependency
- テストしやすい構造を意識する理由

##### 外部依存

- mock の考え方
- stub の考え方
- fake command
- `PATH` 差し替え
- `curl` などの外部 command を毎回実行せずにテストする基本的な方法

#### 対象外

- Bats 以外の test framework 比較
- 高度な mocking
- coverage の詳細

#### 到達状態

基本的な Shell Script に対して、正常系・異常系、exit status、stdout / stderr、file などを確認する Bats のテストコードを読み、基本形であれば自分でも作成できる。

### Unit 10. DB / Docker / Application との連携

**重み付け：標準**

#### 目的

これまで学んだ Shell Script を、DB、Docker Container、Application など実際のシステムに近い対象へ接続し、Shell Script が複数の仕組みをつなぐ用途で利用されることを理解する。

#### 主な学習内容

##### PostgreSQL

- `psql`
- connection information
- environment variable
- SQL file
- SQL 実行
- CSV import
- exit status
- failure handling

代表的な題材として、以下のような流れを扱う。

```text
CSV
↓
Shell Script
↓
PostgreSQL
```

##### Docker

Docker 自体の学習を目的とせず、Shell Script から操作する対象として扱う。

- Container 起動
- Container status
- log
- `docker exec`
- Docker Compose の基本的な操作
- command の exit status

##### Application

- Application 起動
- 起動完了待ち
- health check
- API call
- DB との連携
- failure 時の終了

##### 統合

以下のような複数の処理を Shell Script からつなぐ基本的な例を扱う。

```text
Docker / Application 起動
↓
起動完了待ち
↓
Health Check
↓
API
↓
DB
```

#### 到達状態

Shell Script が、DB、Container、Application など複数の command や system をつなぐ glue として利用される基本的なイメージを持てる。

### Unit 11. CI/CD と Shell Script の実務的な統合

**重み付け：やや厚め**

#### 目的

Shell Script が実際の開発工程や自動化の中でどのように利用されるかを理解し、これまで学んだ品質確認を CI に接続する。

#### 主な学習内容

##### CI/CD の基本

- CI
- CD
- pipeline / workflow
- trigger
- runner
- job
- step
- format
- lint
- test
- build
- artifact
- deploy の位置づけ

##### Shell Script と CI

- command と exit status
- step success / failure
- job success / failure
- workflow success / failure
- Shell Script の exit status が CI の結果へつながること

##### GitHub Actions

基本的な実例として、以下のような品質確認を扱う。

```text
Push / Pull Request
↓
GitHub Actions
↓
shfmt
↓
ShellCheck
↓
Bats
↓
Success / Failure
```

##### Environment / Secrets

- environment variable
- CI secrets
- local environment と CI environment の違い
- token / password
- secrets を log へ出力しない

##### 周辺領域

以下は実践対象にはせず、開発・運用自動化の全体像を理解するために存在と役割を確認する。

- deployment automation
- configuration management
- Infrastructure as Code
- container
- orchestration
- job scheduler
- logging
- monitoring / alerting

#### 対象外

- Kubernetes の実践
- Infrastructure as Code の実践
- 本格的な deployment pipeline
- release engineering
- observability 基盤構築

#### 到達状態

CI/CD の基本的な流れを説明でき、ShellCheck、shfmt、Bats などの Shell Script の品質確認が CI の中でどのように利用されるか理解できる。

## 8. 横断的に扱う学習内容

以下は独立した Unit だけで完結させず、必要な Unit で繰り返し扱う。

### 8.1 安全性

- quote
- validation
- error handling
- exit status
- secrets
- destructive operation
- cleanup
- idempotency

### 8.2 アンチパターン

重要なテーマでは、推奨されるコードだけでなく、問題のあるコードとその壊れ方も確認する。

必要に応じて以下の流れを用いる。

```text
単純な実装
↓
アンチパターン
↓
問題が発生する入力・条件
↓
原因確認
↓
改善版
↓
ShellCheck / Bats 等による確認
```

### 8.3 可読性・保守性

- naming
- function 分割
- `printf`
- 意図が分かる処理構造
- 適切な comment
- Script を必要以上に巨大化させない考え方

### 8.4 Linux の仕組みとの接続

後続 Unit でも、process、signal、stdin / stdout / stderr、environment、permission、exit status など、Unit 01・02 で学んだ概念へ必要に応じて立ち返る。

### 8.5 Shell Script の適用範囲

Shell Script で書けるかどうかではなく、その処理に Shell Script を選択することが適切かを考える。

- command orchestration
- file operation
- simple batch
- automation
- build / deploy の補助

などは Shell Script の代表的な用途として扱う。

複雑な data structure、大規模な business logic、高度な parser などは別言語を検討する。

### 8.6 実務との接続

各 Unit で学ぶ内容を、以下のような実務上の利用場面と関連付けて理解する。

- batch / scheduled job
- log processing
- API integration
- DB operation
- Application operation
- Docker / Container
- CI/CD

## 9. 一周完了時の到達状態

全 11 Unit 完了時には、以下の状態になっていることを目標とする。

### Linux / Shell の基礎

- program / process / thread の違いを大まかに説明できる。
- Shell が外部 command を実行する基本的な流れを理解している。
- stdin / stdout / stderr、file descriptor、redirect、pipe の関係を理解している。
- environment variable、PATH、signal、permission、exit status の基本を理解している。

### Bash Script

- Bash Script の基本構文を読める。
- variable、argument、parameter expansion、command substitution、quote などを理解している。
- condition、loop、function を利用した基本的な Script を理解できる。
- Bash と POSIX `sh` が同一ではないことを理解している。

### 安全性・堅牢性

- command failure や不正入力を考慮できる。
- `set -euo pipefail` の役割と注意点を理解している。
- `trap`、cleanup、temporary file、validation の基本を理解している。
- retry、timeout、idempotency、lock などが必要になる場面を理解している。
- secrets や destructive operation の基本的な注意点を理解している。

### 頻出パターン

- ファイル・ディレクトリ処理を含む基本的な Script を理解できる。
- `grep`、`sed`、`awk`、`find` などを組み合わせた代表的な処理を理解できる。
- log / simple CSV を処理する基本的な Script を理解できる。
- Shell Script が不向きな複雑な処理を判断する視点を持っている。

### 外部連携

- `curl` と `jq` を使った基本的な API / JSON 処理を理解できる。
- `psql` や Docker command などを Shell Script から利用する基本的な考え方を理解している。
- Application、API、DB、Container など複数の対象を Shell Script でつなぐ用途を理解している。

### バッチ・運用

- cron で定期実行する基本的な流れを理解している。
- 定期実行 Script では PATH、working directory、logging、exit status、二重実行、再実行性などを考慮する必要があることを理解している。
- systemd service / timer の大まかな役割を理解している。

### 品質

- shfmt と ShellCheck の役割を区別できる。
- ShellCheck の代表的な warning を理解し、基本的な問題を修正できる。
- Bats の基本的なテストコードを読み書きできる。
- 正常系・異常系、exit status、stdout / stderr、file などを自動テストで確認できる。

### CI/CD

- CI/CD の基本的な流れを理解している。
- command の exit status と CI の success / failure の関係を理解している。
- shfmt、ShellCheck、Bats を CI で実行する基本的な流れを理解している。
- GitHub Actions を利用した基本的な Shell Script の品質確認を経験している。

本カリキュラムでは、これらを「Shell Script や Linux をすべて理解した状態」とは位置付けない。

汎用的・基本的な Shell Script であれば、必要に応じて調べながら安全に読み書きし、実務や個人開発の中で利用しながら理解を深めていくための土台ができた状態を、一周完了時の到達地点とする。
