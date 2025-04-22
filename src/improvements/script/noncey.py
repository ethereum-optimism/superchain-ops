# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "tomlkit",
# ]
# ///

import sys
from pathlib import Path
from typing import Dict, List, Set

import tomlkit


def get_safe_dependencies(safes: List[Dict], safe_name: str) -> Set[str]:
    """Get all safes that are involved with a given safe (including itself)."""
    dependencies = {safe_name}

    # Find the safe in the list
    safe = next((s for s in safes if s["name"] == safe_name), None)
    if not safe:
        return dependencies

    # Add owners recursively
    for owner in safe.get("owners", []):
        dependencies.update(get_safe_dependencies(safes, owner))

    return dependencies


def update_nonces_with_tomlkit(config_path: str, nonces: Dict[str, int]) -> None:
    """Update nonces in config.toml using tomlkit."""
    with open(config_path) as f:
        doc = tomlkit.parse(f.read())

    # Ensure nonces table exists
    if "nonces" not in doc:
        doc["nonces"] = tomlkit.table()

    # Update nonces
    for safe_name, nonce in nonces.items():
        doc["nonces"][safe_name] = nonce

    # Write back to file
    with open(config_path, "w") as f:
        f.write(tomlkit.dumps(doc))


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ["eth", "sep"]:
        print("Usage: noncey.py <chain>")
        print("  chain: 'eth' or 'sep'")
        sys.exit(1)

    chain = sys.argv[1]
    tasks_dir = Path("src/improvements/tasks") / chain

    # Read safes.toml
    safes_path = tasks_dir / "safes.toml"
    if not safes_path.exists():
        print(f"Error: {safes_path} does not exist")
        sys.exit(1)

    with open(safes_path) as f:
        doc = tomlkit.parse(f.read())
        safes = doc["safes"].unwrap()

    # Get current nonces from safes.toml
    current_nonces = {safe["name"]: safe["nonce"] for safe in safes}

    # Find all task directories
    task_dirs = []
    for item in tasks_dir.iterdir():
        if item.is_dir() and item.name[:3].isdigit():
            task_dirs.append(item)

    # Sort task directories lexicographically
    task_dirs.sort(key=lambda x: x.name)

    # Process each task
    next_nonces = current_nonces.copy()
    for task_dir in task_dirs:
        config_path = task_dir / "config.toml"
        if not config_path.exists():
            continue

        with open(config_path) as f:
            doc = tomlkit.parse(f.read())
            config = doc.unwrap()

        # Skip if no safe field or already executed
        if "safe" not in config or "executed" in config:
            continue

        safe_name = config["safe"]
        if safe_name not in current_nonces:
            print(f"Error: Safe {safe_name} not found in safes.toml")
            sys.exit(1)

        # Get all safes involved
        involved_safes = get_safe_dependencies(safes, safe_name)

        # Update nonces in config.toml
        task_nonces = {safe: next_nonces[safe] for safe in involved_safes}
        update_nonces_with_tomlkit(str(config_path), task_nonces)

        # Increment nonces for next task
        for safe in involved_safes:
            next_nonces[safe] += 1


if __name__ == "__main__":
    main()
