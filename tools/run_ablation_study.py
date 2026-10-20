#!/usr/bin/env python3
"""
Berrytrade Quantitative Infrastructure: Paired 4-Arm Ablation Experiment
Rigorous empirical ablation study evaluating the causal mechanisms of:
1. Pure Technical Indicator Signal (Raw Signal + Fixed Lots + Hard SL)
2. Indicator Signal + Unhedged Grid Overlay (Loss-averaging)
3. Indicator Signal + Volatility Risk Sizing (Dynamic ATR SL/TP)
4. Pseudo-Random Entry + Grid Overlay (Control Arm)

Evaluated over genuine historical market data with realistic spreads and commissions.
Supports In-Sample (2021-2023) and Out-of-Sample (2024-2025) walk-forward validation.

Author: Berry Wahlberg
Affiliation: Berrytrade Quantitative Research, Singapore
"""

import os
import sys
import json
import numpy as np
import pandas as pd
from pathlib import Path
from scipy import stats

# Ensure UTF-8 output encoding
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data" / "historical"
BENCHMARKS_DIR = REPO_ROOT / "benchmarks"
BENCHMARKS_DIR.mkdir(parents=True, exist_ok=True)


def calculate_indicators(df: pd.DataFrame, bb_period=20, bb_std=2.0, rsi_period=14, atr_period=14):
    """Calculates technical indicators on real OHLCV DataFrame."""
    close = df['close'].values
    high = df['high'].values
    low = df['low'].values
    n = len(close)

    # 1. Bollinger Bands
    sma = pd.Series(close).rolling(window=bb_period).mean().values
    std = pd.Series(close).rolling(window=bb_period).std().values
    bb_upper = sma + bb_std * std
    bb_lower = sma - bb_std * std

    # 2. Relative Strength Index (RSI)
    delta = pd.Series(close).diff()
    gain = delta.clip(lower=0)
    loss = -delta.clip(upper=0)
    avg_gain = gain.rolling(window=rsi_period).mean()
    avg_loss = loss.rolling(window=rsi_period).mean()
    rs = avg_gain / (avg_loss + 1e-12)
    rsi = 100.0 - (100.0 / (1.0 + rs))
    rsi = rsi.values

    # 3. Average True Range (ATR)
    tr1 = high - low
    tr2 = np.abs(high - np.roll(close, 1))
    tr3 = np.abs(low - np.roll(close, 1))
    tr2[0] = tr1[0]
    tr3[0] = tr1[0]
    tr = np.maximum(tr1, np.maximum(tr2, tr3))
    atr = pd.Series(tr).rolling(window=atr_period).mean().values

    df['sma'] = sma
    df['bb_upper'] = bb_upper
    df['bb_lower'] = bb_lower
    df['rsi'] = rsi
    df['atr'] = atr
    return df


