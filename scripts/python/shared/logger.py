"""Logging utils."""

import logging
import os


def get_logger(name: str) -> logging.Logger:
    """
    Return custom logger.

    Args:
        name (str): The name of the logger.

    Returns:
        logging.Logger: Configured logger instance.
    """
    debug_mode = os.getenv("DEBUG_MODE", default="false").lower() == "true"
    level = logging.DEBUG if debug_mode else logging.INFO
    fmt = "[%(filename)s:%(lineno)d:%(funcName)s] %(message)s"

    logging.basicConfig(
        format=fmt,
        level=level,
    )

    return logging.getLogger(name)
