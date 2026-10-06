# 11. CI/CD と Shell Script の実務的な統合

## この Unit の目的

Shell Script が実際の開発工程や自動化の中でどのように利用されるかを理解し、これまで学んだ `shfmt`、ShellCheck、Bats などの品質確認を CI へ接続する。  
Shell Script 単体の書き方だけでなく、command の exit status が CI の step / job / workflow の success / failure へどのようにつながるかを、GitHub Actions の workflow を通して確認する。

この Unit では、次の流れを中心に扱う。

```text
Push / Pull Request
↓
GitHub Actions workflow
↓
shfmt
↓
ShellCheck
↓
Bats
↓
Success / Failure
```

さらに、CI environment と local environment の違い、environment variable、secret、artifact など、CI の中で Shell Script を利用するときに必要になる基本的な要素も確認する。

Unit 11 は Shell Script 学習の最終 Unit である。  
新しい Bash syntax を増やすことより、Unit 01～10 で学んだ exit status、environment、quality check、automated test、安全な secret の扱いなどを、実際の development workflow へ接続することを重視する。

## 学習内容

### CI / CD の基本

CI は Continuous Integration の略である。  
development team が変更を継続的に repository へ統合し、その変更に対して build、test、lint などの確認を自動化する考え方として利用される。

たとえば developer が、

```text
code change
↓
commit
↓
push
↓
Pull Request
```

と進めたとき、CI が自動的に、

```text
format check
static analysis
automated test
build
```

などを実行する。

人間が毎回同じ command を手動実行するだけでは、

- 実行し忘れる
- developer ごとに確認方法が違う
- local environment だけでは再現できない
- Pull Request に問題のある変更が入っても気付きにくい

といった状態が起こり得る。

CI では repository に対する一定の event を trigger として、決められた environment で同じ確認を自動実行できる。

CD は Continuous Delivery または Continuous Deployment の文脈で使われる。

大まかには、

```text
CI
→ code change を統合するための品質確認を自動化する

Continuous Delivery
→ deploy 可能な状態まで継続的に準備する

Continuous Deployment
→ 条件を満たした変更を production 等へ自動 deploy する
```

と捉えられる。

CI / CD は完全に独立したものではなく、

```text
code
↓
quality check
↓
build
↓
artifact
↓
release / deploy
```

という development / delivery flow の中でつながっている。

この Unit では **CI を中心に実践する**。  
本格的な deployment pipeline や release engineering は対象外である。

### Workflow / pipeline・trigger・runner・job・step

CI/CD system では、複数の処理を一連の flow として定義する。  
GitHub Actions では、その定義を workflow と呼ぶ。

今回の workflow は repository root の次の file にある。

```text
.github/workflows/unit11-shell-quality.yml
```

workflow の中には、

```text
trigger
job
step
```

などが定義される。

#### Trigger

trigger は workflow を開始する event である。

今回の workflow では、

```yaml
on:
  push:
  pull_request:
  workflow_dispatch:
```

を利用する。

大まかには、

```text
push
→ repository へ commit が push された

pull_request
→ Pull Request に関する対象 event が発生した

workflow_dispatch
→ 人間が workflow を手動実行する
```

という違いになる。

さらに `paths` を指定し、Unit 11 または Unit 11 の workflow が変更された場合だけ実行する構成にしている。

```text
units/11-cicd-shell-integration/**
.github/workflows/unit11-shell-quality.yml
```

repository 内のすべての変更で学習用 workflow を起動するのではなく、今回の教材に関係する変更へ trigger を限定している。

#### Runner

runner は workflow の処理を実際に実行する machine / environment である。

今回の workflow は、

```yaml
runs-on: ubuntu-latest
```

としている。

GitHub Actions が用意する Ubuntu runner 上で、

```text
checkout
tool installation
Shell Script
Bats
artifact generation
```

などを実行する。

local の WSL 2 で動いていた Script が、CI では別の Linux environment で動くことになる。

そのため、

```text
自分の PC では動く
```

ことと、

```text
CI runner でも動く
```

ことは同じではない。

Unit 07 で扱った「manual execution と scheduler execution の environment の違い」と同じように、CI でも実行環境を明示的に考える必要がある。

#### Job

job は workflow 内で runner 上に実行される一まとまりの処理である。

今回の workflow では、

```yaml
jobs:
  quality:
```

という一つの job を定義している。

この `quality` job の中で、

```text
checkout
tool installation
format check
ShellCheck
Bats
environment 確認
secret sample
artifact build
artifact upload
optional failure
```

を順番に実行する。

実務の大きな workflow では、

```text
lint job
test job
build job
deploy job
```

など複数 job へ分割することもある。

この Unit では CI の基本構造を追いやすくするため、一つの `quality` job にまとめている。

#### Step

step は job 内の個々の処理である。

今回であれば、

```yaml
- name: Check formatting with shfmt
  run: bash units/11-cicd-shell-integration/quality/01-format-check.sh
```

が一つの step になる。

step には、

```text
run
→ command / Shell Script を実行する

uses
→ reusable Action を利用する
```

という形がある。

たとえば checkout は、

