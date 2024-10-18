"""Tests for create_generate_strategy_matrix.py."""

from __future__ import annotations

from subprocess import CalledProcessError
from typing import TYPE_CHECKING

import pytest

from scripts.python.github_actions.generate_strategy_matrix import (
    create_list_from_gh_actions_env_vars,
    filter_files_by_glob,
    find_dirs_by_glob,
    get_changed_workdirs,
    get_git_diff_filenames,
    output_github_actions_strategy_matrix_to_stdout_as_json,
)

if TYPE_CHECKING:
    from pathlib import Path

    import pytest_mock

TEST_DATA_PATHS = [
    "src/subdomain1/microservice1/hoge.py",
    "src/subdomain1/microservice2/Dockerfile",
    "src/subdomain1/microservice2/hoge.txt",
    "src/subdomain1/stub/stub.py",
    "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
    "src/subdomain2/microservice4/huga.txt",
    "infra/terraform/aws/modules/hoge/hoge.tf",
    "hoge.txt",
    "huga.txt",
]


def get_mock_logger(mocker: pytest_mock.MockFixture) -> pytest_mock.MockType:
    """Return a mock logger.

    Args:
    ----
        mocker (pytest_mock.MockFixture): Mock fixture for patching

    Returns:
    -------
        pytest_mock.MockType: Mocked logger

    """
    return mocker.patch("scripts.python.github_actions.generate_strategy_matrix.logger")


# ref: https://docs.pytest.org/en/stable/how-to/tmp_path.html
@pytest.fixture(scope="session")
def tmpfiles(tmp_path_factory: pytest.TempPathFactory) -> Path:
    """Fixture to create temporary files.

    Args:
    ----
        tmp_path_factory (pytest.TempPathFactory): Pytest fixture for temporary paths

    Returns:
    -------
        Path: Temporary directory

    """
    basetemp = tmp_path_factory.getbasetemp()
    for path in TEST_DATA_PATHS:
        full_path = basetemp / path
        full_path.parent.mkdir(parents=True, exist_ok=True)
        full_path.touch()
    return basetemp


def test_fixtures_tmpfiles(tmpfiles: Path) -> None:  # pylint: disable=redefined-outer-name
    """Test tmpfiles fixture works.

    Args:
    ----
        tmpfiles (Path): Path to the base temporary directory

    """
    for path in TEST_DATA_PATHS:
        assert (tmpfiles / path).exists()


@pytest.mark.parametrize(
    ("input_string", "want"),
    [
        pytest.param(
            "src/*/*/infra,infra",
            ["src/*/*/infra", "infra"],
            id="comma-delimited list",
        ),
        pytest.param(
            "src/*/*/infra, infra",
            ["src/*/*/infra", "infra"],
            id="comma + space separated list",
        ),
        pytest.param(
            '"src/*/*/infra","infra"',
            ['"src/*/*/infra"', '"infra"'],
            id="quotes escaped",
        ),
        pytest.param(
            "src/*/*",
            ["src/*/*"],
            id="a string",
        ),
        pytest.param(
            "",
            [""],
            id="empty string",
        ),
    ],
)
def test_create_list_from_gh_actions_env_vars(
    input_string: str,
    want: list[str],
) -> None:
    """Test parsing of GitHub Actions environment variables into a list.

    Args:
    ----
        input_string (str): Input string from environment variable
        want (list[str]): Expected list after parsing

    """
    assert create_list_from_gh_actions_env_vars(input_string) == want


