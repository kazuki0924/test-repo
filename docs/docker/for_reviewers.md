# General Design Decisions

## glossary

- ephemeral compute tools: 実行後に破棄される環境。CI/CDにおけるjobなどが該当

## cache

- opinionated(versions): インストールするツールのバージョンは固定して記述する
  - docker buildはDockerfileの変更が無かった行をdocker build cacheとして再利用可能にしてくれる
    - `FORM句`から変更があった行までの間のレイヤーはdocker build cache化され、build時間の短縮が図れる
      - 行は`ADD/COPY句`だけ参照先のファイルサイズや最終変更日時を基に変更可否が判断され、それ以外は行の文字列だけが見られる
    - そのため、`COPY句`はなるべくDockerfileの中でも後の方に記述することで、キャッシュのヒット率を上げる事ができる
      - ただし、これは`apt-get update`などのパッケージをインストールするコマンドの行が変わらない限りは古いキャッシュを使い続けるという事でもある
        - 場合によってはそれによりローカル開発環境とリモート開発環境（GitHub Actions内、AWS dev環境内、等）で環境差異が生じ、実行時エラーなどが起こる恐れがある
      - 上記の問題が起こらないようにする為に極力、インストールするツールのバージョンは固定して記述する
- opinionated(remote cache): cache exportersは基本的に`registry`かつECRを指定する
  - 通常であればephemeral compute toolsでdocker buildをした場合、docker build cacheは作られるものの、ジョブの終了時に実行コンテナもろとも破棄されてしまうので再利用が出来ない
  - docker buildx（Docker Engine 25.0以降はデフォルトで有効）のcache exportersを使う事で、docker build cacheを外部に保存してCI/CDで再利用する事が可能となっている
  - 基本的にはcache exportersは`registry`かつECRを指定する
    - ref: [Announcing remote cache support in Amazon ECR for BuildKit clients](
      https://aws.amazon.com/jp/blogs/containers/announcing-remote-cache-support-in-amazon-ecr-for-buildkit-clients/
    )
    - ただし、ローカル開発環境の場合だと都度AWSとの認証が求められる事になるため、cache exportersの利用は任意となっている事が望ましい