def simulate_ablation_arm(df: pd.DataFrame, arm_type: str, initial_capital=10000.0, commission_per_lot=7.0, spread_usd=0.30):
    """
    Simulates trading on real market prices for one of the 4 ablation arms:
    - 'raw_signal': Indicator entry, fixed 0.1 lot, hard SL=1.5*ATR, TP=1.5*ATR
    - 'grid_overlay': Indicator entry, 0.1 lot base, grid layers step=1.5*ATR, mult=1.2, aggregate TP=1.0*ATR, NO hard SL
    - 'disciplined_risk': Indicator entry, 1% equity risk lot size, hard SL=1.5*ATR, TP=3.0*ATR
    - 'random_grid': Random entry, identical grid overlay as arm 2
    """
    n = len(df)
    balance = initial_capital
    equity = initial_capital
    max_equity = initial_capital
    min_margin = 10000.0
    
    trades = []
    equity_curve = []
    daily_returns = []

    # State tracking
    active_orders = [] # list of dicts: {'type': 1/-1, 'open_price': p, 'lots': l, 'open_idx': i}
    rng = np.random.RandomState(42)

    for i in range(30, n):
        row = df.iloc[i]
        curr_price = row['close']
        curr_high = row['high']
        curr_low = row['low']
        curr_atr = row['atr'] if not np.isnan(row['atr']) else curr_price * 0.01

        # Calculate floating PnL
        floating_pnl = 0.0
        used_margin = 0.0
        for ord_info in active_orders:
            lots = ord_info['lots']
            entry_p = ord_info['open_price']
            is_long = (ord_info['type'] == 1)
            # Contract size: 100 oz for gold or 100,000 for FX
            contract_size = 100.0
            pnl_pts = (curr_price - entry_p) if is_long else (entry_p - curr_price)
            pos_pnl = pnl_pts * contract_size * lots - (commission_per_lot * lots) - (spread_usd * contract_size * lots)
            floating_pnl += pos_pnl
            used_margin += (curr_price * contract_size * lots) / 100.0 # 1:100 leverage

        equity = balance + floating_pnl
        if equity > max_equity:
            max_equity = equity

        curr_margin_lvl = (equity / used_margin * 100.0) if used_margin > 0 else 10000.0
        if curr_margin_lvl < min_margin:
            min_margin = curr_margin_lvl

        # Check Stop-Out liquidation boundary (20% margin level)
        if used_margin > 0 and curr_margin_lvl <= 20.0:
            # Forced liquidation
            balance = equity
            trades.append({'net_pnl': floating_pnl, 'type': 'liquidation', 'bars': 1})
            active_orders.clear()
            break

        # Entry Signals
        signal = 0 # 1: Buy, -1: Sell
        if arm_type == 'random_grid':
            if len(active_orders) == 0 and rng.rand() < 0.15:
                signal = 1 if rng.rand() < 0.5 else -1
        else:
            # Indicator signals: BB + RSI
            if curr_price <= row['bb_lower'] and row['rsi'] <= 35.0:
                signal = 1
            elif curr_price >= row['bb_upper'] and row['rsi'] >= 65.0:
                signal = -1

        # Order Management per Arm
        if arm_type == 'raw_signal':
            if len(active_orders) == 0 and signal != 0:
                sl_dist = 1.5 * curr_atr
                tp_dist = 1.5 * curr_atr
                active_orders.append({
                    'type': signal, 'open_price': curr_price, 'lots': 0.10,
                    'sl': curr_price - sl_dist if signal == 1 else curr_price + sl_dist,
                    'tp': curr_price + tp_dist if signal == 1 else curr_price - tp_dist,
                    'open_idx': i
                })
            elif len(active_orders) > 0:
                ord_info = active_orders[0]
                hit_sl = (curr_low <= ord_info['sl']) if ord_info['type'] == 1 else (curr_high >= ord_info['sl'])
                hit_tp = (curr_high >= ord_info['tp']) if ord_info['type'] == 1 else (curr_low <= ord_info['tp'])
                if hit_sl or hit_tp:
                    exit_p = ord_info['sl'] if hit_sl else ord_info['tp']
                    pnl_pts = (exit_p - ord_info['open_price']) if ord_info['type'] == 1 else (ord_info['open_price'] - exit_p)
                    realized_pnl = pnl_pts * 100.0 * ord_info['lots'] - (commission_per_lot * ord_info['lots'])
                    balance += realized_pnl
                    trades.append({'net_pnl': realized_pnl, 'type': 'win' if realized_pnl > 0 else 'loss', 'bars': i - ord_info['open_idx']})
                    active_orders.clear()

        elif arm_type in ['grid_overlay', 'random_grid']:
            grid_step = 1.5 * curr_atr
            if len(active_orders) == 0 and signal != 0:
                active_orders.append({
                    'type': signal, 'open_price': curr_price, 'lots': 0.10, 'open_idx': i
                })
            elif len(active_orders) > 0:
                first_ord = active_orders[0]
                last_ord = active_orders[-1]
                # Check adverse deviation to open next grid layer
                adverse_dist = (last_ord['open_price'] - curr_price) if first_ord['type'] == 1 else (curr_price - last_ord['open_price'])
                if adverse_dist >= grid_step and len(active_orders) < 8:
                    next_lot = round(0.10 * (1.2 ** len(active_orders)), 2)
                    active_orders.append({
                        'type': first_ord['type'], 'open_price': curr_price, 'lots': next_lot, 'open_idx': i
                    })

                # Check basket aggregate profit target (0.8 * ATR)
                tot_lot = sum(o['lots'] for o in active_orders)
                w_entry = sum(o['open_price'] * o['lots'] for o in active_orders) / tot_lot
                basket_dist = (curr_price - w_entry) if first_ord['type'] == 1 else (w_entry - curr_price)
                if basket_dist >= 0.8 * curr_atr:
                    # Close all grid layers
                    tot_pnl = 0.0
                    for o in active_orders:
                        pnl_pts = (curr_price - o['open_price']) if o['type'] == 1 else (o['open_price'] - curr_price)
                        tot_pnl += pnl_pts * 100.0 * o['lots'] - (commission_per_lot * o['lots'])
                    balance += tot_pnl
                    trades.append({'net_pnl': tot_pnl, 'type': 'win' if tot_pnl > 0 else 'loss', 'bars': i - first_ord['open_idx']})
                    active_orders.clear()

        elif arm_type == 'disciplined_risk':
            if len(active_orders) == 0 and signal != 0:
                sl_dist = 1.5 * curr_atr
                tp_dist = 3.0 * curr_atr
                risk_amt = balance * 0.01 # 1% risk
                lot_size = max(0.01, round(risk_amt / (sl_dist * 100.0), 2))
                active_orders.append({
                    'type': signal, 'open_price': curr_price, 'lots': lot_size,
                    'sl': curr_price - sl_dist if signal == 1 else curr_price + sl_dist,
                    'tp': curr_price + tp_dist if signal == 1 else curr_price - tp_dist,
                    'open_idx': i
                })
            elif len(active_orders) > 0:
                ord_info = active_orders[0]
                hit_sl = (curr_low <= ord_info['sl']) if ord_info['type'] == 1 else (curr_high >= ord_info['sl'])
                hit_tp = (curr_high >= ord_info['tp']) if ord_info['type'] == 1 else (curr_low <= ord_info['tp'])
                if hit_sl or hit_tp:
                    exit_p = ord_info['sl'] if hit_sl else ord_info['tp']
                    pnl_pts = (exit_p - ord_info['open_price']) if ord_info['type'] == 1 else (ord_info['open_price'] - exit_p)
                    realized_pnl = pnl_pts * 100.0 * ord_info['lots'] - (commission_per_lot * ord_info['lots'])
                    balance += realized_pnl
                    trades.append({'net_pnl': realized_pnl, 'type': 'win' if realized_pnl > 0 else 'loss', 'bars': i - ord_info['open_idx']})
                    active_orders.clear()

        equity_curve.append(equity)
        if len(equity_curve) > 1:
            ret = (equity_curve[-1] - equity_curve[-2]) / equity_curve[-2]
            daily_returns.append(ret)

    # Compute Final Statistics
    net_profit = balance - initial_capital
    eq_series = np.array(equity_curve)
    peaks = np.maximum.accumulate(eq_series)
    dds = (eq_series - peaks) / peaks * 100.0
    max_dd = abs(np.min(dds)) if len(dds) > 0 else 0.0

    wins = [t['net_pnl'] for t in trades if t['net_pnl'] > 0]
    losses = [abs(t['net_pnl']) for t in trades if t['net_pnl'] < 0]
    gross_win = sum(wins)
    gross_loss = sum(losses)
    profit_factor = (gross_win / gross_loss) if gross_loss > 0 else (99.0 if gross_win > 0 else 0.0)
    win_rate = (len(wins) / len(trades) * 100.0) if len(trades) > 0 else 0.0

    rets = np.array(daily_returns)
    skew = float(stats.skew(rets)) if len(rets) > 10 else 0.0
    kurt = float(stats.kurtosis(rets)) if len(rets) > 10 else 0.0
    sharpe = float(np.mean(rets) / (np.std(rets) + 1e-9) * np.sqrt(252)) if len(rets) > 10 else 0.0

    return {
        "arm": arm_type,
        "trades_count": len(trades),
        "win_rate_pct": round(win_rate, 2),
        "net_profit_usd": round(net_profit, 2),
        "profit_factor": round(profit_factor, 2),
        "max_drawdown_pct": round(max_dd, 2),
        "min_margin_level": round(min_margin, 2),
        "return_skewness": round(skew, 2),
        "return_kurtosis": round(kurt, 2),
        "annualized_sharpe": round(sharpe, 2)
    }