@pytest.mark.parametrize(
    ("glob_patterns", "ignore_glob_patterns", "want"),
    [
        pytest.param(
            ["src/*/*"],
            None,
            [
                "src/subdomain1/microservice1",
                "src/subdomain1/microservice2",
                "src/subdomain1/stub",
                "src/subdomain2/microservice3",
                "src/subdomain2/microservice4",
            ],
            id="glob_pattern: wildcard",
        ),
        pytest.param(
            ["src/subdomain1/stub"],
            None,
            ["src/subdomain1/stub"],
            id="glob_pattern: exact match",
        ),
        pytest.param(
            ["infra", "src/*/*/infra"],
            None,
            [
                "infra",
                "src/subdomain2/microservice3/infra",
            ],
            id="glob_patterns: exact match and wildcard",
        ),
        pytest.param(
            [],
            ["**/stub"],
            ["."],
            id="ignore_glob_pattern only",
        ),
        pytest.param(
            ["src/*/*"],
            ["**/stub"],
            [
                "src/subdomain1/microservice1",
                "src/subdomain1/microservice2",
                "src/subdomain2/microservice3",
                "src/subdomain2/microservice4",
            ],
            id="glob_pattern with ignore_glob_pattern",
        ),
        pytest.param(
            ["src/subdomain1/*", "src/subdomain2/*"],
            ["**/stub"],
            [
                "src/subdomain1/microservice1",
                "src/subdomain1/microservice2",
                "src/subdomain2/microservice3",
                "src/subdomain2/microservice4",
            ],
            id="glob_patterns with ignore_glob_pattern",
        ),
        pytest.param(
            ["src/*/*"],
            ["**/stub", "**/subdomain1/**"],
            [
                "src/subdomain2/microservice3",
                "src/subdomain2/microservice4",
            ],
            id="glob_pattern with ignore_patterns",
        ),
        pytest.param(
            None,
            None,
            ["."],
            id="both glob_patterns and ignore_glob_patterns are empty",
        ),
    ],
)
def test_find_dirs_by_glob_works(
    tmpfiles: Path,  # pylint: disable=redefined-outer-name
    glob_patterns: list[str],
    ignore_glob_patterns: list[str],
    want: list[str],
) -> None:
    """Test find_dirs_by_glob() works.

    Args:
    ----
        tmpfiles (Path): Base temporary directory containing test files
        glob_patterns (list[str]): Patterns to include
        ignore_glob_patterns (list[str]): Patterns to exclude
        want (list[str]): Expected list of directories found

    """
    assert find_dirs_by_glob(tmpfiles, glob_patterns, ignore_glob_patterns) == want


@pytest.mark.parametrize(
    ("ref_a", "ref_b", "paths", "mock_stdout", "want", "want_cmd"),
    [
        pytest.param(
            "main",
            "feat/hoge",
            None,
            "src/subdomain1/microservice1/hoge.py\n\
            src/subdomain1/microservice2/Dockerfile\n\
            src/subdomain1/microservice2/hoge.txt\n\
            src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf\n\
            src/subdomain2/microservice4/huga.txt\n\
            infra/terraform/aws/modules/hoge/hoge.tf\n\
            hoge.txt\n\
            huga.txt\n",
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain1/microservice2/hoge.txt",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "src/subdomain2/microservice4/huga.txt",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
                "huga.txt",
            ],
            ["/usr/bin/env", "git", "diff", "--name-only", "main", "feat/hoge"],
            id="git diff returns multiple files",
        ),
        pytest.param(
            "main",
            "feat/hoge",
            None,
            "src/subdomain1/microservice1/hoge.py",
            ["src/subdomain1/microservice1/hoge.py"],
            ["/usr/bin/env", "git", "diff", "--name-only", "main", "feat/hoge"],
            id="git diff returns a file",
        ),
        pytest.param(
            "main",
            "feat/hoge",
            None,
            "",
            [],
            ["/usr/bin/env", "git", "diff", "--name-only", "main", "feat/hoge"],
            id="git diff returns no files",
        ),
        pytest.param(
            "main",
            "feat/hoge",
            ["src", "infra"],
            "src/subdomain1/microservice1/hoge.py\n\
            src/subdomain1/microservice2/Dockerfile\n\
            src/subdomain1/microservice2/hoge.txt\n\
            src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf\n\
            src/subdomain2/microservice4/huga.txt\n\
            infra/terraform/aws/modules/hoge/hoge.tf\n",
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain1/microservice2/hoge.txt",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "src/subdomain2/microservice4/huga.txt",
                "infra/terraform/aws/modules/hoge/hoge.tf",
            ],
            [
                "/usr/bin/env",
                "git",
                "diff",
                "--name-only",
                "main",
                "feat/hoge",
                "--",
                "src",
                "infra",
            ],
            id="git diff with paths",
        ),
    ],
)
def test_get_git_diff_filenames_works(
    mocker: pytest_mock.MockFixture,
    ref_a: str,
    ref_b: str,
    paths: list[str],
    mock_stdout: str,
    want: list[str],
    want_cmd: list[str],
) -> None:
    """Test get_git_diff_filenames() works.

    Args:
    ----
        mocker (pytest_mock.MockFixture): Fixture for mocking
        ref_a (str): First git reference
        ref_b (str): Second git reference
        paths (list[str]): Paths to limit the git diff
        mock_stdout (str): Mocked output of git diff
        want (list[str]): Expected list of filenames
        want_cmd (list[str]): Expected git command executed

    """
    mock_subprocess_run = mocker.patch("subprocess.run")
    mock_subprocess_run.return_value = mocker.Mock(stdout=mock_stdout, returncode=0)

    result = get_git_diff_filenames(ref_a, ref_b, paths)

    assert result == want
    mock_subprocess_run.assert_called_once_with(
        want_cmd,
        check=True,
        capture_output=True,
        text=True,
        shell=False,
    )


