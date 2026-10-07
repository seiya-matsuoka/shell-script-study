# Shell Script Study

<p>
  <img alt="Bash" src="https://img.shields.io/badge/Bash-Shell%20Script-4EAA25?logo=gnubash&logoColor=ffffff">
  <img alt="ShellCheck" src="https://img.shields.io/badge/ShellCheck-Quality-4EAA25">
  <img alt="shfmt" src="https://img.shields.io/badge/shfmt-Format-4EAA25">
  <img alt="Bats" src="https://img.shields.io/badge/Bats-Test-1F6FEB">
  <img alt="GitHub Actions" src="https://img.shields.io/badge/GitHub%20Actions-CI-2088FF?logo=githubactions&logoColor=ffffff">
</p>

Shell Script の基礎から、安全な実装、ファイル・ログ処理、HTTP / API、定期実行、自動テスト、DB / Docker / Application 連携、CI/CD までを体系的に学習するためのリポジトリ。  
各 Unit に学習用ドキュメントと実行可能なサンプルを配置し、コードを読み、実際に実行し、stdout / stderr、exit status、生成ファイル、process、service などの挙動を確認しながら理解を深める。  
基本的・汎用的な Shell Script を、必要に応じて調べながら安全に読み書き・修正できる状態を目標とする。

---

## このリポジトリの位置づけ

このリポジトリは、Linux CLI や Shell Script の基本に触れた後、Shell Script をもう一段体系的に学習するための `shell-script-study` である。

前半では、Linux / Shell の実行モデル、標準入出力、パイプ、ファイル、権限、Bash Script、Shell 展開、安全なエラー処理、ファイル・テキスト・ログ処理など、Shell Script を読み書きするための土台を扱う。  
中盤では、HTTP / API / JSON、batch / cron、shfmt / ShellCheck、Bats による自動テストへ進み、実用的な処理とコード品質を確認する。  
後半では、PostgreSQL、Docker、Application との連携、GitHub Actions を使った CI まで発展させ、Shell Script が複数の command や system をつなぐ glue として使われる流れを確認する。

Shell Script の高度な技巧を網羅すること、すべての POSIX Shell の差異を扱うこと、大規模な Application を Shell だけで実装することは目的としない。  
また、Kubernetes、Infrastructure as Code、本格的な deployment pipeline、release engineering、observability 基盤構築などは学習範囲に含めず、Shell Script から周辺技術へ接続するための基本を対象とする。

---

## 学習目的

このリポジトリでは、主に次の内容を目的として学習を行う。

- Shell、process、PID / PPID、foreground / background、exit status、signal など、Shell Script が動く前提を理解する
- stdin / stdout / stderr、redirection、pipe、file、permission を理解し、command 同士の入出力を安全につなげられるようにする
- variable、argument、quote、command substitution、parameter expansion、glob など Bash Script の基本を読み書きできるようにする
- validation、failure handling、`trap`、cleanup、temporary file、lock、timeout、retry など、安全に実行するための基本を理解する
- `grep` / `sed` / `awk` / `find` / `xargs` などを使い、file、text、log を実用的な形で処理できるようにする
- `curl` / `jq` を使い、HTTP / API / JSON を Shell Script から扱えるようにする
- cron / systemd timer などの定期実行を想定し、non-interactive execution、environment、logging、重複実行防止を考えられるようにする
- shfmt / ShellCheck を使い、format と static analysis を Shell Script の品質確認へ取り入れられるようにする
- Bats を使い、正常系・異常系・exit status・output・file operation・external dependency を自動テストできるようにする
- PostgreSQL、Docker、Application など複数の system を Shell Script から順番につなぐ基本を理解する
- Shell Script の exit status と、GitHub Actions の step / job / workflow の success / failure の関係を理解する
- Shell Script に処理を詰め込みすぎず、各 data format や system に適した command / tool へ処理を委譲する考え方を身につける

---

## 学習範囲

このリポジトリで扱う Unit は次の通り。

