#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# テンプレートから指定の.gitignoreを生成させるスクリプト

# gitignore.ioを活用
# https://www.toptal.com/developers/gitignore

if [[ ! -f .gitignore ]]; then
  touch .gitignore
fi

echo "writing to .gitignore...(this may take 1+ minutes, please wait)"

MANUALLY_ADDED="$(sed -n -e '/# manually added #/,$p' .gitignore)"
readonly MANUALLY_ADDED

cat << EOF > .gitignore
# ---------- generated: start ----------

# 以下はスクリプトによってgitignore.ioから取得したテンプレート
# 最新化の為の取得スクリプトの再実行で全て上書きされる為、直接編集するのは禁止
# 追記する場合は他のテンプレートの内容によって反転されない為にもテンプレート群より下に追記する

# テンプレート一覧は以下から取得可能
# https://docs.gitignore.io/use/api

# fetched from: https://www.toptal.com/developers/gitignore via bash script

EOF

TARGETS=(
  "dotenv"
  "terraform"
  "terragrunt"
  "jsonnet"
  "python"
  "testinfra"
  "matlab"
  "node"
  "react"
  "reactnative"
  "vuejs"
  "nuxtjs"
  "go"
  "java"
  "maven"
  "gradle"
  "groovy"
  "lua"
  "zsh"
  "fish"
  "macos"
  "windows"
  "linux"
  "nohup"
  "backup"
  "ssh"
  "batch"
  "certificates"
  "diskimage"
  "direnv"
  "git"
  "gpg"
  "firebase"
  "redis"
  "ansible"
  "visualstudiocode"
  "jetbrains+all"
  "eclipse"
  "vim"
  "emacs"
  "localstack"
  "sam+config"
  "snyk"
)
readonly TARGETS

for TARGET in "${TARGETS[@]}"; do
  curl -sL "https://www.gitignore.io/api/${TARGET}" >> .gitignore
  echo "${TARGET} finished."
done

cat << EOF >> .gitignore

# ---------- generated: end ----------

# これより上は最新gitignoreテンプレート取得スクリプトの実行で上書きされる為、直接編集するのは禁止
# 上記で指定されている対象を反転させる場合には!を先頭に付与して以下に追記する

EOF

if [[ "${MANUALLY_ADDED}" != "" ]]; then
  echo "${MANUALLY_ADDED}" >> .gitignore
elif ! grep -q "# manually added #" .gitignore; then
  cat << EOF >> .gitignore
# manually added #
EOF
fi

echo "done."