```yaml
uses: actions/checkout@v7
```

で Action を利用する。

一方、学習用 Shell Script は、

```yaml
run: bash ...
```

で実行している。

### Format・lint・test・build・artifact・deploy の位置づけ

CI/CD の中では、似て見える複数の処理が登場する。

今回の Unit では、それぞれを次のように整理する。

```text
format
→ source code の書式を統一する

format check
→ formatter を適用すべき差分がないか確認する

lint / static analysis
→ source code を静的に解析し、問題になり得る pattern を検出する

test
→ 実際に code を実行し、期待する振る舞いを自動確認する

build
→ source などから実行・配布可能な成果物を作る処理

artifact
→ workflow が生成した file / result を保存・受け渡しする仕組み

deploy
→ Application や artifact を実行環境へ配置・反映する処理
```

今回の実例では、

```text
format check
→ shfmt

lint / static analysis
→ ShellCheck

test
→ Bats

build
→ build-artifact.sh

artifact
→ actions/upload-artifact
```

を扱う。

ただし `build-artifact.sh` は実際の Application build を再現するものではない。  
workflow が file を生成し、その file を artifact として扱う一連の関係を理解するために、CI metadata を `ci-summary.txt` へ書き出す最小例にしている。

deployment は実践しない。

### Shell Script と CI の接続

CI から見れば、Shell Script も external command の一つとして実行される。

```yaml
run: bash path/to/script.sh
```

この command が `0` で終了すれば success、non-zero で終了すれば failure として扱われる。

大まかな関係は次のようになる。

```text
Shell command
↓
exit status

0
↓
step success

non-zero
↓
step failure
```

通常の workflow では step が failure になると、後続 step が実行されず job も failure になる。

その結果、

```text
Shell Script failure
↓
step failure
↓
job failure
↓
workflow failure
```

という形で結果が上位へ伝わる。

Unit 01 から繰り返し扱ってきた exit status が、CI の結果そのものへ接続する。

つまり、

```bash
exit 1
```

は単に Terminal で `$?` が `1` になるだけではなく、CI では Pull Request 上の quality check failure などへつながり得る。

### Success / failure を明示する sample

`examples/ci/01-command-result.sh` は、CI と exit status の関係を観察するための最小 sample である。

```bash
bash examples/ci/01-command-result.sh success
```

では、

```text
command completed successfully
```

を stdout に出し、status `0` で終了する。

一方、

```bash
bash examples/ci/01-command-result.sh failure
```

では stderr に message を出し、status `1` で終了する。

この Script は Bats でも test しているため、

```text
Shell Script の contract
↓
Bats で確認
↓
CI から同じ Script を実行
```

という接続も確認できる。

### Local と CI で同じ quality check を利用する

Unit 08 では formatter / static analysis を editor の便利機能だけではなく、CLI から再現できる品質管理として扱った。  
Unit 09 では Bats test を CLI から実行した。  
Unit 11 ではそれらを CI へ接続する。

今回の `quality/` は次の構成である。

```text
01-format-check.sh
→ shfmt

02-shellcheck.sh
→ ShellCheck

03-bats.sh
→ Bats

04-all-checks.sh
→ 上記 3 つを順番に実行
```

local では、

```bash
bash quality/04-all-checks.sh
```

と実行できる。

GitHub Actions では、同じ個別 Script を各 step から呼び出す。

```text
local
↓
quality/*.sh

GitHub Actions
↓
quality/*.sh
```

つまり CI 用に別の lint logic / test logic を新しく作っているのではなく、local でも実行できる同じ入口を automation から呼び出している。

これにより、

```text
local では success
CI では別 rule なので failure
```

というずれを減らしやすい。

### shfmt と CI

`quality/01-format-check.sh` は formatter を実行して code を書き換えるのではなく、format check を行う。

```bash
shfmt -i 2 -d ...
```

差分があれば `shfmt` が non-zero を返すため、そのまま CI step failure へつながる。

通常の Bash files と Bats files は language が異なるため、Bats files には、

```bash
shfmt -ln bats -i 2 -d tests/*.bats
```

を利用している。

local では formatter で修正し、CI では未整形を検出する、という Unit 08 の考え方をそのまま workflow に接続している。

### ShellCheck と CI

`quality/02-shellcheck.sh` は、

```text
examples
scripts
quality
test helper
```

を ShellCheck で解析する。

warning が quality rule に反する場合、ShellCheck の non-zero が Script の non-zero となり、GitHub Actions step の failure へつながる。

この Unit では Bats の `.bats` files の実行確認は Bats 自身へ任せ、ShellCheck の対象は通常の Shell Script と test helper に限定している。

重要なのは、

```text
ShellCheck を GitHub Actions 専用に実行する
```

のではなく、

```text
CLI で実行できる static analysis
↓
CI から同じ command を呼ぶ
```

という構造である。

### Bats と CI

`quality/03-bats.sh` は、

```bash
bats tests
```

を実行する。

一つでも Bats test が failure すれば `bats` が non-zero となる。

そのため、

```text
assertion failure
↓
Bats failure
↓
03-bats.sh failure
↓
GitHub Actions step failure
↓
quality job failure
```

