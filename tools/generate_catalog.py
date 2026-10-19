#!/usr/bin/env python3
"""
Berrytrade-EA Catalog Generator
Scans strategy packages and generates formatted Markdown tables for READMEs.
"""

import sys
import json
from pathlib import Path

# Ensure UTF-8 output encoding on Windows consoles
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

def generate_catalog_markdown(repo_root: Path, lang: str = "en") -> str:
    strategies_dir = repo_root / "strategies"
    
    tiers = [("verified", "Verified Strategies (Production-Grade)" if lang == "en" else "已验证策略（生产基准层）"),
             ("experimental", "Experimental Strategies (Incubator & Community)" if lang == "en" else "实验孵化策略（社区前沿层）")]
    
    output_lines = []

    for tier_key, tier_title in tiers:
        tier_path = strategies_dir / tier_key
        if not tier_path.is_dir():
            continue
        
        strategy_dirs = [d for d in tier_path.iterdir() if d.is_dir() and not d.name.startswith(".")]
        
        output_lines.append(f"### {tier_title}")
        output_lines.append("")
        
        if not strategy_dirs:
            msg = "*No strategies currently in this tier.*" if lang == "en" else "*当前该层级暂无入库策略。*"
            output_lines.append(msg)
            output_lines.append("")
            continue
        
        if lang == "en":
            output_lines.append("| Strategy | Category | Risk Level | Symbols | TF | Min Cap | Summary |")
            output_lines.append("| :--- | :--- | :---: | :--- | :---: | :---: | :--- |")
        else:
            output_lines.append("| 策略名称 | 分类 | 风险等级 | 支持品种 | 周期 | 初始资金 | 策略简述 |")
            output_lines.append("| :--- | :--- | :---: | :--- | :---: | :---: | :--- |")
            
        for s_dir in sorted(strategy_dirs, key=lambda x: x.name):
            meta_file = s_dir / "metadata.json"
            if not meta_file.is_file():
                continue
            try:
                with open(meta_file, "r", encoding="utf-8") as f:
                    meta = json.load(f)
            except Exception:
                continue

            name = meta.get("name", s_dir.name)
            link = f"[{name}](strategies/{tier_key}/{s_dir.name})"
            category = meta.get("category", "N/A")
            risk = meta.get("risk_level", "Medium")
            symbols = ", ".join(meta.get("supported_symbols", [])) or "Any"
            tf = meta.get("recommended_timeframe", "M5")
            min_dep = f"${meta.get('min_deposit_usd', 1000):,}"
            desc = meta.get("description", "").replace("\n", " ")
            
            output_lines.append(f"| {link} | `{category}` | **{risk}** | {symbols} | {tf} | {min_dep} | {desc} |")
        
        output_lines.append("")
        
    return "\n".join(output_lines)

def main():
    repo_root = Path(__file__).resolve().parent.parent
    print("[*] Generating English catalog...")
    en_cat = generate_catalog_markdown(repo_root, "en")
    print(en_cat)
    print("\n[*] Generating Chinese catalog...")
    zh_cat = generate_catalog_markdown(repo_root, "zh-CN")
    print(zh_cat)

if __name__ == "__main__":
    main()
