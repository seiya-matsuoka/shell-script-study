# Shell Script Study - Learning Operation

## 1. 文書の目的

本ドキュメントは、`shell-script-study` の学習カリキュラムを、GitHub リポジトリ上でどのように進め、どのような成果物として残すかを定義する。  
学習対象・学習順序・各 Unit の内容そのものは `learning-curriculum.md` で管理し、本ドキュメントではリポジトリ構成、Unit ごとの成果物、Unit README の共通形式、サンプルコードの扱い、学習の進め方、実行環境、Git / GitHub 上での区切り、Unit 完了基準、最終的なリポジトリ完成状態などの運用面を扱う。  
本学習では、ドキュメントやリポジトリの形式を整えること自体を目的とせず、Shell Script / Linux の理解を深め、実際に動かしながら学習できることを優先する。

## 2. リポジトリの位置づけ

リポジトリ名は以下とする。

```text
shell-script-study
```

本リポジトリは、Linux / Shell の重要概念と Bash / Shell Script の基礎から実用的な利用までを体系的に一周し、実際にコードを読み、実行し、結果を確認しながら学習した内容と成果物を整理して残すための学習用リポジトリとする。

主な目的は以下のとおり。

- Shell Script の構文だけでなく、process、standard input / output、file descriptor、signal、environment variable、permission など関連する Linux の重要概念も理解する。
- コードリーディングを起点として、実行・結果確認・比較・検証まで行う。
- 正しい実装だけでなく、アンチパターンや問題が発生する条件も確認し、安全な書き方の理由を理解する。
- ShellCheck / shfmt / Bats などを利用し、Shell Script の品質管理と自動テストを経験する。
- API / DB / Docker / Application / CI/CD など、Shell Script が実務で利用される代表的な場面へ接続する。
- 学習後に自分で見返した際、各 Unit で何を学び、どのように動作を確認したのか分かる状態にする。
- 他者からの見え方やポートフォリオ性より、学習のしやすさ・理解のしやすさ・振り返りやすさを優先する。

## 3. リポジトリ構成

学習開始前の計画資料と、実際の Unit ごとの学習成果を分離した構成とする。

```text
shell-script-study/
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
├─ .gitattributes
├─ .gitignore
└─ README.md
```

### 3.1 `docs/planning/`

学習開始前に確定した計画資料を格納する。

- `learning-curriculum.md`
  - 何を・どの順番で・どこまで学ぶかを定義する。
- `learning-operation.md`
  - リポジトリ上でどのように学習を進め、成果物を残すかを定義する。

これらは学習開始時点の計画として残す。

### 3.2 `units/`

実際の学習成果を Unit 単位で格納する。  
各 Unit ディレクトリは、その Unit の学習内容と実行可能な成果物がまとまる場所とする。  
Unit ごとに必要な成果物の種類や量は異なるため、内部構成まで一律には統一しない。

## 4. Unit ディレクトリ

Unit ディレクトリ名は学習開始前に固定し、途中で都度命名しない。

| Unit | ディレクトリ名                           |
| ---- | ---------------------------------------- |
| 01   | `01-linux-shell-execution-model`         |
| 02   | `02-standard-io-pipes-files-permissions` |
| 03   | `03-bash-basics-shell-expansion`         |
| 04   | `04-shell-safety-errors-debugging`       |
| 05   | `05-file-text-log-processing`            |
| 06   | `06-http-api-json`                       |
| 07   | `07-batch-cron-operations`               |
| 08   | `08-shfmt-shellcheck-quality`            |
| 09   | `09-bats-automated-testing`              |
| 10   | `10-db-docker-app-integration`           |
| 11   | `11-cicd-shell-integration`              |

Unit 内に複数の学習対象があり、それぞれを明確に分けた方が理解しやすい場合は、必要に応じてサブディレクトリを設ける。

たとえば、以下のように学習対象の境界が明確な場合は分類してよい。

```text
examples/
├─ file-processing/
├─ text-processing/
└─ log-processing/
```

一方で、複数の command や学習対象を組み合わせた一つの Script を無理に分類すると分かりにくくなる場合は、サブディレクトリ化しない。  
ディレクトリ構成を整えることより、学習対象と成果物の関係が分かりやすいことを優先する。

## 5. Unit ごとの成果物

