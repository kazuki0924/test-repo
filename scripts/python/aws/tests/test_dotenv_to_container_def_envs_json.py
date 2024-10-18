"""Tests for dotenv_to_container_def_envs_json.py."""

from __future__ import annotations

import io
import json
from typing import TYPE_CHECKING

import pytest

from scripts.python.aws.dotenv_to_container_def_envs_json import (
    dotenv_to_tf_external_json,
)

if TYPE_CHECKING:
    from pathlib import Path

    import pytest_mock


def get_mock_logger(mocker: pytest_mock.MockFixture) -> pytest_mock.MockType:
    """Return a mock logger.

    Args:
        mocker (pytest_mock.MockFixture): Mock fixture for patching

    Returns:
        pytest_mock.MockType: Mocked logger
    """
    return mocker.patch(
        "scripts.python.aws.dotenv_to_container_def_envs_json.logger",
    )


class TestDotenvToTfExternalJsonWorks:
    """Test dotenv_to_tf_external_json works."""

    @pytest.mark.parametrize(
        ("dotenv_content", "want"),
        [
            pytest.param(
                "HOGE=hoge\nHUGA=huga",
                {
                    "env": [
                        {"name": "HOGE", "value": "hoge"},
                        {"name": "HUGA", "value": "huga"},
                    ],
                },
                id="unquoted",
            ),
            pytest.param(
                "HOGE='hoge'\nHUGA='huga'",
                {
                    "env": [
                        {"name": "HOGE", "value": "hoge"},
                        {"name": "HUGA", "value": "huga"},
                    ],
                },
                id="single quotes",
            ),
            pytest.param(
                'HOGE="hoge"\nHUGA="huga"',
                {
                    "env": [
                        {"name": "HOGE", "value": "hoge"},
                        {"name": "HUGA", "value": "huga"},
                    ],
                },
                id="double quotes",
            ),
            pytest.param(
                "HOGE='hoge'\nHUGA=\"huga\"",
                {
                    "env": [
                        {"name": "HOGE", "value": "hoge"},
                        {"name": "HUGA", "value": "huga"},
                    ],
                },
                id="single and double quotes",
            ),
            pytest.param(
                "# Comment line\nHOGE=hoge\n# Another comment",
                {
                    "env": [
                        {"name": "HOGE", "value": "hoge"},
                    ],
                },
                id="comments",
            ),
            pytest.param(
                "   \n\nHOGE=hoge  \n",
                {
                    "env": [
                        {"name": "HOGE", "value": "hoge"},
                    ],
                },
                id="blank lines and trailing spaces",
            ),
            pytest.param(
                "export HOGE=hoge\nexport HUGA=huga",
                {
                    "env": [
                        {"name": "HOGE", "value": "hoge"},
                        {"name": "HUGA", "value": "huga"},
                    ],
                },
                id="export",
            ),
            pytest.param(
                "HOGE=hoge # Inline comment",
                {
                    "env": [
                        {"name": "HOGE", "value": "hoge"},
                    ],
                },
                id="inline comment",
            ),
            pytest.param(
                "INVALID LINE",
                {"env": []},
                id="invalid line",
            ),
            pytest.param(
                "HOGE=hoge\nINVALID LINE\nHUGA=huga",
                {
                    "env": [
                        {"name": "HOGE", "value": "hoge"},
                        {"name": "HUGA", "value": "huga"},
                    ],
                },
                id="mixed valid and invalid lines",
            ),
            pytest.param(
                "",
                {"env": []},
                id="empty file",
            ),
        ],
    )
    def test_dotenv_to_tf_external_json_works(
        self,
        mocker: pytest_mock.MockFixture,
        tmp_path: Path,
        dotenv_content: str,
        want: dict[str, list[dict[str, str]]],
    ) -> None:
        """Test dotenv_to_tf_external_json() works.

        Args:
            mocker (pytest_mock.MockFixture): Mock fixture for patching
            tmp_path (Path): Temporary path fixture
            dotenv_content (str): Content of the dotenv file
            want (dict[str, list[dict[str, str]]]): Expected json string
        """
        dotenv_file = tmp_path / ".env"
        dotenv_file.write_text(dotenv_content)

        mock_stdout_write = mocker.patch("sys.stdout.write")

        dotenv_to_tf_external_json(str(dotenv_file))

        mock_stdout_write.assert_called_once()

        # argument passed to sys.stdout.write
        json_output = mock_stdout_write.call_args[0][0]

        output_env_vars = json.loads(json_output)
        assert output_env_vars == want


# class TestDotenvToTfExternalJsonErrors:
#     """Test dotenv_to_tf_external_json errors."""

