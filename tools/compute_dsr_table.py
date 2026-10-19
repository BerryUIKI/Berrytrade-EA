"""
Compute Deflated Sharpe Ratio (DSR) Input Matrix and Statistical Diagnostics
Strictly using Bailey & Lopez de Prado (2014) formulation and genuine daily equity logs.
"""
import os
import json
import numpy as np
import pandas as pd
from scipy import stats

def compute_dsr():
    strategies_dir = "strategies"
    daily_equity_files = {}

    for cat in ["experimental", "benchmarks"]:
        cat_dir = os.path.join(strategies_dir, cat)
        if not os.path.exists(cat_dir):
            continue
        for name in os.listdir(cat_dir):
            csv_path = os.path.join(cat_dir, name, "reports", "daily_equity.csv")
            if os.path.exists(csv_path):
                daily_equity_files[name] = csv_path

    results = []
    sharpe_list = []

    # First pass: compute returns, moments, Sharpe
    for name, path in sorted(daily_equity_files.items()):
        df = pd.read_csv(path)
        if len(df) < 5:
            continue
        col = "equity" if "equity" in df.columns else "balance"
        equity = df[col].values
        # Filter out 0.0 before first deposit
        equity = equity[equity > 0]
        if len(equity) < 10:
            continue
        rets = np.diff(equity) / equity[:-1]
        rets = rets[~np.isnan(rets) & ~np.isinf(rets)]
        if len(rets) < 5 or np.std(rets) == 0:
            continue

        T = len(rets)
        mean_r = np.mean(rets)
        std_r = np.std(rets, ddof=1)
        # Annualized Sharpe (assuming 252 trading days)
        sr_daily = mean_r / std_r
        sr_ann = sr_daily * np.sqrt(252)

        skew = stats.skew(rets)
        kurt = stats.kurtosis(rets, fisher=False) # Pearson kurtosis (normal = 3)

        sharpe_list.append(sr_ann)
        results.append({
            "strategy": name,
            "T": T,
            "sr_ann": sr_ann,
            "sr_daily": sr_daily,
            "skew": skew,
            "kurt": kurt,
        })

    # Variance of Sharpe across trials
    var_sr = np.var(sharpe_list, ddof=1)
    std_sr = np.sqrt(var_sr)
    N = len(results) # or total parameter trials
    gamma_E = 0.5772156649

    # Bailey & Lopez de Prado (2014) SR* threshold
    # Formula (8): SR* = sqrt(V) * [ (1 - gamma_E) * NormInv(1 - 1/N) + gamma_E * NormInv(1 - 1/(N*e)) ]
    term1 = (1.0 - gamma_E) * stats.norm.ppf(1.0 - 1.0 / N)
    term2 = gamma_E * stats.norm.ppf(1.0 - 1.0 / (N * np.e))
    sr_star_ann = std_sr * (term1 + term2)
    sr_star_daily = sr_star_ann / np.sqrt(252)

    output_rows = []
    for r in results:
        # Standard error under non-normality (Mertens 2002 / Lo 2002 / Bailey & Lopez de Prado 2014)
        # using daily moments and daily SR
        denom = np.sqrt(1.0 - r["skew"] * r["sr_daily"] + ((r["kurt"] - 1.0) / 4.0) * (r["sr_daily"] ** 2))
        if denom <= 0 or np.isnan(denom):
            denom = 1.0
        
        # Test statistic Z
        z_stat = ((r["sr_daily"] - sr_star_daily) * np.sqrt(r["T"] - 1.0)) / denom
        dsr_val = stats.norm.cdf(z_stat)
        p_val = 1.0 - dsr_val

        output_rows.append({
            "strategy": r["strategy"],
            "T": r["T"],
            "sr_ann": round(r["sr_ann"], 2),
            "skew": round(r["skew"], 2),
            "kurt": round(r["kurt"], 2),
            "N_trials": N,
            "var_sr": round(var_sr, 3),
            "sr_star": round(sr_star_ann, 2),
            "z_stat": round(z_stat, 2),
            "dsr": round(dsr_val, 4),
            "p_value": round(p_val, 4)
        })

    out_file = "benchmarks/dsr_analysis.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(output_rows, f, indent=2)

    print(f"[+] Computed DSR for {len(output_rows)} strategies. Saved to {out_file}")
    for row in output_rows:
        print(f"  {row['strategy']:15} | SR: {row['sr_ann']:5.2f} | Skew: {row['skew']:5.2f} | Kurt: {row['kurt']:6.2f} | DSR: {row['dsr']:.4f} | p-val: {row['p_value']:.4f}")

if __name__ == "__main__":
    compute_dsr()
