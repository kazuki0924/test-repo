# local environment setup

## 使用ツール

### cli

- devcontainerで開発する場合は起動の時点で各種主要cliツールはすでにインストールと一部セットアップが完了済みとなっている為、追加の手順は不要
  - devcontainerを使わない場合は各ツールのそれぞれのOS向け（Windows、macOS、Linux）のインストール・セットアップ手順を公式ドキュメントから参照すること

``` text
- aws cli v2
- gh
```

### Desktop App

- 各ツールのそれぞれのOS向け（Windows、macOS、Linux）のインストール・セットアップ手順を公式ドキュメントから参照すること

``` text
- VS Code
- Rancher Desktop(docker, docker cli, docker compose plugin, buildx, etc.)
```

以下はmacOSでの手順の例

#### macOS

``` bash
# Homebrewのインストール
# https://brew.sh/
# 公式ドキュメントのトップページに最新のインストールスクリプトの実行コマンドが書いてあるのでそれをterminalで実行する
# プロンプトやログの指示に従い~/.bashrc or ~/.zshrcの編集も行う

# Homebrewが使えるようになったら以下のコマンドを実行する
brew install --cask visual-studio-code
brew install --cask rancher
# optional: 詳細は.vscode/settings.jsonを参照
brew install --cask font-cascadia-code-nf
```

##### VS Code（Windows、macOS、Linux共通）

- `.vscode/extensions.json`に記載されているDevContainer拡張をインストールするようにプロンプトされるので指示に従いインストールをする

##### Rancher Desktop（macOS）

- 以下のように設定する

``` text
Preferences -> Application -> Environment -> Configure PATH -> Automatic(独自にrcファイルを編集する場合はManual)
Preferences -> Virtual Machine -> Emulation -> Virtual Machine Type -> VZ
Preferences -> Virtual Machine -> Emulation -> VZ Option -> Enable Rosetta support
Preferences -> Virtual Machine -> Emulation -> VZ Option -> Enable Rosetta support
Preferences -> Container Engine -> General -> dockerd
```

## aws cli

- 複数プロジェクト、かつそれぞれ環境事に切り替えていく場合に備えてprofileの命名は`{AWSアカウント名省略}-{環境}`とする

### rc file

- `~/.bashrc or ~/.zshrc`に`AWS_DEFAULT_PROFILE`と`AWS_DEFAULT_REGION`に普段作業する開発環境向けの値を指定する事を推奨
  - これらの環境変数をセットする事でawsコマンドの省略、またはエラー回避ができる様になる
    - region: 指定するようにプロンプトされなくなる
    - profile: default profileを設定していない状態でawsコマンドを実行するとprofileの設定が必要という旨のエラーが発生する
  - 事故を防止する為、普段作業する環境とは異なる環境を操作する際は`--profile`引数で指定するようにする事で操作対象のAWSアカウントを明示的にしながら作業する事を推奨

``` bash
# 普段開発するprofileとregionを指定
# ~/.bashrc or ~/.zshrc, etc.
export AWS_DEFAULT_PROFILE="xev-vpp-evems-dev"
export AWS_DEFAULT_REGION="ap-northeast-1"
```

### aws configure

- aws configureでプロファイルを設定する

``` bash
export AWS_DEFAULT_REGION="ap-northeast-1"
# sso start urlを入れる
SSO_START_URL="<https://xxxxxxxxxx.awsapps.com/start/>"

# 以下は各アカウント毎に実施する

# 対象となるアカウントIDを入れる
AWS_ACCOUNT_ID="1234567890"
# sso role nameを入れる（sso start urlを踏んだ先で表示されるもの）
ROLE_NAME="AdministratorAccess"
# 作成するプロファイル名を入れる
PROFILE_NAME="xev-vpp-evems-dev"
aws configure --profile "${PROFILE_NAME}" set sso_start_url "${SSO_START_URL}"
aws configure --profile "${PROFILE_NAME}" set sso_region "${AWS_DEFAULT_REGION}"
aws configure --profile "${PROFILE_NAME}" set sso_account_id "${AWS_ACCOUNT_ID}"
aws configure --profile "${PROFILE_NAME}" set sso_role_name "${ROLE_NAME}"
aws sso login --profile "${PROFILE_NAME}"

# 以降は以下のコマンドなどで作成済みのプロファイルにログインが可能
aws sso login --profile xev-vpp-evems-dev
aws sso login --profile xev-vpp-evems-test
aws sso login --profile xev-vpp-evems-stg
aws sso login --profile xev-vpp-evems-sdbx
aws sso login --profile xev-vpp-doms-dev
```

## git

- .gitignoreが設定されていなければ設定する

```
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## gh

- `gh`を使う事でリポジトリの`git clone, git pull, git push`をできるようにするまでの手順の簡略化に加え、以下の用途でも使える
  - リポジトリの初期セットアップ自動化スクリプトの実行
  - リポジトリの情報の取得が必要となる運用業務自動化スクリプト
  - GitHub ActionsのE2Eテストスクリプト
  - PRの作成の自動化スクリプト

### gh auth login

- 以下のディレクトリがdevcontainerとバインドされている以上はdevcontainer上での実行でもネイティブ実行でもログインのセッションは共有される
  - `~/.ssh`
  - `~/.config/gh`
  - `~/.gitconfig`

``` bash
gh auth login
```

- 以下のように回答する
  - What account do you want to log into? `GitHub.com`
  - What is your preferred protocol for git operations on this host? `SSH`
  - Upload your SSH public key to your GitHub account?
    - SSH public keyが作成されていない場合:
      - Generate a new SSH key to add to your GitHub account? (Y/n) `Y`
      - 以降はoptionalなのでお好みで設定
    - GitHub用にすでに作成してある場合はそれを指定する
  - How would you like to authenticate GitHub CLI? `Login with a web browser`
    - 以降はプロンプトの指示に従う
