"""General util functions."""

import argparse
import sys
from pathlib import Path

# must be executed from the repo root
sys.path.append(str(Path.cwd()))

from .logger import get_logger

logger = get_logger(__name__)


def parse_filepath_from_args(default_filepath: str, description: str) -> str:
    """
    Parse the command-line arguments to get a filepath.

    Returns:
        str: filepath
    """
    parser = argparse.ArgumentParser(description=description)

    arg_help_file = "The path of the env file to parse."

    parser.add_argument(
        "file",
        nargs="?",
        type=str,
        help=arg_help_file,
    )

    parser.add_argument(
        "-f",
        "--file",
        type=str,
        help=arg_help_file,
        dest="file_opt",
        default=default_filepath,
    )

    args = parser.parse_args()
    file = args.file or args.file_opt
    logger.debug("parse_filepath_from_args() results: %s", file)
    return file
