#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "pydantic>=2.9.0",
# ]
# ///
# ruff: noqa: S404, S603
"""
Fetch latest versions and update .env.tool-versions.

.tool.jsonから読み込んだ情報でgithubから最新のSemVerのみのtagを取得し、.env.tool-versionsに出力する。

ref:
- https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-tags
- https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#list-releases

To log debug level messages, set the DEBUG_MODE environment variable to true.

e.g.
export DEBUG_MODE=true
./scripts/python/tools/fetch_latest_tool_versions.py
"""

import asyncio
import io
import os
import re
import shutil
import subprocess
import sys
from enum import StrEnum
from fnmatch import fnmatch
from pathlib import Path

import httpx
import pexpect
import pydantic
from dotenv import load_dotenv
from pydantic import BaseModel

sys.path.append(str(Path(__file__).resolve().parents[1]))

from shared.logger import get_logger
from shared.tools import Tool, VersionFrom, load_tools_json

logger = get_logger(__name__)


class GHTag(BaseModel):
    """GitHub tag."""

    name: str


class GHRelease(BaseModel):
    """GitHub release."""

    tag_name: str


class GHSlug(StrEnum):
    """Enum for GitHub request slug."""

    TAGS: str = "tags"
    RELEASES: str = "releases"


class Repository(BaseModel):
    """GitHub repository."""

    name: str
    owner: str


class GHRequestParams(BaseModel):
    """GitHub request parameters."""

    url: str
    headers: dict


class CommandNotFoundError(Exception):
    """Exception raised when a command is not found."""


def check_gh_is_installed() -> None:
    """
    Check if the gh command is installed.

    Raises:
        CommandNotFoundError: If the gh command is not found.
    """
    result = shutil.which("gh")
    logger.debug("shutil.which('gh') results: %s", result)
    if not result:
        msg = "CommandNotFoundError: gh command not found."
        raise CommandNotFoundError(msg)


def check_gh_auth_logged_in() -> bool:
    """
    Check if you're logged in to GitHub with gh.

    Returns:
        bool: True if logged in.
    """
    cmd = ["/usr/bin/env", "gh", "auth", "status"]

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        shell=False,
        check=False,
    )

    logger.debug("gh auth status results: %s", result)
    logged_in = "You are not logged into any GitHub hosts." not in result.stderr
    logger.debug("logged_in: %s", logged_in)

    return logged_in


def gh_auth_login() -> None:
    """
    Login to GitHub using the gh command.

    Raises:
        pexpect.ExceptionPexpect: If the pexpect fails.
    """
    try:
        logger.info("gh not logged in. Running 'gh auth login'...")
        cmd = "gh auth login"
        child = pexpect.spawn(cmd)
        child.interact()
    except pexpect.ExceptionPexpect as e:
        logger.exception(
            "%s: pexpect.spawn() failed to execute %s.",
            e.__class__.__name__,
            cmd,
        )
        raise


def gh_auth_token() -> str:
    """
    Return GitHub token from gh.

    Raises:
        subprocess.CalledProcessError: If the subprocess call fails.
        subprocess.TimeoutExpired: If the subprocess call times out.
        OSError: If an error occurs while running the subprocess

    Returns:
        str: The GitHub token.
    """
    try:
        cmd = ["/usr/bin/env", "gh", "auth", "token"]

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            shell=False,
            check=True,
        )

        logger.debug("gh auth token return code: %s", result.returncode)
        token = result.stdout.strip()
    except (
        subprocess.CalledProcessError,
        subprocess.TimeoutExpired,
        OSError,
        Exception,
    ) as e:
        logger.exception(
            "%s: subprocess.run() failed to execute %s.",
            e.__class__.__name__,
            " ".join(cmd),
        )
        raise
    else:
        return token


