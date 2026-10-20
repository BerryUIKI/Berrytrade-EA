#!/usr/bin/env python3
"""
Berrytrade Quantitative Infrastructure: Author Report Parser
Parses genuine MetaTrader 5 backtest Excel reports (report.xlsx) across all
ingested strategies. Extracts:
1. Exact metadata (author symbol, test period, broker build).
2. Clean deal-by-deal execution logs (deals.csv).
3. Reconstructed closed round-turn trades (trades.csv) with true holding duration and PnL.
4. Resampled daily balance and drawdown trajectories (daily_equity.csv).
5. Centralized author baseline summary (benchmarks/author_baselines_summary.json).

Author: Berry Wahlberg
Affiliation: Berrytrade Quantitative Research, Singapore
"""

import os
import sys
import glob
import json
import openpyxl
import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime

# Ensure UTF-8 output encoding
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

REPO_ROOT = Path(__file__).resolve().parent.parent
STRATEGIES_DIR = REPO_ROOT / "strategies" / "experimental"
BENCHMARKS_DIR = REPO_ROOT / "benchmarks"
BENCHMARKS_DIR.mkdir(parents=True, exist_ok=True)

def parse_report_xlsx(file_path: Path):
    """Parses a single MT5 Strategy Tester report.xlsx file."""
    strat_name = file_path.parent.parent.name
    print(f"[*] Parsing authentic MT5 report for: {strat_name} ({file_path})")

    wb = openpyxl.load_workbook(file_path, data_only=True)
    ws = wb.active
    rows = list(ws.iter_rows(values_only=True))

    meta = {
        "strategy": strat_name,
        "author_symbol": "Unknown",
        "author_period": "Unknown",
        "broker_build": "Unknown",
        "initial_deposit": 10000.0,
        "total_net_profit": 0.0,
        "profit_factor": 0.0,
        "total_trades": 0,
        "total_deals": 0,
        "max_drawdown_pct": 0.0,
        "min_margin_level": 0.0,
        "inputs": {}
    }

    deals_hdr_idx = None
    orders_hdr_idx = None

    # 1. Parse Metadata & Summary Block
    reading_inputs = False
    for i, r in enumerate(rows):
        if not any(r):
            continue
        row_str = " ".join([str(c) for c in r if c is not None])

        if "Strategy Tester Report" in row_str and i + 1 < len(rows):
            next_row = [str(c) for c in rows[i+1] if c is not None]
            if next_row:
                meta["broker_build"] = next_row[0]

        if "Symbol:" in row_str:
            for idx, c in enumerate(r):
                if c == "Symbol:" and idx + 1 < len(r):
                    val = [x for x in r[idx+1:] if x is not None]
                    if val:
                        meta["author_symbol"] = str(val[0])
                        break

        if "Period:" in row_str:
            for idx, c in enumerate(r):
                if c == "Period:" and idx + 1 < len(r):
                    val = [x for x in r[idx+1:] if x is not None]
                    if val:
                        meta["author_period"] = str(val[0])
                        break

        if "Total Net Profit:" in row_str:
            for idx, c in enumerate(r):
                if c == "Total Net Profit:":
                    val = [x for x in r[idx+1:] if isinstance(x, (int, float))]
                    if val:
                        meta["total_net_profit"] = float(val[0])
                        break

        if "Profit Factor:" in row_str:
            for idx, c in enumerate(r):
                if c == "Profit Factor:":
                    val = [x for x in r[idx+1:] if isinstance(x, (int, float))]
                    if val:
                        meta["profit_factor"] = float(val[0])
                        break

        if "Total Trades:" in row_str:
            for idx, c in enumerate(r):
                if c == "Total Trades:":
                    val = [x for x in r[idx+1:] if isinstance(x, (int, float))]
                    if val:
                        meta["total_trades"] = int(val[0])
                        break

        if "Total Deals:" in row_str:
            for idx, c in enumerate(r):
                if c == "Total Deals:":
                    val = [x for x in r[idx+1:] if isinstance(x, (int, float))]
                    if val:
                        meta["total_deals"] = int(val[0])
                        break

        if "Margin Level Minimal:" in row_str:
            for idx, c in enumerate(r):
                if "Margin Level Minimal:" in str(c):
                    val = [x for x in r[idx+1:] if isinstance(x, (int, float))]
                    if val:
                        meta["min_margin_level"] = float(val[0])
                        break

        if "Relative:" in row_str and "Drawdown" in row_str:
            for idx, c in enumerate(r):
                if c == "Relative:":
                    val = [x for x in r[idx+1:] if isinstance(x, (int, float))]
                    if val:
                        meta["max_drawdown_pct"] = float(val[0])
                        break

        if "Orders" in [str(c) for c in r if c is not None] and orders_hdr_idx is None:
            orders_hdr_idx = i

        if "Deals" in [str(c) for c in r if c is not None] and deals_hdr_idx is None:
            deals_hdr_idx = i + 1

    # 2. Parse Deals Table
    if deals_hdr_idx is None or deals_hdr_idx >= len(rows):
        print(f"[-] Warning: Deals table not found in {file_path}")
        return meta, None, None

    raw_hdr = rows[deals_hdr_idx]
    hdr = [str(c).strip() for c in raw_hdr if c is not None]
    
    # Expected columns: ['Time', 'Deal', 'Symbol', 'Type', 'Direction', 'Volume', 'Price', 'Order', 'Commission', 'Swap', 'Profit', 'Balance', 'Comment']
    deals_data = []
    for r in rows[deals_hdr_idx + 1:]:
        if not any(r):
            continue
        cells = [c for c in r if c is not None]
        if len(cells) < 5:
            continue
        # Map values according to raw_hdr positions
        row_dict = {}
        c_idx = 0
        for col_name in hdr:
            # find corresponding value in r
            for val in r:
                pass
        # simpler: take first len(hdr) non-sparse cells or mapped
        row_vals = [c for c in r if c is not None]
        if len(row_vals) >= len(hdr):
            row_dict = dict(zip(hdr, row_vals[:len(hdr)]))
        else:
            # fill with Nones
            padded = row_vals + [None] * (len(hdr) - len(row_vals))
            row_dict = dict(zip(hdr, padded))
        deals_data.append(row_dict)

    df_deals = pd.DataFrame(deals_data)
    
    # Clean types
    if "Time" in df_deals.columns:
        df_deals["Time"] = pd.to_datetime(df_deals["Time"], format="%Y.%m.%d %H:%M:%S", errors="coerce")
    for num_col in ["Volume", "Price", "Commission", "Swap", "Profit", "Balance"]:
        if num_col in df_deals.columns:
            df_deals[num_col] = pd.to_numeric(df_deals[num_col], errors="coerce").fillna(0.0)

    # Filter valid deals
    df_deals = df_deals.dropna(subset=["Time"]).sort_values("Time").reset_index(drop=True)

    # Initial deposit from first deal or default
    init_dep = df_deals["Balance"].iloc[0] if len(df_deals) > 0 and df_deals["Balance"].iloc[0] > 0 else 10000.0
    meta["initial_deposit"] = float(init_dep)

    # 3. Reconstruct Closed Trades
    trades = []
    open_positions = [] # stack of 'in' deals

    for _, deal in df_deals.iterrows():
        direction = str(deal.get("Direction", "")).lower()
        deal_type = str(deal.get("Type", "")).lower()

        if direction == "in" and deal_type in ["buy", "sell"]:
            open_positions.append(deal)
        elif direction == "out" and open_positions:
            # Match FIFO
            entry_deal = open_positions.pop(0)
            holding_time_sec = (deal["Time"] - entry_deal["Time"]).total_seconds()
            holding_hours = holding_time_sec / 3600.0
            gross_pnl = float(deal.get("Profit", 0.0))
            comm = float(deal.get("Commission", 0.0)) + float(entry_deal.get("Commission", 0.0))
            swap = float(deal.get("Swap", 0.0)) + float(entry_deal.get("Swap", 0.0))
            net_pnl = gross_pnl + comm + swap

            trades.append({
                "entry_time": entry_deal["Time"],
                "exit_time": deal["Time"],
                "symbol": deal.get("Symbol", entry_deal.get("Symbol", "")),
                "type": entry_deal["Type"],
                "volume": entry_deal.get("Volume", 0.0),
                "entry_price": entry_deal.get("Price", 0.0),
                "exit_price": deal.get("Price", 0.0),
                "holding_hours": holding_hours,
                "gross_pnl": gross_pnl,
                "commission": comm,
                "swap": swap,
                "net_pnl": net_pnl,
                "balance_after": deal.get("Balance", 0.0)
            })

    df_trades = pd.DataFrame(trades)

    # 4. Generate Resampled Daily Equity / Balance
    if len(df_deals) > 0:
        df_daily = df_deals.set_index("Time").resample("1D")["Balance"].last().ffill().reset_index()
        df_daily.columns = ["date", "balance"]
        peak = df_daily["balance"].cummax()
        df_daily["drawdown_usd"] = df_daily["balance"] - peak
        df_daily["drawdown_pct"] = (df_daily["drawdown_usd"] / peak) * 100.0
    else:
        df_daily = pd.DataFrame()

    out_reports_dir = file_path.parent
    df_deals.to_csv(out_reports_dir / "deals.csv", index=False)
    df_trades.to_csv(out_reports_dir / "trades.csv", index=False)
    if not df_daily.empty:
        df_daily.to_csv(out_reports_dir / "daily_equity.csv", index=False)

    print(f"  [+] Extracted {len(df_deals)} deals, {len(df_trades)} closed trades for {strat_name}")
    print(f"  [+] Author Period: {meta['author_period']}, Symbol: {meta['author_symbol']}, Net Profit: {meta['total_net_profit']}, PF: {meta['profit_factor']}")

    return meta, df_deals, df_trades


def main():
    print("==========================================================")
    print(" Parsing Authentic MT5 Backtest Workbooks (Zero Synthetic)")
    print("==========================================================")

    all_meta = {}
    report_files = sorted(glob.glob(str(STRATEGIES_DIR / "*" / "reports" / "report.xlsx")))
    print(f"[*] Discovered {len(report_files)} author report workbooks.")

    for f_str in report_files:
        f_path = Path(f_str)
        meta, _, _ = parse_report_xlsx(f_path)
        all_meta[meta["strategy"]] = meta

    summary_file = BENCHMARKS_DIR / "author_baselines_summary.json"
    with open(summary_file, "w", encoding="utf-8") as f:
        json.dump(all_meta, f, indent=2, default=str)
    print(f"\n[+] Successfully parsed all {len(all_meta)} workbooks!")
    print(f"[+] Written verified author baseline index to: {summary_file}")


if __name__ == "__main__":
    main()