| Unit | 内容                                                                                          |
| ---- | --------------------------------------------------------------------------------------------- |
| 01   | [Linux / Shell の実行モデル](units/01-linux-shell-execution-model/README.md)                  |
| 02   | [標準入出力・パイプ・ファイル・権限](units/02-standard-io-pipes-files-permissions/README.md)  |
| 03   | [Bash Script の基本と Shell 展開](units/03-bash-basics-shell-expansion/README.md)             |
| 04   | [安全な Shell Script・エラー処理・デバッグ](units/04-shell-safety-errors-debugging/README.md) |
| 05   | [ファイル・テキスト・ログ処理の頻出パターン](units/05-file-text-log-processing/README.md)     |
| 06   | [HTTP / API / JSON の実用パターン](units/06-http-api-json/README.md)                          |
| 07   | [バッチ・cron・定期実行と運用設計](units/07-batch-cron-operations/README.md)                  |
| 08   | [shfmt / ShellCheck とコード品質](units/08-shfmt-shellcheck-quality/README.md)                |
| 09   | [Bats による Shell Script の自動テスト](units/09-bats-automated-testing/README.md)            |
| 10   | [DB / Docker / Application との連携](units/10-db-docker-app-integration/README.md)            |
| 11   | [CI/CD と Shell Script の実務的な統合](units/11-cicd-shell-integration/README.md)             |

### 各 Unit の位置づけ

- **Unit 01: Linux / Shell の実行モデル**  
  program / process / thread、PID / PPID、Shell process、builtin / external command、foreground / background、exit status、signal、environment variable、subshell など、Shell Script が動作する前提を整理する。

- **Unit 02: 標準入出力・パイプ・ファイル・権限**  
  stdin / stdout / stderr、redirection、pipe、`pipefail`、path、file、symbolic link、permission、`chmod`、temporary file など、Shell で command と file を扱う基本を確認する。

- **Unit 03: Bash Script の基本と Shell 展開**  
  variable、argument、array、condition、loop、function、quote、command substitution、parameter expansion、pathname expansion など、Bash Script を読み書きするための基本を扱う。

- **Unit 04: 安全な Shell Script・エラー処理・デバッグ**  
  exit status、`set -euo pipefail` と注意点、validation、`trap`、cleanup、temporary directory、idempotency、lock、timeout、retry、secret、trace など、安全な Script の基本を確認する。

- **Unit 05: ファイル・テキスト・ログ処理の頻出パターン**  
  file / directory の処理、`grep` / `sed` / `awk` / `cut` / `sort` / `uniq` / `find` / `xargs` / `while read`、log、簡単な CSV など、Shell で頻出する処理をまとめて扱う。

- **Unit 06: HTTP / API / JSON の実用パターン**  
  `curl` による GET / POST、header、HTTP status、timeout、failure handling、environment variable による token、`jq` による JSON 処理、health / readiness の基本を確認する。

- **Unit 07: バッチ・cron・定期実行と運用設計**  
  non-interactive batch、cron / crontab、scheduler environment、stdout / stderr、logging、retry / timeout、idempotency、partial failure、lock、systemd service / timer を扱う。

- **Unit 08: shfmt / ShellCheck とコード品質**  
  shfmt による format / format check、ShellCheck による static analysis、代表的な warning、suppression、local quality check など、Shell Script の品質確認を扱う。

- **Unit 09: Bats による Shell Script の自動テスト**  
  `.bats`、`@test`、`run`、`$status`、`$output`、`$lines`、正常系 / 異常系、file operation、fixture、test isolation、testability、fake command、`PATH` 差し替えを扱う。

- **Unit 10: DB / Docker / Application との連携**  
  PostgreSQL / `psql`、CSV import、Docker Compose、Container 操作、Application 起動、health check、API、DB 確認を Shell Script からつなぎ、glue / orchestration としての利用を確認する。

- **Unit 11: CI/CD と Shell Script の実務的な統合**  
  CI/CD、workflow、trigger、runner、job、step、environment / secrets、artifact を整理し、shfmt / ShellCheck / Bats を GitHub Actions へ接続して、exit status が CI の結果へ伝播する流れを確認する。

---

## 学習の進め方

基本的な進め方は次の通り。