基本ルールは以下とする。

> 1 Unit = 1 `README.md` + その Unit に必要な実行可能・確認可能な成果物

### 5.1 全 Unit 共通

すべての Unit に以下を作成する。

```text
README.md
```

`README.md` は、その Unit の目的、学習内容、実行方法、確認方法、学習ポイントをまとめた学習ガイド兼記録とする。

### 5.2 Unit に応じて作成する成果物

Unit の内容に応じて、以下のような成果物を必要なものだけ作成する。

- Shell Script
  - `*.sh`
- Bats test
  - `*.bats`
- text file
- log file
- CSV
- JSON
- SQL
- test fixture
- configuration file
- Docker 関連ファイル
- GitHub Actions workflow
- その他、その Unit の学習に必要なファイル

すべての Unit に同じ種類のファイルやディレクトリを用意することはしない。  
空の `tests/` や `fixtures/` などを形式上だけ作成せず、学習内容に必要な場合にだけ設ける。

## 6. Unit README の共通フォーマット

各 Unit の `README.md` は、原則として以下の共通見出しを使用する。

```markdown
# XX. Unit名

## この Unit の目的

## 学習内容

## 使用するもの

## 事前準備

## 学習・実践

## 実行・確認ポイント

## 学習ポイント

## 完了条件
```

### 6.1 この Unit の目的

その Unit で何を理解し、何ができるようになることを目指すのかを記載する。

### 6.2 学習内容

その Unit で扱う Linux / Shell / Bash / tool / integration などの概念や仕組みを説明する。  
単なる用語一覧ではなく、必要に応じて「何のためのものか」「どの仕組みと関係するのか」「なぜその書き方をするのか」まで説明する。

### 6.3 使用するもの

その Unit で利用する主な command、tool、application、file、service などを記載する。

例:

- Bash
- `ps`
- `curl`
- `jq`
- shfmt
- ShellCheck
- Bats
- PostgreSQL
- Docker

### 6.4 事前準備

その Unit の学習や実行に必要な技術的準備を記載する。

例:

- 必要な tool が利用できることの確認
- 必要な file / directory の準備
- test data の準備
- Application / DB / Container の準備
- environment variable の準備
- Unit 内で利用する command の成立確認

学習開始前にすべての tool や外部 system を一括で準備するのではなく、その Unit で初めて必要になるものは原則としてその Unit で準備する。

### 6.5 学習・実践

その Unit に適した方法で、コードリーディング、Script 実行、CLI 操作、アンチパターン比較、テスト、外部 system との連携などを行う。

Unit によって学習方法が異なるため、この項目内の小見出しや構成は必要に応じて変更してよい。

### 6.6 実行・確認ポイント

コードや command を実行した後、何を確認すればよいかを記載する。

例:

- stdout に何が出力されるか
- stderr に何が出力されるか
- exit status が何になるか
- process / PID がどのように変化するか
- file が作成・変更されるか
- API がどの response を返すか
- DB にどの data が登録されるか
- ShellCheck がどの warning を出すか
- Bats の test が成功・失敗するか
- CI workflow が成功・失敗するか

### 6.7 学習ポイント

実行やコードリーディングを通して理解してほしい本質を整理する。  
「動いた」で終わらず、なぜその結果になるのか、どの概念と関係しているのかを確認できる内容とする。

### 6.8 完了条件

その Unit を完了と判断するための条件を記載する。

## 7. Unit README のボリューム方針

共通化するのは見出し構成であり、各見出しの文章量・情報量ではない。

Unit ごとに学習対象・実践内容・重要なポイントが異なるため、必要な箇所を必要なだけ記載する。

たとえば以下のような差を許容する。

- Linux / Shell の仕組みを扱う Unit では `学習内容` の説明が厚くなる。
- Bash の構文や実用パターンを扱う Unit では `学習・実践` やサンプルコードが多くなる。
- 安全性を扱う Unit ではアンチパターンと改善理由の説明量が増える。
- Bats を扱う Unit では test code と test 結果の確認が厚くなる。
- DB / Docker / Application 連携では、準備や実行・確認手順が厚くなる。

Unit 間で文章量、ファイル数、各見出しの行数をそろえるための目安は設けない。  
学習に必要な説明・解説・実践内容が不足しないことを優先し、形式上の分量制限を理由に必要な内容を省略しない。

