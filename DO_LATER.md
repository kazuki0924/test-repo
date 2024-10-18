# DO_LATER

- release-pleaseのrelease PRの向き先を"商用環境"に向ける為にメインブランチはprodにする？
- 毎回手動でdevに向けさせるのが面倒であればPR作成時に自動でdraft状態にし、かつ、devにそもそも取り込まれていないcommitがあるのであればまずdevに向く様にする、など
- prodにマージされてもデプロイは行わないようにする？pull pushのみ？←要検討
- trivyとtflintをセットアップする（pre-commit, cicd）
- install bats-libs
- for aws_nuke, accept arguments to skip certain resources by names
- install git from source <https://git-scm.com/book/it/v2/Per-Iniziare-Installing-Git>
- Add API Gateway, Cognito, VPCLink, NewRelic Sidecar Container
- Add SSM Parameter Store(NewRelic API Key), CloudTrail, AWS Backup, etc.
