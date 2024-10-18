#!/usr/bin/env python3

# friendly-snippetsからsnippetを取得してvscode用に変換してから出力するスクリプト
# https://github.com/rafamadriz/friendly-snippets/

import asyncio
from dataclasses import dataclass
import os
import json
import sys
from typing import Any, List
import httpx


@dataclass
class FriendlySnippetFile:
    from_path: str
    to_path: str


@dataclass
class FriendlySnippet:
    file: FriendlySnippetFile
    scope: str
    prefix: str


def load_friendly_snippets_json(
    filename="friendly_snippets.json",
) -> List[FriendlySnippet]:
    filepath = os.path.join(os.path.dirname(os.path.abspath(__file__)), filename)
    try:
        print(f"loading data from {filepath}")
        with open(filepath, "r") as file:
            return [
                FriendlySnippet(file=FriendlySnippetFile(**fs.pop("file")), **fs)
                for fs in json.load(file)
            ]
    except FileNotFoundError:
        print(f"Error: The file {filepath} does not exist.")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Error: The file {filepath} contains invalid JSON.")
        sys.exit(1)


def modify_friendly_snippets_json(fs: FriendlySnippet, snippets: Any) -> Any:
    for _, snippet in snippets.items():
        snippet["scope"] = fs.scope
        snippet["prefix"] = f"{fs.prefix}{snippet["prefix"]}"
    return snippets


def dump_friendly_snippets(fs: FriendlySnippet, snippets: Any) -> None:
    file_to = fs.file.to_path
    try:
        with open(file_to, "w") as file:
            print(f"Writing to {file_to}")
            file.write(
                "// fetched from: https://github.com/rafamadriz/friendly-snippets via python script\n"
            )
            json.dump(snippets, file, indent=2)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


async def get_latest_friendly_snippets(
    client: httpx.AsyncClient,
    fs: FriendlySnippet,
) -> None:
    base_url = "https://raw.githubusercontent.com/rafamadriz/friendly-snippets/main/"
    url = base_url + fs.file.from_path
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    print(f"GET request to {url}")
    response = await client.get(url, headers=headers)
    response.raise_for_status()

    mod = modify_friendly_snippets_json(fs, response.json())

    dump_friendly_snippets(fs, mod)


async def main():
    try:
        friendly_snippets = load_friendly_snippets_json()

        async with httpx.AsyncClient() as client:
            async with asyncio.TaskGroup() as tg:
                for fs in friendly_snippets:
                    tg.create_task(
                        get_latest_friendly_snippets(
                            client=client,
                            fs=fs,
                        )
                    )
    except* Exception as eg:
        print(f"Error: {eg.exceptions}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
