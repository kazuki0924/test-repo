# project setup

- 前提: `local_environment_setup.md`の手順をすべて完了していること

## OIDCプロバイダー/IAMロール作成スクリプトの実行

- OIDCプロバイダーが作成済みの場合はOIDCプロバイダー作成部分はスキップされる
- このスクリプトで作成されるIAMロールの設定は仮である為、後の工程でterraformでimportをし設定を上書きする想定
  - 初回のGitHub ActionsとAWSの認証を行う為に強い権限（AdministratorAccess）と広いリポジトリ対象の設定となっている
  - 本番環境ではAdministratorAccessより弱い権限にする事は推奨（Should）であるが必須（Must）ではない
  - リポジトリ対象に"*"を使用する事はセキュリティチェックツール（trivy等）で引っかかってしまう為、terraformで構成管理して対象を絞る事は必須
- 実行後は念の為、マネコンの「IAM」からIAMロールが作成されている事を確認するを推奨

以下のように環境名、システム名、対象となるポジトリのglobパターン、AWSリージョンを引数として渡して実行する

``` bash
# オプションの詳細は以下のコマンドを実行して表示
# $ bash ./scripts/bash/aws/iam_oidc_provider_and_role_for_github_action.sh --help
bash ./scripts/bash/aws/iam_oidc_provider_and_role_for_github_action.sh --prefix=xev-vpp-evems-dev
```