という流れになる。

Unit 09 で学んだ automated test が、CI の gate として機能する。

### `set -e` と quality check のまとめ

`quality/04-all-checks.sh` では、

```bash
set -e
```

を利用している。

その後、

```bash
bash 01-format-check.sh
bash 02-shellcheck.sh
bash 03-bats.sh
```

を順番に実行する。

途中の command が non-zero を返した場合、そこで Script が終了する。

```text
shfmt failure
↓
04-all-checks.sh failure

ShellCheck failure
↓
04-all-checks.sh failure

Bats failure
↓
04-all-checks.sh failure
```

となる。

この Script は local で CI 相当の quality check を一括実行する入口として利用する。

一方 GitHub Actions workflow では、各 quality check を別 step にしている。

これは workflow 上で、

```text
formatting が失敗した
ShellCheck が失敗した
Bats が失敗した
```

のどこで止まったかを見やすくするためである。

### GitHub Actions workflow の構造

今回の workflow は次の大きな流れになっている。

```text
Checkout repository
↓
Install shell quality tools
↓
Check formatting with shfmt
↓
Analyze with ShellCheck
↓
Run Bats tests
↓
Show execution environment
↓
Handle optional secret safely
↓
Build sample artifact
↓
Upload sample artifact
↓
Optional intentional failure
```

最初に repository content を runner へ checkout する。

```yaml
- name: Checkout repository
  uses: actions/checkout@v7
```

その後、学習で使用する CLI を runner へ用意する。

```yaml
sudo apt-get install -y shfmt shellcheck bats
```

tool installation 自体を学ぶことが目的ではなく、その runner に必要な dependency を明示的に準備している点を見る。

その後、quality check Script を順番に実行する。

### Workflow trigger と Pull Request

今回の workflow は `push` と `pull_request` の両方を trigger にしている。

そのため Unit 11 の file を変更して feature branch へ push した場合や、Pull Request を作成・更新した場合に quality workflow が起動する。

repository の通常運用が、

```text
feature branch
↓
push
↓
Pull Request
↓
review
↓
merge
```

であれば、CI はその途中へ入り、

```text
feature branch
↓
push
↓
CI
↓
Pull Request
↓
CI result を確認
↓
review / merge
```

という位置づけになる。

CI が code review の代わりになるわけではない。

```text
CI
→ 機械的に確認できるもの

review
→ code の設計意図、読みやすさ、仕様との整合など人間が判断するもの
```

という役割の違いがある。

### Runner environment と local environment

`examples/ci/02-environment.sh` は、同じ Script を local と GitHub Actions の両方で実行できる。

local では、

```text
execution_environment=local
runner_os=local
ref_name=local
```

のようになる。

GitHub Actions では、runner が用意する environment variable によって、

```text
execution_environment=github-actions
runner_os=Linux
ref_name=<branch or ref>
```

のような情報を取得できる。

今回利用するのは、

```text
GITHUB_ACTIONS
RUNNER_OS
GITHUB_REF_NAME
```

である。

`build-artifact.sh` ではさらに、

```text
GITHUB_SHA
```

も利用する。

これは GitHub Actions のすべての environment variable を暗記するためではない。

重要なのは、

> CI runner には CI system が用意する execution context が environment variable として存在する

という考え方である。

### Environment variable と secret の違い

environment variable は process へ設定値を渡す一般的な仕組みである。

たとえば、

```bash
UNIT11_OUTPUT_DIR=/tmp/output bash scripts/build-artifact.sh
```

とすれば、build output directory を外部から変更できる。

CI でも同じ仕組みを利用できる。

一方、token や password などの confidential value は source code や workflow file に直接書かない。

GitHub Actions では repository / environment などへ登録した secret を workflow から参照できる。

今回の workflow では、

```yaml
env:
  UNIT11_SAMPLE_TOKEN: ${{ secrets.UNIT11_SAMPLE_TOKEN }}
```

として、secret を step の environment variable へ渡している。

Shell Script 側では、

```bash
${UNIT11_SAMPLE_TOKEN:-}
```

から値の有無を確認できる。

### Secret を log へ出さない

secret を environment variable として渡しても、安全性の問題がすべて解決するわけではない。

たとえば、

```bash
printf '%s\n' "$UNIT11_SAMPLE_TOKEN"
```

とすれば Script 自身が secret を出力してしまう。

また、

```bash
set -x
```

の trace に command argument や expansion が含まれる場合もある。

そのため今回の `03-secret-usage.sh` は secret value を利用せず、

```text
configured
not configured
```

だけを出力する。

```text
secret を source code に書かない
+
secret を CI secret から渡す
+
Script が secret value を log へ出さない
```

までを一つの安全性として考える。

この考え方は Unit 06 の authentication token、Unit 07 の logging、Unit 04 の xtrace と secret の学習にもつながる。

### Secret がなくても学習 workflow を実行できる構成

`UNIT11_SAMPLE_TOKEN` は学習用の optional secret である。

secret を repository に登録していない場合でも、

```text
UNIT11_SAMPLE_TOKEN is not configured; secret example skipped
```