def get_github_token() -> str:
    """
    Return GitHub token.

    Attempt to retrieve the GitHub token in the following order:
    - from environment variable "GITHUB_TOKEN"
    - from "gh auth token" command

    Returns:
        str: The GitHub token.
    """
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        check_gh_is_installed()
        if not check_gh_auth_logged_in():
            gh_auth_login()
        token = gh_auth_token()
    else:
        logger.debug("GITHUB_TOKEN found in environment variables.")
    return token


def extract_repo_info_from_gh_url(repository_url: str) -> Repository:
    """
    Extract the repository owner and name from a GitHub repository URL.

    Args:
        repository (str): The GitHub repository URL.

    Returns:
        Repository: The repository owner
    """
    repo_split = repository_url.split("/")
    owner = repo_split[-2]
    repo_name = repo_split[-1]
    repo = Repository(name=repo_name, owner=owner)
    logger.debug("extract_repo_info_from_gh_url() results: %s", repo)
    return repo


def get_slug(version_from: str) -> GHSlug:
    """
    Get the slug based on the version_from value.

    Args:
        version_from (str): The version_from value.

    Returns:
        GHSlug: The corresponding slug.
    """
    if version_from == VersionFrom.LATEST_TAG:
        slug = GHSlug.TAGS
    if version_from == VersionFrom.LATEST_RELEASE:
        slug = GHSlug.RELEASES
    return slug


def build_gh_request_params(
    gh_token: str,
    repo_owner: str,
    repo_name: str,
    slug: GHSlug,
    search_limit: int,
) -> GHRequestParams:
    """
    Build the GitHub request parameters.

    Args:
        gh_token (str): The GitHub token
        repo_owner (str): The owner of the repository.
        repo_name (str): The name of the repository.
        slug (GHSlug): The slug to use in the URL.
        search_limit (int): The number of items to retrieve per page.

    Returns:
        GHRequestParams: The URL and headers for the GitHub request.
    """
    base_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/"
    query = f"?per_page={search_limit}"
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "Authorization": f"Bearer {gh_token}",
    }

    params = GHRequestParams(url=base_url + slug + query, headers=headers)
    logger.debug("build_gh_request_params url: %s", params.url)
    return params


def extract_tags(response: httpx.Response, slug: GHSlug) -> list[str]:
    """
    Extract tags from the GitHub API response.

    Args:
        response (httpx.Response): The response from the GitHub API.
        slug (str): The slug used in the URL.

    Returns:
        list[str]: A list of tags extracted from the response.
    """
    if slug == GHSlug.TAGS:
        resp_tags = pydantic.TypeAdapter(list[GHTag]).validate_python(
            response.json(),
        )

        tags = [tag.name for tag in resp_tags]
    elif slug == GHSlug.RELEASES:
        resp_releases = pydantic.TypeAdapter(list[GHRelease]).validate_python(
            response.json(),
        )

        tags = [release.tag_name for release in resp_releases]
    return tags


def find_semver_only_tag(tags: list[str], ignore_patterns: list[str]) -> str:
    """
    Find the first tag that matches the semantic versioning pattern.

    Args:
        tags (list[str]): A list of tags to search through.
        ignore_patterns (list[str]): A list of patterns to ignore.

    Raises:
        ValueError: If no semver tag is found.

    Returns:
        str: The first tag that matches the semantic versioning pattern.
    """
    pattern = re.compile(r".*?(\d+\.\d+(\.\d+)?)$")
    for tag in tags:
        if any(fnmatch(tag, ignore_pattern) for ignore_pattern in ignore_patterns):
            continue

        match = pattern.match(tag)
        if match:
            return match.group(1)
    msg = "ValueError: No semver tag found"
    raise ValueError(msg)