@pytest.mark.parametrize(
    ("ref_a", "ref_b", "return_code", "cmd", "want_error"),
    [
        pytest.param(
            "main",
            "feat/hoge",
            1,
            ["/usr/bin/env", "git", "diff", "--name-only", "main", "feat/hoge"],
            "CalledProcessError: git diff command failed.",
            id="raises CalledProcessError",
        ),
    ],
)
def test_get_git_diff_filenames_exceptions_calledprocesserror(
    mocker: pytest_mock.MockFixture,
    ref_a: str,
    ref_b: str,
    return_code: int,
    cmd: list[str],
    want_error: str,
) -> None:
    """Test get_git_diff_filenames() raises error.

    Args:
    ----
        mocker (pytest_mock.MockFixture): Fixture for mocking
        ref_a (str): First git reference
        ref_b (str): Second git reference
        return_code (int): Mocked return code from subprocess
        cmd (list[str]): Command that was executed
        want_error (str): Expected error message logged

    """
    mock_subprocess_run = mocker.patch(
        "subprocess.run",
        side_effect=CalledProcessError(
            cmd=cmd,
            returncode=return_code,
        ),
    )
    mock_logger = get_mock_logger(mocker)

    with pytest.raises(CalledProcessError) as e:
        get_git_diff_filenames(ref_a, ref_b)
    assert e.value.returncode == return_code

    mock_subprocess_run.assert_called_once_with(
        cmd,
        check=True,
        capture_output=True,
        text=True,
        shell=False,
    )
    mock_logger.exception.assert_called_once_with(want_error)


@pytest.mark.parametrize(
    ("files", "glob_patterns", "ignore_glob_patterns", "want"),
    [
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            ["src/subdomain1/microservice1/*"],
            [],
            ["src/subdomain1/microservice1/hoge.py"],
            id="glob_pattern: wildcard matching a file",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            ["src/*"],
            [],
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
            ],
            id="glob_pattern: wildcard matching files",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            ["infra/terraform/aws/modules/hoge/hoge.tf"],
            [],
            ["infra/terraform/aws/modules/hoge/hoge.tf"],
            id="glob_pattern: exact match",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            ["**/hoge.tf"],
            [],
            [
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
            ],
            id="glob_pattern: recursive wildcard with separater",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain1/microservice2/hoge.txt",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.txt",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            ["**hoge.txt"],
            [],
            [
                "src/subdomain1/microservice2/hoge.txt",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.txt",
                "hoge.txt",
            ],
            id="glob_pattern: recursive wildcard without separators",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain1/microservice2/hoge.txt",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.txt",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            ["src/"],
            [],
            [],
            id="glob_pattern: pattern ending with separator should have no matches",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            ["src/*", "infra/terraform/aws/modules/hoge/hoge.tf"],
            [],
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
            ],
            id="glob_patterns: wildcard and a exact match",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            ["src/*", "infra/*"],
            [],
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
            ],
            id="glob_patterns: wildcards matching files",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            ["hoge/*", "huga/*"],
            [],
            [],
            id="glob_patterns: no matching files",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain1/microservice2/hoge.txt",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "src/subdomain2/microservice4/huga.txt",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
                "huga.txt",
            ],
            [],
            ["huga.*"],
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain1/microservice2/hoge.txt",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "src/subdomain2/microservice4/huga.txt",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            id="ignore_glob_pattern: wildcard excluding a file",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain1/microservice2/hoge.txt",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "src/subdomain2/microservice4/huga.txt",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
                "huga.txt",
            ],
            [],
            ["*.txt"],
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
            ],
            id="ignore_glob_pattern: wildcard excluding files",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain1/microservice2/hoge.txt",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            [],
            ["**/hoge.*"],
            [
                "src/subdomain1/microservice2/Dockerfile",
                "hoge.txt",
            ],
            id="ignore_glob_pattern: recursive wildcard with separater",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            [],
            ["**hoge.*"],
            [
                "src/subdomain1/microservice2/Dockerfile",
            ],
            id="ignore_glob_pattern: recursive wildcard without separater",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain1/microservice2/hoge.txt",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            [],
            ["*.txt", "**/hoge.*"],
            [
                "src/subdomain1/microservice2/Dockerfile",
            ],
            id="ignore_glob_patterns: wildcard and recursive wildcard with separators",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain1/microservice2/hoge.txt",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            ["src/**/Dockerfile", "src/**/*.py"],
            ["*.txt"],
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
            ],
            id="both glob_patterns and ignore_glob_patterns: \
              recursive wildcards with separators",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            [],
            [],
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            id="both glob_patterns and ignore_glob_patterns are empty",
        ),
        pytest.param(
            [],
            ["src/*"],
            ["*.txt"],
            [],
            id="files is empty",
        ),
    ],
)
def test_filter_files_by_glob(
    files: list[str],
    glob_patterns: list[str],
    ignore_glob_patterns: list[str],
    want: list[str],
) -> None:
    """Test filter_files_by_glob() works.

    Args:
    ----
        files (list[str]): List of file paths
        glob_patterns (list[str]): Patterns to include
        ignore_glob_patterns (list[str]): Patterns to exclude
        want (list[str]): Expected list of filtered files

    """
    assert filter_files_by_glob(files, glob_patterns, ignore_glob_patterns) == want