として status `0` で終了する。

つまり Unit 11 を学習するために、本物の token や password を用意する必要はない。  
secret を実際に登録して確認する場合も、学習用の dummy value を使用できる。

重要なのは secret value そのものではなく、

```text
GitHub Actions secrets
↓
workflow の env
↓
Shell process
```

という受け渡しの形を理解することである。

### Build と artifact

CI/CD では quality check の後に build が行われる場合がある。

Application なら、

```text
compile
package
bundle
container image build
```

などが build に当たる。

今回の Unit は Shell Script repository なので、本格的な Application build は行わない。

代わりに `scripts/build-artifact.sh` が、

```text
execution_environment
runner_os
ref_name
commit_sha
```

を `dist/ci-summary.txt` へ書き出す。

local では、

```text
execution_environment=local
runner_os=local
ref_name=local
commit_sha=local
```

となる。

GitHub Actions では runner の context が反映される。

この file は workflow 内の、

```yaml
uses: actions/upload-artifact@v7
```

で artifact として upload される。

### Artifact と deploy は異なる

artifact を upload することは deploy ではない。

```text
artifact
→ workflow が生成した成果物を保存・受け渡しする

deploy
→ Application / artifact を実行環境へ反映する
```

今回の artifact は、

```text
unit11-ci-summary
```

という名前で workflow run に紐づいて保存される。

実務では、

```text
build artifact
↓
test
↓
release
↓
deploy
```

のように後続工程で利用することがある。

Unit 11 では artifact の生成と保存までを扱い、deployment pipeline までは進めない。

### Intentional failure

CI では success だけでなく failure を観察することも重要である。

今回の workflow は `workflow_dispatch` に、

```text
run_failure_demo
```

という boolean input を用意している。

`false` の場合は intentional failure step を実行しない。

`true` の場合だけ、

```bash
bash units/11-cicd-shell-integration/examples/ci/01-command-result.sh failure
```

を実行する。

この Script は status `1` を返す。

その結果、

```text
01-command-result.sh
↓
exit 1
↓
Optional intentional failure step
↓
failure
↓
quality job
↓
failure
↓
workflow
↓
failure
```

という伝播を GitHub Actions 上で観察できる。

この failure は bug ではなく、CI の failure propagation を確認するために明示的に選んだ場合だけ発生させる。

### Workflow permission

今回の workflow では、

```yaml
permissions:
  contents: read
```

としている。

学習用 workflow は repository content を checkout して quality check するだけなので、repository を書き換える permission は必要ない。  
CI/CD では token や permission を必要以上に広くしないことも重要である。

この Unit では GitHub permission model の詳細までは扱わないが、

> workflow に必要な権限だけを与える

という基本的な考え方を確認する。

### 周辺領域との関係

CI/CD は development automation の一部分であり、周囲には多くの仕組みが存在する。

この Unit では実践しないが、位置づけとして以下を確認する。

#### Deployment automation

build / test が成功した artifact や Application を、server、cloud、hosting environment などへ反映する automation である。  
CI の後段に配置されることが多いが、deploy の承認や environment ごとの制御が必要になる場合もある。

#### Configuration management

server / middleware / OS configuration などを一定の状態へ管理する考え方や tool 群である。  
Shell Script でも configuration を変更できるが、多数の server や複雑な desired state を継続管理する場合は専用 tool が適する場合がある。

#### Infrastructure as Code

server、network、cloud resource などの infrastructure definition を code として管理する考え方である。  
CI から validation / plan / apply などを実行する構成もあるが、この Unit では IaC の実践は行わない。

#### Container / orchestration

Unit 10 で扱った Docker Container も CI/CD とつながる。

たとえば、

```text
CI
↓
Container image build
↓
registry
↓
deployment
```

のような流れがある。

複数 Container を大規模に管理する orchestration system も存在するが、Kubernetes の実践はこの学習範囲外である。

#### Job scheduler

cron や systemd timer など、Unit 07 で扱った定期実行も automation の一種である。

```text
CI
→ source code change などを trigger として実行

scheduler
→ time / schedule を trigger として実行
```

というように trigger が異なる。

どちらも Shell Script を実行する場になり得る。

#### Logging

automation は無人実行されるため、後から原因を追跡できる output が必要になる。  
CI では step の stdout / stderr が workflow log として確認できる。

Unit 07 で扱った、

```text
後から何が起きたか追える output
```

という考え方は CI でも同じである。

#### Monitoring / alerting

CI/CD 自体の failure、deployment 後の Application failure、infrastructure failure などを検知し、人間へ通知する仕組みが利用される。

この Unit では monitoring / alerting 基盤は構築しない。

重要なのは、

```text
CI/CD
deployment
configuration
infrastructure
container
scheduler
logging
monitoring
```

が独立した無関係な技術ではなく、development / operations automation の中で接続していることを把握することである。

## 使用するもの

この Unit では主に以下を利用する。

- Bash
- Git / GitHub
- GitHub Actions
- YAML
- `shfmt`
- ShellCheck
- Bats
- `actions/checkout@v7`
- `actions/upload-artifact@v7`

