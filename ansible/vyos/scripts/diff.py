#!/usr/bin/env python3

import argparse
from collections.abc import Iterable, Iterator
import sys
from pathlib import Path

type Tree = dict[str, Tree]
type Pattern = tuple[str, ...]


def parse_commands(input: Iterable[str]) -> Tree:
    tree: Tree = {}
    for line in input:
        parts = line.rstrip().removeprefix("set ").split()
        node = tree
        for part in parts:
            if part not in node:
                node[part] = {}
            node = node[part]
    return tree


def parse_patterns(input: Iterable[str]) -> set[Pattern]:
    return {tuple(line.rstrip().split()) for line in input}


def matches_pattern(path: list[str], patterns: set[Pattern]) -> bool:
    for pattern in patterns:
        if len(pattern) > len(path):
            continue
        for pat, elem in zip(pattern, path):
            if pat != elem and pat != "*":
                break
        else:
            return True
    return False


def filter_tree(
    tree: Tree,
    patterns: set[Pattern],
    path: list[str] | None = None,
    verbose: bool = False,
) -> Tree:
    if path is None:
        path = []
    result: Tree = {}
    for key, subtree in tree.items():
        current_path = path + [key]
        if matches_pattern(current_path, patterns):
            if verbose:
                for leaf in collect_leaves(subtree, current_path):
                    print(f"# (ignored) set {leaf}", file=sys.stderr)
            continue
        result[key] = filter_tree(subtree, patterns, current_path, verbose)
    return result


def collect_leaves(tree: Tree, path: list[str]) -> Iterator[str]:
    if not tree:
        yield " ".join(path)
    else:
        for key, subtree in tree.items():
            yield from collect_leaves(subtree, path + [key])


def compute_diff(
    running: Tree, desired: Tree, path: list[str] | None = None
) -> tuple[list[str], list[str]]:
    if path is None:
        path = []
    additions: list[str] = []
    deletions: list[str] = []

    all_keys = running.keys() | desired.keys()
    for key in all_keys:
        current_path = path + [key]
        in_running = key in running
        in_desired = key in desired

        if not in_running and in_desired:
            additions.extend(collect_leaves(desired[key], current_path))
        elif in_running and not in_desired:
            deletions.append(" ".join(current_path))
        else:
            a, d = compute_diff(running[key], desired[key], current_path)
            additions.extend(a)
            deletions.extend(d)

    return additions, deletions


def main() -> None:
    parser = argparse.ArgumentParser(description="Diff VyOS configurations")
    parser.add_argument("running", type=Path, help="Running config file")
    parser.add_argument("desired", type=Path, help="Desired config file")
    parser.add_argument("patterns", type=Path, help="Ignore patterns file")
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Print ignored config"
    )
    args = parser.parse_args()

    with args.running.open() as f:
        running = parse_commands(f)
    with args.desired.open() as f:
        desired = parse_commands(f)
    with args.patterns.open() as f:
        patterns = parse_patterns(f)

    running = filter_tree(running, patterns, verbose=args.verbose)
    additions, deletions = compute_diff(running, desired)

    for conf in sorted(deletions):
        print("delete " + conf)
    for conf in sorted(additions):
        print("set " + conf)


if __name__ == "__main__":
    main()
