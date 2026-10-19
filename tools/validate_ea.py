#!/usr/bin/env python3
"""
Berrytrade-EA Strategy Validator
Validates strategy directory structure, metadata.json schema, and scans for prohibited code patterns.
"""

import sys
import os
import json
import re
import argparse
from pathlib import Path

REQUIRED_METADATA_FIELDS = [
    "name",
    "version",
    "author",
    "category",
    "tier",
    "risk_level",
    "description",
    "supported_symbols",
    "recommended_timeframe",
    "min_deposit_usd",
    "has_stop_loss",
    "uses_martingale",
    "uses_grid"
]

VALID_CATEGORIES = {
    "trend_following",
    "mean_reversion",
    "breakout",
    "scalping",
    "grid",
    "martingale",
    "arbitrage",
    "news_trading",
    "hedging",
    "portfolio"
}

VALID_RISK_LEVELS = {"Low", "Medium", "High", "Extreme"}
VALID_TIERS = {"experimental", "verified"}

# Prohibited patterns for security and audit compliance
PROHIBITED_PATTERNS = [
    (re.compile(r'#import\s+["\'](user32|kernel32|shell32|advapi32|ws2_32|wininet)\.dll["\']', re.IGNORECASE),
     "Direct Win32/system native DLL imports are prohibited for security reasons."),
    (re.compile(r'#import\s+["\'][^"\']+\.dll["\']', re.IGNORECASE),
     "External custom DLL imports are prohibited unless explicitly reviewed and whitelisted."),
    (re.compile(r'WebRequest\s*\(', re.IGNORECASE),
     "WebRequest found. Network requests must be strictly declared, documented, and reviewed.")
]

def validate_strategy_package(strategy_path: Path) -> list[str]:
    errors = []
    warnings = []

    if not strategy_path.is_dir():
        return [f"Path {strategy_path} is not a valid directory."]

    strategy_name = strategy_path.name
    print(f"[*] Validating strategy package: {strategy_name} at {strategy_path}")

    # 1. Check directory layout
    src_dir = strategy_path / "src"
    presets_dir = strategy_path / "presets"
    reports_dir = strategy_path / "reports"
    readme_file = strategy_path / "README.md"
    metadata_file = strategy_path / "metadata.json"

    if not src_dir.is_dir():
        errors.append("Missing required directory: 'src/'")
    else:
        mq5_files = list(src_dir.glob("*.mq5"))
        if not mq5_files:
            errors.append("No .mq5 source files found in 'src/' directory.")

    if not presets_dir.is_dir():
        errors.append("Missing required directory: 'presets/'")
    else:
        set_files = list(presets_dir.glob("*.set"))
        if not set_files:
            errors.append("No .set preset files found in 'presets/' directory.")

    if not reports_dir.is_dir():
        errors.append("Missing required directory: 'reports/'")

    if not readme_file.is_file():
        errors.append("Missing required file: 'README.md'")

    if not metadata_file.is_file():
        errors.append("Missing required file: 'metadata.json'")
        return errors

    # 2. Validate metadata.json
    try:
        with open(metadata_file, "r", encoding="utf-8") as f:
            metadata = json.load(f)
    except Exception as e:
        errors.append(f"Invalid JSON format in metadata.json: {e}")
        return errors

    for field in REQUIRED_METADATA_FIELDS:
        if field not in metadata:
            errors.append(f"metadata.json is missing required field: '{field}'")

    cat = metadata.get("category")
    if cat and cat not in VALID_CATEGORIES:
        errors.append(f"Invalid category '{cat}'. Must be one of: {sorted(list(VALID_CATEGORIES))}")

    risk = metadata.get("risk_level")
    if risk and risk not in VALID_RISK_LEVELS:
        errors.append(f"Invalid risk_level '{risk}'. Must be one of: {sorted(list(VALID_RISK_LEVELS))}")

    tier = metadata.get("tier")
    if tier and tier not in VALID_TIERS:
        errors.append(f"Invalid tier '{tier}'. Must be one of: {sorted(list(VALID_TIERS))}")

    if metadata.get("uses_martingale") is True and metadata.get("risk_level") != "Extreme":
        errors.append("Strategies with 'uses_martingale: true' MUST declare 'risk_level: \"Extreme\"'.")

    # 3. Security & Prohibited Pattern Scanning in source files
    for root, _, files in os.walk(strategy_path):
        for file in files:
            if file.endswith((".mq5", ".mqh")):
                file_path = Path(root) / file
                try:
                    with open(file_path, "r", encoding="utf-8", errors="ignore") as code_f:
                        content = code_f.read()
                    for pattern, msg in PROHIBITED_PATTERNS:
                        if pattern.search(content):
                            # WebRequest may be a warning if documented, DLL imports are errors
                            if "WebRequest" in msg:
                                warnings.append(f"[{file}] Warning: {msg}")
                            else:
                                errors.append(f"[{file}] Security Violation: {msg}")
                except Exception as e:
                    errors.append(f"Failed to read file {file_path}: {e}")

    for w in warnings:
        print(f"  [!] {w}")

    return errors


def main():
    parser = argparse.ArgumentParser(description="Validate Berrytrade-EA strategy packages.")
    parser.add_argument("--path", type=str, help="Path to a specific strategy directory.")
    parser.add_argument("--all", action="store_true", help="Scan all strategies in strategies/ directory.")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent

    target_paths = []
    if args.path:
        target_paths.append(Path(args.path).resolve())
    elif args.all:
        for tier in ["experimental", "verified"]:
            tier_dir = repo_root / "strategies" / tier
            if tier_dir.is_dir():
                for sub in tier_dir.iterdir():
                    if sub.is_dir() and not sub.name.startswith("."):
                        target_paths.append(sub)
    else:
        # Default scan all
        for tier in ["experimental", "verified"]:
            tier_dir = repo_root / "strategies" / tier
            if tier_dir.is_dir():
                for sub in tier_dir.iterdir():
                    if sub.is_dir() and not sub.name.startswith("."):
                        target_paths.append(sub)

    if not target_paths:
        print("No strategy packages found to validate.")
        sys.exit(0)

    total_errors = 0
    for strat_path in target_paths:
        errs = validate_strategy_package(strat_path)
        if errs:
            print(f"[-] FAILED: {strat_path.name}")
            for err in errs:
                print(f"    - {err}")
            total_errors += len(errs)
        else:
            print(f"[+] PASSED: {strat_path.name}")

    if total_errors > 0:
        print(f"\nValidation failed with {total_errors} error(s).")
        sys.exit(1)
    else:
        print("\nAll strategy packages validated successfully!")
        sys.exit(0)


if __name__ == "__main__":
    main()