def run_full_ablation():
    print("==========================================================")
    print(" Running Paired 4-Arm Ablation Suite on Real Historical Data")
    print(" Strategy: BBRSI (XAUUSD / Gold)")
    print("==========================================================")

    data_file = DATA_DIR / "XAUUSD_1d.csv"
    if not data_file.exists():
        print(f"[-] Data file {data_file} not found. Running downloader...")
        import tools.download_market_data as dmd
        dmd.download_all()

    df = pd.read_csv(data_file)
    df.columns = [c.lower() for c in df.columns]
    df['date'] = pd.to_datetime(df['date'])
    df = df.sort_values('date').reset_index(drop=True)
    df = calculate_indicators(df)

    # Split: In-Sample (2021-2023) and Out-of-Sample (2024-2025)
    df_is = df[(df['date'] >= '2021-01-01') & (df['date'] <= '2023-12-31')].reset_index(drop=True)
    df_oos = df[(df['date'] >= '2024-01-01') & (df['date'] <= '2025-12-31')].reset_index(drop=True)

    print(f"[*] In-Sample bars (2021-2023): {len(df_is)}")
    print(f"[*] Out-of-Sample bars (2024-2025): {len(df_oos)}")

    arms = [
        ("raw_signal", "Arm 1: Raw Signal + Fixed Lot (No Grid)"),
        ("grid_overlay", "Arm 2: Raw Signal + Unhedged Grid Overlay"),
        ("disciplined_risk", "Arm 3: Raw Signal + Volatility Risk Sizing & Hard SL"),
        ("random_grid", "Arm 4: Pseudo-Random Entry + Grid Overlay (Control)")
    ]

    results = {
        "strategy": "BBRSI",
        "symbol": "XAUUSD (Gold)",
        "in_sample": {},
        "out_of_sample": {},
        "full_period": {}
    }

    for arm_key, arm_desc in arms:
        print(f"\n[*] Evaluating {arm_desc}...")
        res_is = simulate_ablation_arm(df_is, arm_key)
        res_oos = simulate_ablation_arm(df_oos, arm_key)
        res_full = simulate_ablation_arm(df, arm_key)

        results["in_sample"][arm_key] = res_is
        results["out_of_sample"][arm_key] = res_oos
        results["full_period"][arm_key] = res_full

        print(f"    In-Sample  -> PF: {res_is['profit_factor']}, Net: ${res_is['net_profit_usd']}, MaxDD: {res_is['max_drawdown_pct']}%, WinRate: {res_is['win_rate_pct']}%, Skew: {res_is['return_skewness']}")
        print(f"    Out-Sample -> PF: {res_oos['profit_factor']}, Net: ${res_oos['net_profit_usd']}, MaxDD: {res_oos['max_drawdown_pct']}%, WinRate: {res_oos['win_rate_pct']}%, Skew: {res_oos['return_skewness']}")

    out_json = BENCHMARKS_DIR / "ablation_study.json"
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print(f"\n[+] Ablation study successfully completed! Saved to {out_json}")


if __name__ == "__main__":
    run_full_ablation()