local での quality check には Unit 08 / 09 で導入した `shfmt`、ShellCheck、Bats を利用する。

GitHub Actions の実行には GitHub repository への push が必要になる。

## 事前準備

Unit 01～10 が完了し、以下を確認済みであることを前提とする。

- command / process / exit status
- stdout / stderr
- environment variable
- secret を log に出さない考え方
- `set -e`
- Shell Script の failure handling
- shfmt
- ShellCheck
- Bats
- local と automated execution environment の違い
- Git / GitHub の基本操作
- feature branch / Pull Request の基本的な workflow

Unit 11 の第 1 回生成物は repository root を基準に配置する。

```text
repository-root/
├─ .github/
│  └─ workflows/
│     └─ unit11-shell-quality.yml
└─ units/
   └─ 11-cicd-shell-integration/
      ├─ .gitignore
      ├─ examples/
      │  └─ ci/
      │     ├─ 01-command-result.sh
      │     ├─ 02-environment.sh
      │     └─ 03-secret-usage.sh
      ├─ quality/
      │  ├─ 01-format-check.sh
      │  ├─ 02-shellcheck.sh
      │  ├─ 03-bats.sh
      │  └─ 04-all-checks.sh
      ├─ scripts/
      │  └─ build-artifact.sh
      └─ tests/
         ├─ 01-command-result.bats
         ├─ 02-environment-secret-artifact.bats
         └─ test_helper.bash
```

Unit directory へ移動する。

```bash
cd units/11-cicd-shell-integration
```

必要な local command を確認する。

```bash
command -v bash
command -v shfmt
command -v shellcheck
command -v bats
```

version も確認する。

```bash
shfmt --version
shellcheck --version
bats --version
```

Unit 09 と同様、`run --separate-stderr` を利用するため、Bats はその機能を利用できる version を前提とする。

workflow file は Unit directory の外、repository root の `.github/workflows/` にある。

Unit directory から確認する場合は、

```bash
cat ../../.github/workflows/unit11-shell-quality.yml
```

とする。

## 学習・実践

### 1. CI に接続する Shell Script と exit status を確認する

まず CI の最小単位となる command success / failure を local で確認する。

```bash
bash examples/ci/01-command-result.sh success
echo $?
```

出力は、

```text
command completed successfully
```

となり、exit status は `0` になる。

次に intentional failure を実行する。

```bash
bash examples/ci/01-command-result.sh failure
echo $?
```

stderr に、

```text
command failed intentionally
```

と表示され、exit status は `1` になる。

unknown mode も確認する。

```bash
bash examples/ci/01-command-result.sh unknown
echo $?
```

status `2` になる。

ここでは status code の意味を細かく分類することより、

```text
Shell command
↓
0 / non-zero
↓
CI が success / failure を判断
```

という境界を確認する。

対応する Bats test を読む。

```bash
cat tests/01-command-result.bats
```

次の要素を確認する。

```text
run
$status
$output
$stderr
```

Bats を実行する。

```bash
bats tests/01-command-result.bats
```

Shell Script が CI に入る前に、その success / failure contract 自体を automated test で確認できる。

### 2. Local と CI で共有する quality check を確認する

個別の quality Script を読む。

```bash
cat quality/01-format-check.sh
cat quality/02-shellcheck.sh
cat quality/03-bats.sh
```

それぞれの役割は、

```text
01-format-check.sh
→ shfmt

02-shellcheck.sh
→ ShellCheck

03-bats.sh
→ Bats
```

である。

まず format check を実行する。

```bash
bash quality/01-format-check.sh
echo $?
```

formatting 差分がなければ `0` になる。

次に ShellCheck を実行する。

```bash
bash quality/02-shellcheck.sh
echo $?
```

warning が quality rule に反しなければ `0` になる。

Bats を実行する。

```bash
bash quality/03-bats.sh
echo $?
```

test がすべて成功すれば `0` になる。

最後にまとめて実行する。

```bash
bash quality/04-all-checks.sh
```

すべて通過すれば、

```text
all quality checks passed
```

と表示される。

`04-all-checks.sh` には `set -e` があるため、途中の check が failure すればそこで停止する。

この一つの command を developer が commit / push 前に実行することで、CI に近い quality check を local で先に確認できる。

### 3. Bats で CI environment・secret・artifact generation を確認する

次の test file を読む。

```bash
cat tests/02-environment-secret-artifact.bats
```

この test では、

```text
local environment
GitHub Actions environment
secret 未設定
secret 設定済み
artifact file generation
```

を確認している。

実行する。

```bash
bats tests/02-environment-secret-artifact.bats
```

次にすべての test をまとめて実行する。

```bash
bats tests
```

重要なのは GitHub Actions 自体を Bats で再現しているわけではないことである。

Bats では、

```text
GITHUB_ACTIONS=true
RUNNER_OS=Linux
GITHUB_REF_NAME=...
GITHUB_SHA=...
```

などを environment variable として与え、**Shell Script が CI environment を受け取ったときの振る舞い**を確認している。

GitHub Actions platform の動作自体は GitHub Actions 上で確認する。