#     @pytest.mark.parametrize(
#         ("exception", "side_effect", "error_message"),
#         [
#             pytest.param(
#                 FileNotFoundError,
#                 FileNotFoundError,
#                 "FileNotFoundError",
#                 id="file_not_found",
#             ),
#             pytest.param(
#                 PermissionError,
#                 PermissionError,
#                 "PermissionError",
#                 id="permission_error",
#             ),
#             pytest.param(
#                 UnicodeError,
#                 UnicodeError,
#                 "UnicodeError",
#                 id="unicode_error",
#             ),
#             pytest.param(
#                 IsADirectoryError,
#                 IsADirectoryError,
#                 "IsADirectoryError",
#                 id="is_a_directory_error",
#             ),
#             pytest.param(OSError, OSError, "OSError", id="os_error"),
#         ],
#     )
#     def test_errors(
#         self,
#         mocker: pytest_mock.MockFixture,
#         exception: type[Exception],
#         side_effect: Exception,
#         error_message: str,
#     ) -> None:
#         """Test that exceptions are raised and logged correctly.

#         Args:
#             mocker (pytest_mock.MockFixture): Mock fixture for patching
#             exception (type[Exception]): Expected exception type
#             side_effect (Exception): Exception side effect to simulate
#             error_message (str): Expected error message
#         """
#         mock_logger = get_mock_logger(mocker)
#         mocker.patch("pathlib.Path.open", side_effect=side_effect)

#         with pytest.raises(exception):
#             dotenv_to_tf_external_json("some_file.env")

#         mock_logger.exception.assert_called_once_with(
#             "%s: io operation failed.",
#             error_message,
#         )


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
    return tmp_path_factory.getbasetemp()


class TestDotenvToTfExternalJsonErrors:
    """Test dotenv_to_tf_external_json errors."""

    def test_file_not_found_error(
        self,
        tmpfiles: Path,
        mocker: pytest_mock.MockFixture,
    ) -> None:
        """Test FileNotFoundError is raised and logged."""
        nonexistent_file = tmpfiles / "nonexistent_file.env"
        mock_logger = get_mock_logger(mocker)

        with pytest.raises(FileNotFoundError):
            dotenv_to_tf_external_json(str(nonexistent_file))

        mock_logger.exception.assert_called_once_with(
            "%s: io operation failed.",
            "FileNotFoundError",
        )

    def test_permission_error(
        self,
        tmpfiles: Path,
        mocker: pytest_mock.MockFixture,
    ) -> None:
        """Test PermissionError is raised and logged."""
        no_permissions_file = tmpfiles / "no_permissions.env"
        no_permissions_file.touch(0o000)  # Create file with no permissions
        mock_logger = get_mock_logger(mocker)

        with pytest.raises(PermissionError):
            dotenv_to_tf_external_json(str(no_permissions_file))

        mock_logger.exception.assert_called_once_with(
            "%s: io operation failed.",
            "PermissionError",
        )

    def test_is_a_directory_error(
        self,
        tmpfiles: Path,
        mocker: pytest_mock.MockFixture,
    ) -> None:
        """Test IsADirectoryError is raised when trying to read a directory."""
        dir_path = tmpfiles / "directory"
        mock_logger = get_mock_logger(mocker)

        with pytest.raises(IsADirectoryError):
            dotenv_to_tf_external_json(str(dir_path))

        mock_logger.exception.assert_called_once_with(
            "%s: io operation failed.",
            "IsADirectoryError",
        )

    def test_unicode_error(
        self,
        tmpfiles: Path,
        mocker: pytest_mock.MockFixture,
    ) -> None:
        """Test UnicodeError is raised when file has invalid encoding."""
        invalid_encoding_file = tmpfiles / "invalid_encoding.env"
        invalid_encoding_file.write_bytes(b"\x80abc")  # Write invalid UTF-8
        mock_logger = get_mock_logger(mocker)

        with pytest.raises(UnicodeError):
            dotenv_to_tf_external_json(str(invalid_encoding_file))

        mock_logger.exception.assert_called_once_with(
            "%s: io operation failed.",
            "UnicodeError",
        )

    def test_io_unsupported_operation(
        self,
        tmpfiles: Path,
        mocker: pytest_mock.MockFixture,
    ) -> None:
        """Test io.UnsupportedOperation is raised when file is not readable."""
        dotenv_file = tmpfiles / "no_permissions.env"
        dotenv_file.write_text("HOGE=hoge")
        mock_logger = get_mock_logger(mocker)

        with (
            pytest.raises(io.UnsupportedOperation),
            dotenv_file.open("w") as f,
        ):  # Opening in write mode
            dotenv_to_tf_external_json(str(f))  # Passing the file handle

        mock_logger.exception.assert_called_once_with(
            "%s: io operation failed.",
            "UnsupportedOperation",
        )
