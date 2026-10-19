#!/usr/bin/env python3
"""
Berrytrade Quantitative Infrastructure: Historical Market Data Downloader
Downloads genuine daily OHLCV market price series for core evaluation symbols
across 2020.01.01 -- 2026.01.01 from public financial market feeds.

Author: Berry Wahlberg
Affiliation: Berrytrade Quantitative Research, Singapore
"""

import os
import sys
import yfinance as yf
import pandas as pd
from pathlib import Path

# Ensure UTF-8 output encoding
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data" / "historical"
DATA_DIR.mkdir(parents=True, exist_ok=True)

SYMBOLS = {
    "EURUSD": "EURUSD=X",
    "GBPUSD": "GBPUSD=X",
    "USDJPY": "USDJPY=X",
    "XAUUSD": "GC=F",
    "USDCAD": "USDCAD=X",
    "AUDUSD": "AUDUSD=X",
    "NZDUSD": "NZDUSD=X"
}

def download_all():
    print("==========================================================")
    print(" Downloading Verified Historical Market Data (2020-2026)")
    print("==========================================================")

    for name, ticker in SYMBOLS.items():
        out_file = DATA_DIR / f"{name}_1d.csv"
        print(f"[*] Downloading {name} ({ticker})...")
        df = yf.download(ticker, start="2020-01-01", end="2026-01-01", interval="1d", progress=False)
        if not df.empty:
            if hasattr(df.columns, 'levels') and len(df.columns.levels) > 1:
                df.columns = [c[0].lower() for c in df.columns]
            else:
                df.columns = [c.lower() for c in df.columns]
            df.index.name = "date"
            df.to_csv(out_file)
            print(f"  [+] Saved {len(df)} authentic daily bars to {out_file}")
        else:
            print(f"  [-] Failed to download data for {name}")

    print("\n[+] Historical market data download complete!")

if __name__ == "__main__":
    download_all()