### 4. GitHub Actions workflow の trigger・runner・job・step を読む

repository root の workflow を表示する。

```bash
cat ../../.github/workflows/unit11-shell-quality.yml
```

まず先頭の、

```yaml
name:
on:
```

を見る。

`on` には、

```text
push
pull_request
workflow_dispatch
```

がある。

次に、

```yaml
jobs:
  quality:
    runs-on: ubuntu-latest
```

を見る。

ここから、

```text
workflow
└─ quality job
   └─ Ubuntu runner
```

という構造を確認する。

さらに `steps:` を追う。

```text
Checkout repository
Install shell quality tools
Check formatting with shfmt
Analyze with ShellCheck
Run Bats tests
Show execution environment
Handle optional secret safely
Build sample artifact
Upload sample artifact
Optional intentional failure
```

ここで YAML を暗記する必要はない。

次の対応関係を読めることを重視する。

```text
workflow
→ automation 全体

trigger
→ いつ開始するか

runner
→ どこで動くか

job
→ 一まとまりの処理

step
→ 個々の command / Action
```

### 5. Push / Pull Request から GitHub Actions を実行する

local quality check を通した状態で、Unit 11 の変更を通常の Git workflow に沿って commit / push する。

この Unit の branch 名を repository の運用ルールに合わせて作成している場合、その branch へ push する。

workflow の `push.paths` には、

```text
units/11-cicd-shell-integration/**
.github/workflows/unit11-shell-quality.yml
```

が含まれるため、今回の変更で workflow の対象になる。

GitHub repository の Actions 画面または Pull Request の check から workflow result を確認する。

quality job 内で、

```text
shfmt
ShellCheck
Bats
```

が順番に success していることを見る。

Pull Request を作成した場合は `pull_request` trigger でも workflow が実行される。

ここで確認するのは、

```text
local
bash quality/04-all-checks.sh
↓
success

push / Pull Request
↓
GitHub Actions
↓
同じ quality Script
↓
success
```

という関係である。

CI は local check を不要にするものではない。

local で早く feedback を得て、repository 側でも同じ基準を自動確認する。

### 6. CI environment と secret の扱いを確認する

まず local で environment sample を実行する。

```bash
bash examples/ci/02-environment.sh
```

local では、

```text
execution_environment=local
runner_os=local
ref_name=local
```

のようになる。

Bats では GitHub Actions 相当の environment を明示して確認できる。

```bash
bats tests/02-environment-secret-artifact.bats
```

GitHub Actions の workflow run では `Show execution environment` step の log を確認する。

local とは異なり、

```text
execution_environment=github-actions
```

となる。

次に secret sample を local で未設定のまま実行する。

```bash
env -u UNIT11_SAMPLE_TOKEN \
  bash examples/ci/03-secret-usage.sh
```

```text
UNIT11_SAMPLE_TOKEN is not configured; secret example skipped
```

となる。

dummy value を与える。

```bash
UNIT11_SAMPLE_TOKEN='unit11-dummy-secret' \
  bash examples/ci/03-secret-usage.sh
```

出力は、

```text
UNIT11_SAMPLE_TOKEN is configured; value is not printed
```

となり、dummy secret 自体は表示されない。

GitHub Actions workflow では、

```yaml
env:
  UNIT11_SAMPLE_TOKEN: ${{ secrets.UNIT11_SAMPLE_TOKEN }}
```

から Shell Script へ渡している。

実際の GitHub secret を登録しなくても Unit 11 の workflow は学習できる。  
secret がない場合は sample が安全に skip する。

secret の受け渡しを試す場合は、学習用の dummy value を `UNIT11_SAMPLE_TOKEN` という repository secret として登録して確認する。  
本物の token / password をこの教材のために用意する必要はない。

確認するのは、

```text
GitHub secret
↓
workflow expression
↓
step env
↓
Shell environment variable
```

という data flow である。

また workflow log に secret value を表示する処理がないことも確認する。

### 7. Build と artifact を local / CI の両方から確認する

local で build sample を実行する。

```bash
bash scripts/build-artifact.sh
```

出力例は、

```text
artifact_file=.../dist/ci-summary.txt
```

となる。

生成された file を確認する。

```bash
cat dist/ci-summary.txt
```

local では、

```text
execution_environment=local
runner_os=local
ref_name=local
commit_sha=local
```

となる。

`dist/` は `.gitignore` の対象なので、学習実行で生成した artifact を repository へ commit する必要はない。

GitHub Actions では `Build sample artifact` step が同じ Script を実行する。

runner では GitHub Actions が environment information を持つため、artifact 内容には CI 側の情報が入る。

続く、

```text
Upload sample artifact
```

step で `dist/` を upload する。

workflow run が成功したら `unit11-ci-summary` artifact を確認し、その中の `ci-summary.txt` を local で生成した file と比較する。

見るべき違いは、

```text
local
→ local values

CI
→ GitHub Actions runner / ref / commit values
```

である。

artifact を upload したことは deploy したことを意味しない。

この Unit では、

```text
build
↓
artifact
```

までを実践する。

### 8. Intentional failure で step / job / workflow failure を確認する

