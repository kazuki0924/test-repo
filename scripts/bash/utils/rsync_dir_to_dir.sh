#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

echo "rsync_dir_to_dir.sh started."

usage() {
  cat << EOF
NAME

  rsync_dir_to_dir

DESCRIPTION

  rsync a directory to another directory excluding .git

SYNOPSIS

  rsync_dir_to_dir [-h] [-t to] [-f from]

OPTIONS

  -h | --help: このヘルプの表示
  -t, --to [DIR]: コピー先のディレクトリの指定 e.g. -t ~/workspace/temp, --to=~/workspace/temp
  -f, --from [DIR]: コピー元のディレクトリの指定 e.g. -f ~/workspace, --from=~/workspace
EOF
}

# dependencies
REQUIREMENTS=(
  "rsync"
)

for CMD in "${REQUIREMENTS[@]}"; do
  if ! command -v "${CMD}" &> /dev/null; then
    echo "Error: ${CMD} is not installed." >&2
    exit 1
  fi
done

SOURCE=""
DESTINATION=""

# args
ARGS=("$@")
INDEX_TO_SKIP=""
for i in "${!ARGS[@]}"; do
  FLAG="${ARGS["${i}"]}"
  if [[ "${i}" == "${INDEX_TO_SKIP}" ]]; then
    continue
  fi
  case "${FLAG}" in
    -h | --help)
      usage
      exit 0
      ;;
    --to=*)
      DESTINATION="${FLAG#*=}"
      ;;
    -t | --to)
      INDEX_TO_SKIP="$((i + 1))"
      ARGS_LENGTH="${#ARGS[@]}"
      if [[ "${INDEX_TO_SKIP}" -lt "${ARGS_LENGTH}" ]]; then
        NEXT_ARG="${ARGS["${INDEX_TO_SKIP}"]}"
        DESTINATION="${NEXT_ARG}"
      fi
      ;;
    --from=*)
      SOURCE="${FLAG#*=}"
      ;;
    -f | --from)
      INDEX_TO_SKIP="$((i + 1))"
      ARGS_LENGTH="${#ARGS[@]}"
      if [[ "${INDEX_TO_SKIP}" -lt "${ARGS_LENGTH}" ]]; then
        NEXT_ARG="${ARGS["${INDEX_TO_SKIP}"]}"
        SOURCE+="${NEXT_ARG}"
      fi
      ;;
  esac
done

rsync --archive --verbose --exclude=".git" --exclude="*local.*" "${SOURCE}" "${DESTINATION}"
echo "rsync_dir_to_dir.sh completed."
