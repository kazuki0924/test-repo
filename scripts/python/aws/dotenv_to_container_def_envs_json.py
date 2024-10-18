#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
"""
Output containerDefinitions[*].environment JSON to stdout from dotenv file.

指定の.envファイルを読み込み、以下のJSON形式で標準出力に出力する.
- ECS Task Definition Parameter - Container Definition: environment
- ref: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions

To log debug level messages, set the DEBUG_MODE environment variable to true.
e.g.
export DEBUG_MODE=true
./scripts/python/aws/dotenv_to_container_def_envs_json.py ./src/.env.defaults
"""

import io
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))

from shared.logger import get_logger
from shared.utils import parse_filepath_from_args

logger = get_logger(__name__)

DEFAULT_DOTENV_PATH = "./src/.env.defaults"
DESCRIPTION = (
    "Output containerDefinitions[*].environment JSON to stdout from dotenv file."
)


@dataclass
class EnvVar:
    """Container Definition environment variable."""

    name: str
    value: str


def dotenv_to_tf_external_json(file: str) -> None:
    """
    Parse the given dotenv file and return the environment variables in JSON format.

    Args:
        filename (str): The name of the dotenv file to parse.

    Raises:
        FileNotFoundError: If the file does not exist.
        PermissionError: If the file is not readable.
        IsADirectoryError: If the file is a directory.
        UnicodeError: If the file is not encoded in UTF-8.
        io.UnsupportedOperation: If the file is not readable.
        OSError: If the file operation fails.
    """
    env_vars: list[EnvVar] = []

    regex = re.compile(
        r'^\s*(?:export\s+)?([a-zA-Z_][a-zA-Z0-9_]*)=(["\']?)(.*?)(\2)?\s*(?:#.*)?$',
    )

    try:
        with Path(file).open("r", encoding="utf-8") as f:
            for line in f:
                stripped_line = line.strip()
                if not stripped_line or stripped_line.startswith("#"):
                    continue

                match = regex.match(line)
                if match:
                    key = match.group(1)
                    value = match.group(3)
                    env_vars.append(EnvVar(name=key, value=value))
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
    except Exception:
        raise
    finally:
        sys.stdout.write(
            json.dumps({"json": json.dumps([asdict(env_var) for env_var in env_vars])}),
        )


def main() -> None:
    """Entry point."""
    try:
        logger.debug("dotenv_to_container_def_envs_json.py started.")
        file_path = parse_filepath_from_args(DEFAULT_DOTENV_PATH, DESCRIPTION)
        dotenv_to_tf_external_json(file_path)
    except (
        TypeError,
        ValueError,
        Exception,
    ) as e:
        logger.exception("%s:", e.__class__.__name__)
        logger.debug("dotenv_to_container_def_envs_json.py failed. Exiting...")
        sys.exit(1)


if __name__ == "__main__":
    main()