通常の `push` / `pull_request` workflow では intentional failure step は実行されない。

workflow file の次の条件を確認する。

```yaml
if: ${{ github.event_name == 'workflow_dispatch' && inputs.run_failure_demo }}
```

manual execution で `run_failure_demo` を有効にした場合だけ failure sample を実行する。

GitHub Actions 上で manual workflow execution を利用できる状態になったら、まず `run_failure_demo=false` で実行する。

通常どおり success することを確認する。

次に、

```text
run_failure_demo=true
```

で実行する。

最後の step が、

```bash
bash units/11-cicd-shell-integration/examples/ci/01-command-result.sh failure
```

を実行し、status `1` を返す。

その結果、

```text
Shell Script
↓
non-zero

Optional intentional failure step
↓
failure

quality job
↓
failure

workflow
↓
failure
```

となることを確認する。

これは意図的に failure を起こす学習なので、確認後に workflow file を壊したり、Script を success に書き換えたりする必要はない。

通常実行では input が `false` のため failure demo は skip される。

### 9. CI/CD の周辺領域と Shell Script の位置づけを整理する

最後に、この Unit で実践しなかった周辺領域を、これまでの Unit と接続して整理する。

```text
source code
↓
Git / GitHub
↓
CI
├─ format
├─ static analysis
├─ test
└─ build
↓
artifact
↓
delivery / deployment
↓
runtime environment
├─ container / orchestration
├─ configuration
├─ scheduler
└─ infrastructure
↓
logging / monitoring / alerting
```

この中で Shell Script は一つの layer に固定されるものではない。

たとえば、

```text
CI step
→ Shell Script

deployment automation
→ Shell Script

container startup
→ Shell Script

scheduled job
→ Shell Script

maintenance task
→ Shell Script
```

のように複数の場所で glue として利用され得る。

一方で、

```text
complex application logic
large-scale infrastructure state
complex deployment orchestration
monitoring platform
```

などをすべて Shell Script で自作することが目的ではない。

専用 tool / service が持つ interface を Shell Script から呼び出し、必要な範囲を自動化するという Unit 10 までの考え方を維持する。

## 実行・確認ポイント

### CI / CD

- CI は source code change に対する quality check を継続的に自動化する。
- CD は delivery / deployment までを含む broader flow として位置づける。

### GitHub Actions

- workflow file は repository root の `.github/workflows/` に配置する。
- `on` が workflow trigger を定義する。
- `runner` は workflow command を実際に実行する environment である。
- `job` は一まとまりの処理である。
- `step` は job 内の個々の command / Action である。
- `run` と `uses` の役割を区別する。

### Exit status

- Shell command の `0` は CI step success へつながる。
- non-zero は CI step failure へつながる。
- step failure が job / workflow failure へ伝播する流れを確認する。
- intentional failure sample で実際の failure result を観察する。

### Quality check

- local と CI で同じ shfmt rule を利用する。
- ShellCheck を CLI Script から実行する。
- Bats failure を CI failure へ接続する。
- `04-all-checks.sh` で local の一括確認ができる。
- CI では各 quality check を別 step にして failure 箇所を見やすくする。

### Environment / secrets

- local environment と CI runner environment は同じではない。
- GitHub Actions 固有の context が environment variable として利用できる。
- configuration と secret を source code に hard-code しない。
- secret value 自体を stdout / stderr / xtrace へ出さない。
- secret がなくても学習できる optional な構成になっている。

### Build / artifact

- `build-artifact.sh` は学習用 artifact を生成する。
- `dist/` は generated output として `.gitignore` の対象である。
- GitHub Actions から artifact を upload できる。
- artifact と deployment は別の概念である。

### 周辺領域

- deployment automation の存在と役割を説明できる。
- configuration management / IaC の位置づけを把握する。
- Container / orchestration と CI/CD の接続をイメージできる。
- cron / scheduler と CI は trigger が異なる automation である。
- logging / monitoring / alerting が無人 automation を支えることを理解する。
- Kubernetes、IaC、deployment pipeline の本格的な実践までは行わない。

## 学習ポイント

### Shell Script の exit status は開発工程の結果までつながる

Unit 01 では、

```bash
echo $?
```

で command の終了状態を確認した。

Unit 11 では、その同じ exit status が、

```text
Shell command
↓
CI step
↓
job
↓
workflow
↓
Pull Request の check
```

までつながる。

つまり exit status は Shell 内部だけの細かな情報ではない。  
外側の automation system と Shell Script が success / failure を共有するための interface になる。

この視点を持つと、

```bash
error message は出したが exit 0
```

という Script が CI ではなぜ問題になるか理解しやすい。

### CI は Shell Script の中身を理解しているわけではない

GitHub Actions が、

```text
この Script の business logic は正しい
```

と理解しているわけではない。

CI system が観察できるのは主に、

```text
command
exit status
stdout / stderr
generated files
```

などである。

Shell Script 側が適切な status を返し、Bats が適切な assertion を行い、quality tool が適切な result を返すことで、CI が機械的な判断をできる。

### CI 導入で新しい品質ルールを作る必要はない