## 8. 学習方法

本学習では、Unit の特性に応じてコードリーディング型とハンズオン型を使い分ける。  
どちらの場合も、ドキュメントを読むだけで完了することは原則としない。

### 8.1 コードリーディング型

コードリーディングは、単に Script の中身を見ることだけを意味しない。  
基本的に以下の流れで学習する。

```text
概念・目的を確認
↓
実行可能なコードを読む
↓
実際に実行
↓
stdout / stderr / exit status / file などを確認
↓
必要に応じて入力・条件を変更して再実行
↓
コードと実際の挙動を結び付けて理解
```

概念中心の Unit でも、可能な限り小さな Script や command を用いて、実際の挙動を観察できる構成とする。

### 8.2 ハンズオン型

外部 system や複数の対象を扱う Unit では、以下のような流れを基本とする。

```text
目的・仕組みを確認
↓
必要な対象・環境を準備
↓
Script / command を順番に実行
↓
system 間の動作・連携を確認
↓
期待する状態と結果を検証
```

API、DB、Docker、Application、CI/CD などを扱う場合も、それら自体を深く学習することではなく、Shell Script からどのように扱い、結果を確認するかを中心とする。

### 8.3 アンチパターンの扱い

安全性・品質に関係する重要なテーマでは、必要に応じて以下の流れで確認する。

```text
単純な実装
↓
アンチパターン
↓
問題が発生する条件で実行
↓
問題・原因を確認
↓
改善版を読む
↓
同じ条件で再実行
↓
必要に応じて ShellCheck / Bats で確認
```

推奨コードだけを提示するのではなく、なぜ改善が必要なのかを実際の挙動と結び付けて理解できるようにする。

## 9. サンプルコード・教材の方針

### 9.1 最小例から段階的に発展させる

サンプルは原則として、以下の順序を意識して構成する。

```text
最小例
↓
少し発展した例
↓
複数要素を組み合わせた例
↓
実務を意識した利用例
```

最初から大きな Script を提示せず、何を学習しているかを追いやすい構成とする。

### 9.2 実行可能な成果物を基本とする

概念中心の Unit であっても、可能な範囲で実際に実行・観察できる Script や command を成果物として用意する。  
README だけで完結する Unit は原則として作らない。

### 9.3 学習対象外の実装を作り込みすぎない

API / DB / Docker / Application / CI/CD などは Shell Script 学習の題材として使用する。  
Shell Script の学習に直接必要でない実装は最小限に留める。

例:

- 複雑な Application 実装
- 本格的な DB 設計
- 高度な API 設計
- 複雑な business logic
- UI の作り込み
- Docker 自体の詳細な再学習
- CI/CD infrastructure の高度な構築

### 9.4 Shell Script の適用範囲を示す

Shell Script で実装できることだけを示すのではなく、Shell Script が向いている処理と、別の言語・tool を選択した方がよい処理の違いも必要に応じて説明する。

## 10. ソースコードのコメント方針

各 Unit の Script、test code、configuration などには、学習しやすさを優先して必要なコメントを記載する。

### 10.1 学習対象に直接関係する箇所

Linux / Shell / Bash / safety / testing / integration など、今回の学習対象に直接関係する実装には、意図や仕組みが分かるようにコメントをしっかり記載する。

例:

- なぜ変数を double quote しているのか
- なぜ `"$@"` を利用するのか
- なぜ `printf` を選択しているのか
- `set -euo pipefail` が何をしているのか
- `trap` で何を cleanup しているのか
- exit status をどこで確認しているのか
- stderr へ出力する理由
- ShellCheck warning を回避・修正している理由
- Bats の test が何を保証しているのか

### 10.2 README との重複

README とソースコードコメントは別の学習媒体として扱う。  
そのため、学習上重要な説明については README とコメントの内容が重複しても問題ない。

README を参照せずソースコード単体を読み返した場合でも、重要な意図や注意点を理解できる状態を目指す。

### 10.3 不要なコメント

コードをそのまま日本語で読み上げるだけのコメントや、学習上意味のないコメントは避ける。  
コメントを付けるべきか迷う場合は、学習対象の理解に役立つかどうかを判断基準とする。

## 11. 実行環境・使用ツール

### 11.1 主な実行環境

