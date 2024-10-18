#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "pydantic>=2.9.0",
# ]
# ///
# ruff: noqa: S404 S603
"""Generate GitHub Actions strategy matrix.

- GitHub ActionsでのCI/CDのためのstrategy matrixをJSON形式で標準出力に出力する.
"""

# TODO: use pydantic validator and serialize data

from __future__ import annotations

import logging
import os
import subprocess
import sys
from fnmatch import fnmatch
from pathlib import Path
from subprocess import CalledProcessError

from pydantic import BaseModel


# ref: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow
class Job(BaseModel):
    """GitHub Actions strategy matrix job info."""

    # jobの実行ディレクトリの相対パス
    # e.g.
    # terragrunt run-all apply: src/subdomain1/microservice1/infra, infra
    # docker build: src/subdomain1/microservice1, baseimage
    workdir_relative_path: str
    # 実行ディレクトリ名
    # ディレクトリ名からマイクロサービス名を取得するためなどに使用
    work_dirname: str


class GitHubActionsStrategyMatrix(BaseModel):
    """GitHub Actions strategy matrix."""

    jobs: list[Job]


LOG_LEVEL = (
    logging.DEBUG
    if os.getenv("DEBUG_MODE", default="false").lower() == "true"
    else logging.INFO
)

logging.basicConfig(format="%(message)s", level=LOG_LEVEL)
logger = logging.getlogger(__name__)

GIT_DIFF_FROM_BRANCH = os.getenv("GIT_DIFF_FROM_BRANCH", default="dev")
GIT_DIFF_TO_BRANCH = os.getenv("GIT_DIFF_TO_BRANCH", default="feat/hoge")
GIT_DIFF_NAMES_ONLY_TARGET_PATHS = os.getenv(
    "GIT_DIFF_NAMES_ONLY_TARGET_PATHS",
    default="src,infra",
)
WORKDIRS_GLOB_PATTERNS = os.getenv(
    "WORKDIRS_GLOB_PATTERNS",
    default="src/*/*/infra,infra",
)
WORKDIRS_IGNORE_GLOB_PATTERNS = os.getenv(
    "WORKDIRS_IGNORE_GLOB_PATTERNS",
    default="**/examples,**/docs",
)
GITHUB_ACTIONS_STRATEGY_MATRIX_GLOB_PATTERNS = os.getenv(
    "GITHUB_ACTIONS_STRATEGY_MATRIX_GLOB_PATTERNS",
    # example for ci_app_docker_build_push.yml
    default="*.py,*requirements*.txt,Dockerfile,*ecr*.tf",
)
GITHUB_ACTIONS_STRATEGY_MATRIX_IGNORE_GLOB_PATTERNS = os.getenv(
    "GITHUB_ACTIONS_STRATEGY_MATRIX_IGNORE_GLOB_PATTERNS",
    # example for ci_app_docker_build_push.yml
    default="*.md,*.log,*_generated.*",
)


def create_list_from_gh_actions_env_vars(input_string: str) -> list[str]:
    """GitHub Actionsから渡される環境変数をpythonのlist[str]に変換.

    Args:
    ----
        input_string (str): comma-delimited string

    Returns:
    -------
        list[str]: list of strings

    """
    created_list = (
        [item.strip() for item in input_string.split(",")]
        if "," in input_string
        else [input_string.strip()]
    )

    logger.debug("create_list_from_gh_actions_env_vars results: %s", created_list)
    return created_list


def find_dirs_by_glob(
    root: Path = Path(),
    glob_patterns: list[str] | None = None,
    ignore_glob_patterns: list[str] | None = None,
) -> list[str]:
    """指定のパターンでディレクトリ一覧を取得.

    Args:
    ----
        root (Path): root path to search from
        glob_patterns (list[str]):
            list of glob patterns for searching directories
        ignore_glob_patterns (list[str]):
            list of glob patterns for ignoring directories

    Returns:
    -------
        list[str]: list of directories that match the patterns

    """
    paths: list[Path | str] = []

    if glob_patterns:
        paths = [
            path
            for pattern in glob_patterns
            for path in root.glob(pattern)
            if path.is_dir()
        ]
    else:
        paths = ["."]

    if ignore_glob_patterns:
        paths = [
            path
            for path in paths
            if not any(
                fnmatch(str(path), ignore_pattern)
                for ignore_pattern in ignore_glob_patterns
            )
        ]

    dirs = sorted(
        [str(path).removeprefix(str(root) + os.sep) for path in paths],
    )
    logger.debug("find_dirs_by_glob results: %s", dirs)
    return dirs