Unit 08 / 09 で、

```text
shfmt
ShellCheck
Bats
```

を local CLI から実行できるようにした。

Unit 11 では、それを GitHub Actions から呼び出しているだけである。

```text
local quality rule
≠
CI quality rule
```

にするのではなく、

```text
one quality rule
↓
local から実行
CI から実行
```

とする方が理解しやすく、maintenance もしやすい。

CI は既存の品質確認を automation へ接続する場所と考えられる。

### Local feedback と CI feedback の両方を利用する

CI があるから local check をしなくてよいわけではない。

```text
local
→ すぐに feedback
→ push 前に修正できる

CI
→ repository 側で自動実行
→ developer environment に依存しない確認
→ Pull Request 上で共有できる
```

という違いがある。

両方で同じ quality command を使うことで、それぞれの長所を利用できる。

### Runner は自分の PC ではない

CI runner は clean な environment から始まる。

自分の local environment には、

```text
既に install 済みの command
shell startup configuration
local file
cached state
```

などが存在する。

runner ではそれらを当然の前提にできない。

そのため workflow では、

```text
checkout
dependency installation
environment configuration
```

など必要な準備を明示する。

これは Unit 07 の unattended execution で学んだ考え方の延長である。

### Quality check を step に分けると failure の意味が見やすくなる

`quality/04-all-checks.sh` は local で便利な一つの入口である。

しかし GitHub Actions では、

```text
shfmt
ShellCheck
Bats
```

を別 step にしている。

これにより workflow result を見たとき、

```text
format failure
static analysis failure
test failure
```

のどこに問題があるか分かりやすい。

同じ command 群でも、利用する environment に合わせて presentation を変えられる。

### Automated test は CI で繰り返されることで価値が増す

Bats test を一度実行して終わりにすることもできる。

しかし code change のたびに CI から実行すれば、

```text
以前成立していた behavior
↓
新しい変更
↓
regression
```

を自動的に検出しやすくなる。

Unit 09 で「Shell Script にも automated test を書ける」と学び、Unit 11 で「その test を development flow の中で繰り返す」段階へ進んでいる。

### Secret は値を隠すだけでなく、扱う範囲を狭くする

secret を GitHub へ登録すれば、それだけで安全になるわけではない。

今回の workflow は secret を必要な step の `env` だけへ渡す。

```text
repository secret
↓
specific step
↓
Shell environment
```

と利用範囲を限定する。

Script 側でも値を log へ出さない。

このように、

```text
保存場所
渡す範囲
log
trace
permission
```

を組み合わせて考える。

### Artifact は pipeline の工程間をつなぐ data になる

Shell Script が file を生成し、

```text
build-artifact.sh
↓
dist/ci-summary.txt
```

GitHub Actions がそれを artifact として保存する。

これは Unit 10 の、

```text
Shell
→ external system
→ result
```

と同じ glue の考え方である。

artifact は、

```text
build job
↓
test job

build
↓
release

CI
↓
human review
```

などの工程間で成果物を受け渡すためにも利用される。

今回の text file はその仕組みを理解するための最小例である。

### CI と CD を一つの巨大な自動化として考えなくてよい

CI/CD という言葉は一まとまりで使われることが多いが、すべてを最初から自動化する必要はない。

たとえば、

```text
Phase 1
format / lint / test

Phase 2
build artifact

Phase 3
release preparation

Phase 4
deployment
```

のように段階的に発展させられる。

今回の Unit は、

```text
quality check
+
sample build
+
artifact
```

までに留めている。

これは学習範囲を狭めているだけでなく、automation を小さな責務へ分ける考え方にもつながる。

### CI/CD の周辺には専用 tool が存在する

Shell Script は automation に便利だが、

```text
IaC
container orchestration
configuration management
monitoring
release management
```

まで Shell だけで自作する必要はない。

Unit 10 と同様に、

```text
専用 tool / platform
↓
CLI / API
↓
Shell Script
```

という関係を作れる。

Shell Script の強みは、各 tool の機能を置き換えることではなく、必要な範囲でそれらをつなぐことにある。

### Unit 11 は Unit 01～10 の内容を development workflow へ接続する

Unit 11 で利用している要素を遡ると、

```text
Unit 01
→ process / exit status

Unit 02
→ stdout / stderr

Unit 03
→ Bash Script の基本

Unit 04
→ error handling / safe Script

Unit 05
→ file / text processing

Unit 06
→ HTTP / environment / secret に関連する考え方

Unit 07
→ unattended execution / logging / environment

Unit 08
→ shfmt / ShellCheck

Unit 09
→ Bats

Unit 10
→ system 間をつなぐ orchestration
```

が含まれている。

それらを、

```text
GitHub Actions runner
↓
Shell Script
↓
quality tools
↓
automated test
↓
artifact
↓
workflow result
```

へ接続している。

この Unit の中心は GitHub Actions の YAML syntax を暗記することではない。

最終的には、

> Shell Script は local Terminal だけで使うものではなく、CI/CD、batch、container、Application operation など、さまざまな automation の中で command / system をつなぐ glue として利用できる

という全体像を持つことが重要である。