本学習では、WSL 2 上の Linux / Bash を主な実行環境とする。

Linux / Shell の process、signal、permission、standard input / output などを扱うため、Linux 環境上で実際の挙動を確認することを基本とする。

### 11.2 Path の扱い

教材や Script は、特定の PC や directory 配置に依存しない構成とする。

原則として、対象 Unit の directory や repository root を起点とした relative path を利用する。

特定環境の absolute path を教材へ固定的に記載しない。  
absolute path を説明上使用する必要がある場合は、以下のような一般化した表記を使用する。

```text
/absolute/path/to/example
```

### 11.3 Docker

Docker は Shell Script 学習全体の主な実行環境とはしない。  
DB / Docker / Application 連携など、Docker を操作対象として利用する Unit で必要な場合に使用する。

### 11.4 主な tool

Unit に応じて、以下のような tool を利用する。

- Bash
- Linux standard commands / utilities
- shfmt
- ShellCheck
- Bats
- `curl`
- `jq`
- `psql`
- Docker
- Docker Compose
- GitHub Actions

すべてを学習開始前に一括で準備する必要はなく、原則として初めて必要になる Unit で準備・成立確認を行う。

## 12. 品質確認の扱い

### 12.1 shfmt / ShellCheck 学習前

Unit 08 より前は、shfmt / ShellCheck の理解を先取りすることを目的としない。  
ただし、生成する Script 自体は可能な範囲で適切な format と安全な書き方を採用する。

### 12.2 Unit 08 以降

Unit 08 で shfmt / ShellCheck を学習した後は、その後に作成する通常の Shell Script を原則として shfmt / ShellCheck の確認対象とする。

単に tool を学ぶ Unit だけで利用するのではなく、後続 Unit でも品質確認の一部として継続して利用する。

### 12.3 Bats

Unit 09 で Bats を学習した後も、すべての小さなサンプルに機械的に test を作成することはしない。  
自動テストによる確認が有効な Script に対して、必要に応じて Bats を利用する。

テストファイル数や test case 数を増やすこと自体を目的にはしない。

## 13. Unit の基本的な進め方

各 Unit は、内容に応じて以下を基本的な流れとする。

1. Unit の目的と学習内容を確認する。
2. 使用する command / tool / file を確認する。
3. 必要な事前準備を行う。
4. README とサンプルコードを読み、何を確認するか把握する。
5. Script / command を実際に実行する。
6. stdout / stderr / exit status / file / process / API response / test result などを確認する。
7. 必要に応じて入力・条件を変更し、再実行する。
8. アンチパターンや改善例がある場合は、両者を比較する。
9. README の学習ポイントを確認し、実行結果と概念を結び付ける。
10. 完了条件を満たしていることを確認し、Unit を完了する。

Unit によっては、コードリーディング中心、CLI 操作中心、test 中心、integration hands-on 中心など、実践部分の比重を変えてよい。

## 14. Unit 完了基準

各 Unit は、README やサンプルファイルを配置しただけでは完了としない。  
原則として以下を満たすことを完了条件とする。

### 14.1 内容を確認している

README とサンプルコードを読み、その Unit で扱う主要な概念・処理を確認している。

### 14.2 実行可能なものを実際に実行している

Script や command を実際に実行し、コードリーディングだけで終わらせない。

### 14.3 期待する結果を確認している

Unit に応じて、以下のような結果を確認する。

- stdout
- stderr
- exit status
- process / PID
- file / directory
- log
- API response
- JSON data
- DB data
- ShellCheck warning
- Bats test result
- Docker / Application state
- CI workflow result

### 14.4 主要な意味を理解している

その Unit の主要な概念について、大まかに説明できる状態を目指す。  
暗記テストや自己採点、学習時間の記録などを毎 Unit の必須作業にはしない。

### 14.5 Unit 固有の完了条件

必要な Unit では、共通条件に加えて固有の確認を行う。

例:

- Unit 08
  - shfmt / ShellCheck を実行できる。
  - 代表的な warning の原因と改善内容を確認できる。
- Unit 09
  - Bats test を実行し、正常系・異常系の結果を確認できる。
  - 意図的に対象 Script を変更した場合に test が失敗することを確認できる。
- Unit 10
  - Shell Script から DB / Docker / Application などの連携を実際に確認できる。