1. `units/` 配下の対象 Unit の `README.md` を開く
2. `この Unit の目的` と `学習内容` を読み、扱う概念と Unit 全体の位置づけを確認する
3. `使用するもの` と `事前準備` を確認する
4. `examples/`、`scripts/`、`tests/` など、その Unit のサンプルファイルを読む
5. コード内のコメントと実際の command / Script の処理を対応させながら、処理の流れを追う
6. `学習・実践` の手順に沿って Script や command を実行する
7. stdout / stderr、exit status、生成ファイル、process、log、HTTP response、DB、Container など、Unit に応じた実行結果を確認する
8. 必要に応じて argument、input、environment variable、実行条件などを変更し、挙動の違いを確認する
9. `実行・確認ポイント` と実際の結果を照らし合わせる
10. `学習ポイント` を読み、実行結果と概念を対応づけて整理する

このリポジトリでは、コードリーディングを「ソースコードを読むだけ」の学習にはしない。  
コードを読み、実際に実行し、観察できる結果を確認することで、記述と挙動を対応づけることを重視する。

サンプルコードには、コードを日本語へ置き換えるだけの説明を機械的に付けるのではなく、処理意図、設計上の判断、分かりにくい command / option、failure handling など、コードリーディングに必要な箇所へコメントを記載している。

---

## 前提環境

主な学習環境は次の通り。

- Windows
- WSL 2
- Linux
- Bash
- VS Code
- Git / GitHub

Shell Script の実行は、基本的に WSL 2 上の Linux / Bash を前提とする。

Unit によって、以下の tool / environment も利用する。

- `curl`
- `jq`
- cron
- systemd
- shfmt
- ShellCheck
- Bats
- Docker / Docker Compose
- PostgreSQL / `psql`
- Python 3
- GitHub Actions

すべての tool がすべての Unit で必要になるわけではない。  
Unit 固有の前提や準備は、各 Unit の `README.md` を参照する。

---

## 使用技術・ツール

### Shell / Linux

- Bash
- Linux CLI
- GNU / Linux の基本的な command
- cron
- systemd / systemd timer

### Quality / Test

- shfmt
- ShellCheck
- Bats

### HTTP / Data / Integration

- curl
- jq
- PostgreSQL / psql
- Docker / Docker Compose
- Python 3
  - Unit 10 の学習補助 Application で使用

### CI/CD

- Git
- GitHub
- GitHub Actions

### Development

- WSL 2
- VS Code

---

## セットアップ

このリポジトリ全体で package manager を使った一括 setup は行わない。  
利用する command / tool は Unit ごとに異なるため、必要なものを対象 Unit の `README.md` で確認する。

まず Bash を確認する。

```bash
bash --version
```

主要な command が利用できるか確認する場合は、`command -v` を使う。

```bash
command -v bash
command -v curl
command -v jq
```

品質確認用 tool を利用する Unit では、次も確認する。

```bash
command -v shfmt
command -v shellcheck
command -v bats
```

Docker を利用する Unit では、次を確認する。

```bash
docker version
docker compose version
```

Unit 10 では PostgreSQL Container 内の `psql` を利用するため、host 側への `psql` 導入を必須とはしていない。

---

## 実行・品質確認

各 Unit の具体的な実行 command は、それぞれの `README.md` に記載している。

Shell Script の基本的な実行例は次の通り。

```bash
bash path/to/script.sh
```

Bash の構文だけを確認する場合は、`bash -n` を利用できる。

```bash
bash -n path/to/script.sh
```

Unit 08 以降では、通常の Shell Script に対して shfmt / ShellCheck を利用する。

```bash
shfmt -i 2 -d path/to/script.sh
shellcheck path/to/script.sh
```

Unit 09 以降では、必要な箇所に Bats による自動テストを利用する。

```bash
bats path/to/tests
```

Unit 11 では、local で CI と同じ品質確認をまとめて実行できる。

```bash
bash units/11-cicd-shell-integration/quality/04-all-checks.sh
```

GitHub Actions では、Unit 11 の workflow から shfmt、ShellCheck、Bats を実行し、Shell Script の exit status を workflow の success / failure へ接続する。

