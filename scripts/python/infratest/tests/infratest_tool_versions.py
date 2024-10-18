"""test tool versions"""

import os
from dotenv import load_dotenv
import pytest
import testinfra  # type: ignore

from ..utils import Tool, load_tools_json

load_dotenv(".env.tool-versions")

RUN_INFRATEST = os.getenv("RUN_INFRATEST", "false").lower() == "true"


@pytest.fixture()
def tool(request: pytest.FixtureRequest) -> Tool:
    return request.param


def pytest_generate_tests(metafunc: pytest.Metafunc) -> None:
    tools = load_tools_json()
    metafunc.parametrize(
        "tool",
        tools,
        indirect=True,
        ids=[tool.name for tool in tools],
    )


@pytest.mark.skipif(not RUN_INFRATEST, reason="RUN_INFRATEST is not set to 'true'")
def test_path(host: testinfra.host.Host, tool: Tool) -> None:
    """test: if commands exist in the path"""
    skip_list = ["docker-compose", "docker-buildx"]

    if tool.command == "noop" or tool.name in skip_list:
        pytest.skip()

    assert host.exists(tool.command)


@pytest.mark.skipif(not RUN_INFRATEST, reason="RUN_INFRATEST is not set to 'true'")
def test_version(host: testinfra.host.Host, tool: Tool) -> None:
    """test: version"""
    skip_list = ["hclfmt", "perflint", "commitizen"]

    if tool.version_option == "noop" or tool.name in skip_list:
        pytest.skip()

    assert (
        os.getenv(tool.version_env)
        in host.run(f"{tool.command} {tool.version_option}").stdout
    )


@pytest.mark.skipif(not RUN_INFRATEST, reason="RUN_INFRATEST is not set to 'true'")
def test_bad_option(host: testinfra.host.Host, tool: Tool) -> None:
    """test: bad option"""
    skip_list = [""]

    if tool.bad_option == "noop" or tool.name in skip_list:
        pytest.skip()

    bad_option_message = tool.bad_option_message
    res = host.run(f"{tool.command} {tool.bad_option}")
    assert bad_option_message in res.stderr or bad_option_message in res.stdout