async def get_latest_semver_tag(
    client: httpx.AsyncClient,
    gh_token: str,
    tool: Tool,
    search_limit: int = 15,
) -> str:
    """
    Get the latest semantic version tag from a GitHub repository.

    Args:
        client (httpx.AsyncClient): The HTTP client to use for the request.
        gh_token (str): The GitHub token to use for authentication.
        tool (Tool): The tool object to get the latest version for.
        search_limit (int): The number of items to retrieve per page.
            Default: 15.

    Returns:
        str: The latest semantic version only tag.

    Raises:
        httpx.HTTPStatusError: If the HTTP request returned an unsuccessful status code.
        httpx.RequestError: If an error occurred while making the request.
        httpx.HTTPError: If an HTTP error occurred.
        httpx.InvalidURL: If the URL is invalid.
        httpx.CookieConflict: If there is a cookie conflict.
        httpx.StreamError: If there is a stream error.
    """
    repo = extract_repo_info_from_gh_url(tool.repository)

    if tool.pinned_version != "noop":
        logger.debug(
            "pinned version found: %s/%s: %s",
            repo.owner,
            repo.name,
            tool.pinned_version,
        )
        return tool.pinned_version

    try:
        slug = get_slug(tool.version_from)
        logger.debug("get_slug() results: %s/%s: %s", repo.owner, repo.name, slug)
        params = build_gh_request_params(
            gh_token,
            repo.owner,
            repo.name,
            slug,
            search_limit,
        )
        response = await client.get(params.url, headers=params.headers)
        response.raise_for_status()
        tags = extract_tags(response, slug)
        logger.debug(
            "extract_tags() results: %s/%s: %s",
            repo.owner,
            repo.name,
            tags,
        )
        semver = find_semver_only_tag(tags, tool.ignore_pattern)
        logger.debug(
            "find_semver_only_tag() results: %s/%s: %s",
            repo.owner,
            repo.name,
            semver,
        )
    except (
        httpx.HTTPStatusError,
        httpx.RequestError,
        httpx.HTTPError,
        httpx.InvalidURL,
        httpx.CookieConflict,
        httpx.StreamError,
    ) as e:
        logger.exception("%s: httpx.AsyncClient.get() failed.", e.__class__.__name__)
        raise
    else:
        return semver


def write_env_tool_versions(
    tools: list[Tool],
    versions: list[str],
    write_to: str = ".env.tool-versions",
) -> None:
    """
    Write the latest versions of tools to .env.tool-versions.

    Args:
        tools (list[Tool]): A list of Tool objects.
        versions (list[str]): A list of the latest versions of the tools.
        write_to (str): The path to write the .env file.
            Default: ".env.tool-versions".

    Raises:
        PermissionError: If the file is not accessible due to permission settings.
        IsADirectoryError: If the file is a directory.
        UnicodeError: If the file contains invalid characters.
        UnsupportedOperation: If the file is not readable.
        OSError: If an error occurs while writing the file

    """
    seen: set[str] = set()
    lines = []

    for tool, version in zip(tools, versions, strict=False):
        if tool.version_env not in seen:
            lines.append(f'export {tool.version_env}="{version}"')
            seen.add(tool.version_env)

    joined = "\n".join(lines)
    logger.debug("write_env_tool_versions() results: %s", joined)

    try:
        with Path(write_to).open(mode="w", encoding="utf-8") as f:
            f.write(joined)
    except (
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


async def main() -> None:
    """Entry point."""
    try:
        logger.debug("fetch_latest_tool_versions.py started.")
        load_dotenv()

        tools = load_tools_json()
        gh_token = get_github_token()

        async with httpx.AsyncClient() as client:
            async with asyncio.TaskGroup() as tg:
                tasks = [
                    tg.create_task(
                        get_latest_semver_tag(
                            client=client,
                            gh_token=gh_token,
                            tool=tool,
                        ),
                    )
                    for tool in tools
                ]

            versions = [task.result() for task in tasks]

            write_env_tool_versions(tools, versions)
        logger.debug("fetch_latest_tool_versions.py completed.")
    except* (
        TypeError,
        ValueError,
        Exception,
    ) as e:
        logger.exception("%s:", e.__class__.__name__)
        logger.debug("fetch_latest_tool_versions.py failed. Exiting...")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
