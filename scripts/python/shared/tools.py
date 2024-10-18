"""Util functions for .tools.json."""

import io
import json
from enum import StrEnum
from json import JSONDecodeError
from pathlib import Path

import pydantic
from pydantic import BaseModel, ValidationError

from .logger import get_logger

logger = get_logger(__name__)


class VersionFrom(StrEnum):
    """Enum for specifying where to get the latest version from."""

    LATEST_TAG = "latest-tag"
    LATEST_RELEASE = "latest-release"
    NOOP = "noop"


class Tool(BaseModel):
    """An item in .tools.json."""

    name: str  # tool name
    command: str  # command to check path
    repository: str  # repository URL
    version_env: str  # environment variable to store the tool's version
    pinned_version: str  # pinned version
    version_from: VersionFrom  # where to get the latest version from
    ignore_pattern: list[str]  # ignore pattern to filter out the version
    version_option: str  # command option to get version
    bad_option: str  # command option that errors(returns non-zero exit code)
    bad_option_message: str  # message to check a partial match of the error message
    tags: list[str]  # optional tags to categorize the tools
    priority: int  # priority to sort the tools in ascending order


def load_tools_json(file: str = ".tools.json") -> list[Tool]:
    """
    Load JSON file and return a list of Tool objects.

    Args:
        file (str): The path of the JSON file to load. Defaults to ".tools.json".

    Returns:
        list[Tool]: A list of Tool objects loaded from the JSON file.

    Raises:
        FileNotFoundError: If the file does not exist.
        PermissionError: If the file cannot be opened.
        IsADirectoryError: If the file is a directory.
        UnicodeError: If the file cannot be decoded.
        io.UnsupportedOperation: If the file is not readable.
        OSError: If the file operation fails.
        ValidationError: If the file does not match the Tool schema.
        JSONDecodeError: If the file is not a valid JSON.
    """
    try:
        with Path(file).open("r", encoding="utf-8") as f:
            tools = pydantic.TypeAdapter(list[Tool]).validate_python(json.load(f))
            logger.debug("load_tools_json results: %s", tools)
            return tools
    except (
        FileNotFoundError,
        PermissionError,
        IsADirectoryError,
        UnicodeError,
        io.UnsupportedOperation,
        OSError,
    ) as e:
        logger.exception("%s: io operation failed.", e.__class__.__name__)
        raise
    except ValidationError as e:
        logger.exception(
            "%s: pydantic.TypeAdapter().validate_python() failed.",
            e.__class__.__name__,
        )
        raise
    except JSONDecodeError as e:
        logger.exception("%s: json.load() failed.", e.__class__.__name__)
        raise