- Unit 11
  - CI workflow 上で shfmt / ShellCheck / Bats などの品質確認が実行され、success / failure を確認できる。

## 15. Git / GitHub 上での学習単位

Git / GitHub では、Unit ごとの学習区切りを明確に残す。

### 15.1 Branch

原則として以下とする。

```text
1 Unit = 1 feature branch
```

branch 名は Unit directory 名を利用する。

形式:

```text
feature/<Unitディレクトリ名>
```

例:

```text
feature/01-linux-shell-execution-model
feature/09-bats-automated-testing
feature/11-cicd-shell-integration
```

Commit message、Pull Request の記載内容、merge 方法などの具体的な Git / GitHub 操作は、本学習の運用計画では定義しない。

## 16. 学習開始前の準備

Unit 01 を開始する前には、学習内容を先取りしすぎない範囲で、学習を開始できる状態だけ整える。

### 16.1 リポジトリ準備

- `shell-script-study` repository を作成する。
- Git 管理を開始する。
- `docs/planning/` を用意する。
- `learning-curriculum.md` を配置する。
- `learning-operation.md` を配置する。
- `.gitignore` を作成する。
- `.gitattributes` を作成する。

### 16.2 Shell Script の改行コード

Shell Script は Linux / Bash 上で実行することを前提とするため、repository 内の Shell Script の改行コードは LF を基本とする。

Windows 環境で repository を管理する場合でも、`.gitattributes` を利用して Shell Script の改行コードが意図せず CRLF にならないようにする。

### 16.3 実行環境の成立確認

Unit 01 開始前には、最低限以下を確認する。

- WSL 2 を利用できる。
- Linux environment を起動できる。
- Bash を実行できる。
- repository 内の file へ Linux 側からアクセスできる。
- Unit 01 を開始できない環境上の問題がない。

shfmt、ShellCheck、Bats、`curl`、`jq`、`psql`、Docker などは、この段階ですべて準備する必要はない。

## 17. ルート README の扱い

学習開始時にはルート `README.md` を完成版として作成しない。  
仮の学習内容を前提とした README を先に作り込まず、全 11 Unit 完了後、実際に完成した repository を基準として最終成果物として作成する。

最終 README では、必要に応じて以下を整理する。

- repository の目的
- 学習範囲
- 11 Unit 一覧
- repository 構成
- planning document への導線
- 各 Unit への導線
- 主な使用 tool
- 学習完了時点の内容

## 18. リポジトリ完成時の状態

全学習完了時には、少なくとも以下が存在する状態とする。

### 18.1 事前計画ドキュメント

```text
docs/planning/
├─ learning-curriculum.md
└─ learning-operation.md
```

### 18.2 全 11 Unit

```text
units/
├─ 01-linux-shell-execution-model/
├─ 02-standard-io-pipes-files-permissions/
├─ 03-bash-basics-shell-expansion/
├─ 04-shell-safety-errors-debugging/
├─ 05-file-text-log-processing/
├─ 06-http-api-json/
├─ 07-batch-cron-operations/
├─ 08-shfmt-shellcheck-quality/
├─ 09-bats-automated-testing/
├─ 10-db-docker-app-integration/
└─ 11-cicd-shell-integration/
```

各 Unit には `README.md` があり、必要な Unit には Shell Script、Bats test、test data、JSON、CSV、SQL、Docker 関連ファイル、CI workflow などの実践成果物が存在する。

### 18.3 ルート共通ファイル

- `.gitignore`
- `.gitattributes`
- 全 Unit 完了後に作成した `README.md`

### 18.4 CI 関連成果物

Unit 11 の学習成果として、GitHub Actions などを利用した Shell Script の品質確認 workflow が存在する。

## 19. 運用上の基本判断

本学習では、以下の優先順位で判断する。

1. Shell Script / Linux の仕組みを正しく理解できること。
2. 実際にコードを動かし、結果と仕組みを結び付けて理解できること。
3. 学習途中で迷わず進められること。
4. 後から自分で見返したときに内容が分かること。
5. repository 内の構成が整理されていること。
6. ファイル数や文章量を機械的に統一すること。

迷った場合は、形式や分量をそろえることより、学習内容が理解しやすく、実行・確認しやすい状態で残ることを優先する。