@pytest.mark.parametrize(
    ("workdirs", "files", "want"),
    [
        pytest.param(
            [
                "src/subdomain1/microservice1",
                "src/subdomain1/microservice2",
                "src/subdomain2/microservice3",
                "src/subdomain2/microservice4",
            ],
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "hoge.txt",
            ],
            [
                "src/subdomain1/microservice1",
                "src/subdomain1/microservice2",
            ],
            id="microservices changed",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/infra",
                "src/subdomain1/microservice2/infra",
                "src/subdomain2/microservice3/infra",
                "src/subdomain2/microservice4/infra",
                "infra",
            ],
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "src/subdomain2/microservice3/infra/terraform/aws/modules/hoge/hoge.tf",
                "src/subdomain2/microservice4/infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            [
                "src/subdomain2/microservice3/infra",
                "src/subdomain2/microservice4/infra",
            ],
            id="per-microservices modules changed",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/infra",
                "src/subdomain1/microservice2/infra",
                "src/subdomain2/microservice3/infra",
                "src/subdomain2/microservice4/infra",
                "infra",
            ],
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "infra/terraform/aws/modules/hoge/hoge.tf",
                "hoge.txt",
            ],
            [
                "infra",
            ],
            id="per-repository modules changed",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/infra",
                "src/subdomain1/microservice2/infra",
                "src/subdomain2/microservice3/infra",
                "src/subdomain2/microservice4/infra",
                "infra",
            ],
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "hoge.txt",
            ],
            [],
            id="no workdirs changed",
        ),
        pytest.param(
            [],
            [
                "src/subdomain1/microservice1/hoge.py",
                "src/subdomain1/microservice2/Dockerfile",
                "hoge.txt",
            ],
            [],
            id="workdirs is empty",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1/infra",
                "src/subdomain1/microservice2/infra",
                "src/subdomain2/microservice3/infra",
                "src/subdomain2/microservice4/infra",
                "infra",
            ],
            [],
            [],
            id="files is empty",
        ),
    ],
)
def test_get_changed_workdirs(
    workdirs: list[str],
    files: list[str],
    want: list[str],
) -> None:
    """Test get_changed_workdirs() works.

    Args:
    ----
        workdirs (list[str]): List of work directories to check
        files (list[str]): List of changed files
        want (list[str]): Expected list of changed work directories

    """
    assert get_changed_workdirs(workdirs, files) == want


@pytest.mark.parametrize(
    ("workdirs", "want"),
    [
        pytest.param(
            [
                "infra",
            ],
            '{"jobs":[{"workdir_relative_path":"infra","work_dirname":"infra"}]}',
            id="per-repository modules",
        ),
        pytest.param(
            [
                "src/subdomain1/microservice1",
                "src/subdomain1/microservice2",
            ],
            '{"jobs":[\
{"workdir_relative_path":"src/subdomain1/microservice1","work_dirname":"microservice1"},\
{"workdir_relative_path":"src/subdomain1/microservice2","work_dirname":"microservice2"}\
]}',
            id="per-microservice modules",
        ),
        pytest.param(
            [
                "infra",
                "src/subdomain1/microservice1",
            ],
            '{"jobs":[\
{"workdir_relative_path":"infra","work_dirname":"infra"},\
{"workdir_relative_path":"src/subdomain1/microservice1","work_dirname":"microservice1"}\
]}',
            id="both per-repository and per-microservice modules",
        ),
        pytest.param(
            [],
            '{"jobs":[]}',
            id="no workdir",
        ),
    ],
)
def test_output_github_actions_strategy_matrix_to_stdout_as_json(
    mocker: pytest_mock.MockFixture,
    workdirs: list[str],
    want: str,
) -> None:
    """Test output_github_actions_strategy_matrix_to_stdout_as_json() works."""
    mock_stdout_write = mocker.patch("sys.stdout.write")

    output_github_actions_strategy_matrix_to_stdout_as_json(workdirs)
    mock_stdout_write.assert_called_once_with(want)