---

## リポジトリ構成

主要な構成は次の通り。

```text
.
├─ .github/
│  └─ workflows/
│     └─ unit11-shell-quality.yml
│
├─ docs/
│  └─ planning/
│     ├─ learning-curriculum.md
│     └─ learning-operation.md
│
├─ units/
│  ├─ 01-linux-shell-execution-model/
│  ├─ 02-standard-io-pipes-files-permissions/
│  ├─ 03-bash-basics-shell-expansion/
│  ├─ 04-shell-safety-errors-debugging/
│  ├─ 05-file-text-log-processing/
│  ├─ 06-http-api-json/
│  ├─ 07-batch-cron-operations/
│  ├─ 08-shfmt-shellcheck-quality/
│  ├─ 09-bats-automated-testing/
│  ├─ 10-db-docker-app-integration/
│  └─ 11-cicd-shell-integration/
│
└─ README.md
```

各 Unit の内部構成は学習内容に応じて異なる。  
`examples/`、`scripts/`、`tests/`、`quality/`、`config/`、`sql/`、`support/` など、必要なディレクトリだけを配置している。

### 各ディレクトリ・ファイルの役割

- `.github/workflows/`  
  Unit 11 で使用する GitHub Actions workflow を配置する。

- `docs/planning/`  
  このリポジトリ全体の学習計画と運用方針を配置する。

- `units/`  
  Unit 01～11 の実際の学習教材を配置する。  
  各 Unit の `README.md` に、学習目的、概念説明、実行手順、確認ポイント、学習ポイントをまとめる。

- `units/<unit>/examples/`  
  Unit の概念や処理パターンを確認するための実行可能なサンプルを配置する。  
  Unit によっては別のディレクトリ構成を使用する。

- `units/<unit>/tests/`  
  Bats などによる自動テストを扱う Unit で test code を配置する。

- `units/<unit>/quality/`  
  shfmt / ShellCheck / Bats などの品質確認をまとめて実行する Script を配置する Unit がある。

- `README.md`  
  リポジトリ全体の目的、学習範囲、進め方、環境、構成への入口となるドキュメント。

---

## ドキュメント

### 学習計画

- [`docs/planning/learning-curriculum.md`](docs/planning/learning-curriculum.md)  
  学習目的、対象範囲、11 Unit の構成、各 Unit で扱う内容、対象外、最終的な到達状態をまとめる。

- [`docs/planning/learning-operation.md`](docs/planning/learning-operation.md)  
  リポジトリ構成、Unit の進め方、成果物、学習方法、環境、Git 運用など、この学習リポジトリの運用方針をまとめる。

### Unit ドキュメント

各 Unit の `README.md` が、その Unit の実際の学習教材となる。

基本的に以下の構成で整理している。

```text
この Unit の目的
学習内容
使用するもの
事前準備
学習・実践
実行・確認ポイント
学習ポイント
```

概念だけを切り離して読むのではなく、サンプルコード、実行 command、実行結果と対応させながら利用する。

---

## このリポジトリで確認できること

このリポジトリでは、Shell Script の文法だけでなく、実際に Script を利用するときに必要になる周辺知識まで段階的に確認できる。

- Linux / Shell の実行モデルと command / process / exit status の関係
- stdin / stdout / stderr、pipe、redirection、file、permission
- Bash Script の基本構文と Shell 展開
- validation、error handling、cleanup、retry、lock などの安全な Script
- file / text / log の実用的な処理
- HTTP / API / JSON と Shell Script の連携
- batch / cron / systemd timer と non-interactive execution
- shfmt / ShellCheck による format / static analysis
- Bats による Shell Script の自動テスト
- PostgreSQL / Docker / Application をつなぐ orchestration
- GitHub Actions から shfmt / ShellCheck / Bats を実行する CI
- Shell Script の exit status が外部の automation system の success / failure へつながる考え方

個々の command を暗記することより、必要な command や option を調べながら、処理の意図、入出力、failure、実行環境を確認し、安全に Script を扱えることを重視している。