def get_git_diff_filenames(
    git_ref_compared_from: str,
    git_ref_compared_to: str,
    paths: list[str] | None = None,
) -> list[str]:
    """2つのgit ref間で変更されたファイル一覧を取得.

    Args:
    ----
        ref_a (str): git ref being compared from
        ref_b (str): git ref being compared to
        paths (list[str] | None): list of paths to compare

    Returns:
    -------
        list[str]: list of files that changed

    Raises:
    ------
        CalledProcessError: git diff command failed

    """
    try:
        cmd = [
            "/usr/bin/env",
            "git",
            "diff",
            "--name-only",
            git_ref_compared_from,
            git_ref_compared_to,
        ]
        if paths:
            cmd.extend(["--"])
            cmd += paths

        result = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
            shell=False,
        )

        files = [file.strip() for file in result.stdout.split("\n") if file]
        logger.debug("get_git_diff_filenames results: %s", files)
    except CalledProcessError:
        logger.exception("CalledProcessError: git diff command failed.")
        raise
    else:
        return files


def filter_files_by_glob(
    files: list[str],
    glob_patterns: list[str] | None = None,
    ignore_glob_patterns: list[str] | None = None,
) -> list[str]:
    """指定のパターンでファイル一覧をフィルター.

    Args:
    ----
        files (list[str]): list of files
        all_workdirs (list[str]): list of all workdirs
        glob_patterns (list[str]): list of glob patterns
        ignore_glob_patterns (list[str]): list of glob ignore patterns

    Returns:
    -------
        list[str]: list of files that match the patterns

    """
    filtered_files: list[str] = []

    if glob_patterns:
        for file in files:
            if any(fnmatch(file, pattern) for pattern in glob_patterns):
                filtered_files += [file]
    else:
        filtered_files = files

    if ignore_glob_patterns:
        filtered_files = [
            file
            for file in filtered_files
            if not any(
                fnmatch(
                    file,
                    ignore_pattern,
                )
                for ignore_pattern in ignore_glob_patterns
            )
        ]

    logger.debug("filter_files_by_glob results: %s", filtered_files)
    return filtered_files


def get_changed_workdirs(
    all_workdirs: list[str],
    files: list[str],
) -> list[str]:
    """変更されたファイルが含まれるworkdirs一覧を返却.

    Args:
    ----
        all_workdirs (list[str]): list of all workdirs
        files (list[str]): list of files

    Returns:
    -------
        list[str]: list of workdirs that has changed files

    """
    workdirs = sorted(
        [
            workdir
            for workdir in all_workdirs
            if any(file.startswith(workdir) for file in files) and workdir
        ],
    )
    logger.debug("get_changed_workdirs results: %s", workdirs)
    return workdirs


def output_github_actions_strategy_matrix_to_stdout_as_json(
    workdirs: list[str],
) -> None:
    """GitHub Actions strategy matrixをJSON形式でstdoutに出力.

    Args:
    ----
        workdirs (list[str]): list of workdirs

    """
    jobs = [
        Job(
            workdir_relative_path=workdir,
            work_dirname=Path(workdir).name if "/" in workdir else workdir,
        )
        for workdir in workdirs
    ]

    strategy_matrix = GitHubActionsStrategyMatrix(jobs=jobs)
    logger.debug(
        "output_github_actions_strategy_matrix_to_stdout_as_json results: %s",
        strategy_matrix,
    )
    sys.stdout.write(strategy_matrix.model_dump_json())


def main() -> None:
    """Entry point."""
    try:
        all_workdirs = find_dirs_by_glob(
            Path(),
            create_list_from_gh_actions_env_vars(
                WORKDIRS_GLOB_PATTERNS,
            ),
            create_list_from_gh_actions_env_vars(
                WORKDIRS_IGNORE_GLOB_PATTERNS,
            ),
        )

        changed_files = get_git_diff_filenames(
            git_ref_compared_from=GIT_DIFF_FROM_BRANCH,
            git_ref_compared_to=GIT_DIFF_TO_BRANCH,
            paths=create_list_from_gh_actions_env_vars(
                GIT_DIFF_NAMES_ONLY_TARGET_PATHS,
            ),
        )

        filtered_files = filter_files_by_glob(
            changed_files,
            create_list_from_gh_actions_env_vars(
                GITHUB_ACTIONS_STRATEGY_MATRIX_GLOB_PATTERNS,
            ),
            create_list_from_gh_actions_env_vars(
                GITHUB_ACTIONS_STRATEGY_MATRIX_IGNORE_GLOB_PATTERNS,
            ),
        )

        changed_workdirs = get_changed_workdirs(all_workdirs, filtered_files)
        output_github_actions_strategy_matrix_to_stdout_as_json(
            changed_workdirs,
        )
    # main()でのみbroad exceptionを許可する
    except Exception:  # pylint: disable=broad-exception-caught
        logger.exception("Error:")
        sys.exit(1)


if __name__ == "__main__":
    main()
