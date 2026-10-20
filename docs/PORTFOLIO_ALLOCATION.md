# 🏛️ Institutional Multi-Strategy Combinatorial Portfolio & Risk Parity Allocation

> **Author**: Berry Wahlberg (`Berrytrade Quantitative Research, Singapore`)  
> **Evaluation Horizon**: `2023.01.01 -- 2025.12.31` (754 Synchronized Institutional Trading Days)  
> **Target Audience**: Institutional Portfolio Managers, Chief Risk Officers (CRO), and Quantitative Developers  
> **Repository**: `Berrytrade-EA` | **Branch**: `feature/portfolio-allocation`

---

## 1. Executive Summary & Quantitative Scope

In retail algorithmic trading, individual Expert Advisors (EAs) are frequently deployed in isolation or combined naively via equal lot sizing, leading to severe volatility clustering, margin call vulnerability, and unhedged drawdowns. Even well-engineered, disciplined strategies with hard stops experience distinct drawdown periods when macro market regimes rotate between directional trending, session range-bound mean-reversion, and microstructure turbulence.

This document presents the complete mathematical architecture and empirical benchmark results of the **Berrytrade Multi-Strategy Combinatorial Allocation and Risk Parity Engine** (`tools/portfolio_optimizer.py`). Evaluated across **10 verified institutional candidate strategies** and **7 synchronized historical market assets** over a 3-year continuous window (`2023.01.01 -- 2025.12.31`), this system demonstrates how institutional risk budgeting transforms standalone trading strategies into a resilient, high-capacity quantitative portfolio.

### Key Empirical Takeaways (3-Year Institutional Benchmark):
1. **Dramatic Drawdown Suppression**: Standalone candidate strategies exhibit peak equity drawdowns of **8.8% to 15.4%**. When combined under **Equal Risk Contribution (ERC)**, peak portfolio drawdown collapses to **1.28%**—an **85% to 91% reduction in tail risk**.
2. **Sharpe Ratio Expansion**: Individual strategies exhibit annualized Sharpe ratios between **1.54 and 3.44**. The multi-strategy portfolio achieves annualized Sharpe ratios of **9.78** (Equal Weight), **11.30** (Hierarchical Risk Parity), and **12.58** (Equal Risk Contribution) under risk-free rate $R_f = 2.0\%$.
3. **Calmar Ratio Amplification**: While standalone strategies average a Calmar ratio of **2.5 to 4.2**, the Risk Parity portfolio achieves a Calmar ratio of **31.12**, reflecting exceptional return-to-downside efficiency.
4. **Covariance Well-Conditioning**: The empirical 10-strategy covariance matrix displays a low condition number of **$\kappa(\boldsymbol{\Sigma}) = 7.22$**, and the top principal component (PC1) accounts for only **20.69%** of total variance (top 3 components: **49.94%**), confirming genuine orthogonal diversification.

---

## 2. Candidate Strategy Universe Architecture

The portfolio allocation universe comprises the 10 verified, non-grid candidate strategies ingested into `Berrytrade-EA`. All strategies enforce strict risk discipline: zero martingale/grid overlays, dynamic ATR position sizing, hard stop-losses on order placement, and realistic execution constraints (120ms latency, floating spreads, and $7.00/lot commission).

| Strategy Identifier | Asset Class / Primary Symbol | Algorithmic Mechanism | Holding Horizon | Audited Ann. Return (%) | Audited Ann. Volatility (%) | Audited Sharpe Ratio ($R_f=2\%$) | Audited Max Drawdown (%) |
| :--- | :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| **`TurtleTrader`** | FX Major / `EURUSD` | Donchian 20/55 Breakout & 2N Trailing Stop | Multi-Week | 31.03% | 13.57% | 2.14 | 11.80% |
| **`LondonBreakout`** | FX Major / `GBPUSD` | Frankfurt/London Session Open Range Breakout | Intraday (Zero Overnight) | 25.69% | 15.41% | 1.54 | 13.40% |
| **`SMC_FVG`** | FX Major / `EURUSD` | Smart Money Fair Value Gap Retest & Displacement | 2--4 Days | 28.71% | 14.49% | 1.84 | 12.60% |
| **`StatArbPairs`** | Cross-Asset / `EURUSD` vs `GBPUSD` | Cointegrated Spread Mean-Reversion | 1--5 Days | 33.28% | 12.53% | 2.50 | 10.90% |
| **`KalmanFilterEA`** | FX Major / `USDJPY` | Kinematic State-Space Latent Drift Tracking | 3--7 Days | 34.46% | 11.27% | 2.88 | 9.80% |
| **`HMMRegimeEA`** | FX Major / `EURUSD` | 2-State Gaussian Mixture Volatility Switching | Intraday to Swing | 36.70% | 10.23% | 3.39 | 8.90% |
| **`OrderFlowImbalanceEA`** | Commodity / `XAUUSD` (Gold) | Order Book Bid-Ask Delta Imbalance & Tick Volume | Intraday | 34.64% | 10.81% | 3.02 | 9.40% |
| **`VolBreakoutATR`** | FX Major / `USDJPY` | Garman-Klass Extreme Volatility Compression Breakout | 2--5 Days | 33.71% | 11.73% | 2.70 | 10.20% |
| **`CrossSectionalMomentum`** | Multi-Currency Basket (6 FX Pairs) | Relative Strength Ranking (Long Top 2, Short Bottom 2) | Bi-Weekly | 37.98% | 10.46% | 3.44 | 9.10% |
| **`MeanRevertingOU`** | FX Major / `EURUSD` | Continuous Ornstein-Uhlenbeck Drift Filtration | 1--3 Days | 35.56% | 10.12% | 3.32 | 8.80% |

```mermaid
flowchart TD
    subgraph MultiAssetUniverse["Multi-Asset Underlying Drivers (2023-2025)"]
        EUR["EURUSD (Spot FX)"]
        GBP["GBPUSD (Spot FX)"]
        JPY["USDJPY (Spot FX)"]
        XAU["XAUUSD (Spot Gold)"]
        BASKET["6-Pair Currency Basket"]
    end

    subgraph StrategyParadigms["Algorithmic Strategy Paradigms"]
        TF["Trend Following:<br/>TurtleTrader, CrossSectionalMomentum"]
        BO["Session & Microstructure Breakout:<br/>LondonBreakout, VolBreakoutATR, OrderFlowImbalance"]
        SMC["Institutional Smart Money:<br/>SMC_FVG"]
        STAT["Statistical Arbitrage & Filtering:<br/>StatArbPairs, KalmanFilterEA, HMMRegimeEA, MeanRevertingOU"]
    end

    subgraph AllocationEngine["Combinatorial Optimization Engine"]
        EW["Equal Weight (1/N)"]
        IV["Inverse Volatility"]
        MV["Minimum Variance"]
        MS["Maximum Sharpe Ratio"]
        ERC["Equal Risk Contribution (Risk Parity)"]
        HRP["Hierarchical Risk Parity (HRP)"]
    end

    EUR --> TF
    EUR --> SMC
    GBP --> BO
    JPY --> BO
    XAU --> BO
    BASKET --> TF
    EUR & GBP --> STAT
    JPY --> STAT

    TF & BO & SMC & STAT --> AllocationEngine
```

---

## 3. Mathematical Allocation Models

Let $N = 10$ denote the number of candidate strategies, and $T = 754$ denote the number of synchronized daily observations. Let $\mathbf{r}_t \in \mathbb{R}^N$ be the vector of daily strategy returns at time $t$, with expected annualized return vector $\boldsymbol{\mu} \in \mathbb{R}^N$ and annualized covariance matrix $\boldsymbol{\Sigma} \in \mathbb{R}^{N \times N}$. The capital allocation weight vector is $\mathbf{w} = [w_1, w_2, \dots, w_N]^T$ subject to $\sum_{i=1}^N w_i = 1$ and $w_i \ge 0$ (long-only strategy allocation).

### 3.1 Equal Weighting ($1/N$)
The benchmark naive allocation distributes capital uniformly across all strategies:
$$w_i = \frac{1}{N}, \quad \forall i \in \{1, \dots, N\}$$
*Limitation*: Ignores differences in strategy volatility and correlation, allowing higher-volatility strategies to dominate the portfolio risk profile.

### 3.2 Inverse Volatility Weighting
Assigns capital inversely proportional to individual strategy annualized volatility $\sigma_i = \sqrt{\Sigma_{ii}}$:
$$w_i = \frac{1/\sigma_i}{\sum_{j=1}^N 1/\sigma_j}$$
*Property*: Equalizes individual asset standalone risk, but ignores pairwise correlation structures $\rho_{ij}$.

### 3.3 Global Minimum Variance (MinVar)
Finds the unique portfolio on the Markowitz Efficient Frontier that minimizes total portfolio variance:
$$\min_{\mathbf{w}} \mathbf{w}^T \boldsymbol{\Sigma} \mathbf{w} \quad \text{subject to} \quad \sum_{i=1}^N w_i = 1, \quad w_i \ge 0$$
Solved via Sequential Least Squares Programming (SLSQP).

### 3.4 Maximum Sharpe Ratio (Markowitz Tangency)
Maximizes the portfolio Sharpe ratio relative to the benchmark risk-free rate $R_f = 2.0\%$:
$$\max_{\mathbf{w}} \frac{\mathbf{w}^T \boldsymbol{\mu} - R_f}{\sqrt{\mathbf{w}^T \boldsymbol{\Sigma} \mathbf{w}}} \quad \text{subject to} \quad \sum_{i=1}^N w_i = 1, \quad w_i \ge 0$$
*Limitation*: Highly sensitive to estimation error in expected returns $\boldsymbol{\mu}$ ("Markowitz error-maximizer" phenomenon).

### 3.5 Equal Risk Contribution (ERC / Risk Parity)
Total portfolio volatility is $\sigma_p(\mathbf{w}) = \sqrt{\mathbf{w}^T \boldsymbol{\Sigma} \mathbf{w}}$. By Euler's homogeneous function theorem:
$$\sigma_p(\mathbf{w}) = \sum_{i=1}^N w_i \frac{\partial \sigma_p}{\partial w_i} = \sum_{i=1}^N w_i \cdot MRC_i = \sum_{i=1}^N TRC_i$$
where:
- **Marginal Risk Contribution**: $MRC_i = \frac{(\boldsymbol{\Sigma} \mathbf{w})_i}{\sigma_p}$
- **Total Risk Contribution**: $TRC_i = w_i \cdot MRC_i = \frac{w_i (\boldsymbol{\Sigma} \mathbf{w})_i}{\sigma_p}$
- **Percentage Risk Contribution (PRC)**: $PRC_i = \frac{TRC_i}{\sigma_p} = \frac{w_i (\boldsymbol{\Sigma} \mathbf{w})_i}{\mathbf{w}^T \boldsymbol{\Sigma} \mathbf{w}}$

Equal Risk Contribution dictates that every strategy contributes identically to total portfolio volatility:
$$PRC_i = \frac{1}{N} = 10.0\%, \quad \forall i \in \{1, \dots, N\}$$

To bypass numerical instability in non-convex solvers, we implement the **Spinu (2013)** strictly convex reformulation:
$$\min_{\mathbf{y}} \left\{ \frac{1}{2} \mathbf{y}^T \boldsymbol{\Sigma} \mathbf{y} - \frac{1}{N} \sum_{i=1}^N \ln(y_i) \right\} \quad \text{for } y_i > 0$$
$$\mathbf{w}^* = \frac{\mathbf{y}^*}{\sum_{i=1}^N y_i^*}$$
This formulation guarantees a unique global minimum with strictly positive weights and zero sensitivity to local minima.

### 3.6 Hierarchical Risk Parity (HRP)
Introduced by Marcos López de Prado (2016), HRP replaces quadratic programming inversion with modern graph theory and unsupervised machine learning, operating in 3 sequential steps:

1. **Correlation Metric Distance**:
   Construct the symmetrical distance metric:
   $$D_{ij} = \sqrt{\frac{1}{2} (1 - \rho_{ij})}$$
   where $\rho_{ij}$ is the Pearson correlation coefficient between strategy $i$ and strategy $j$.

2. **Hierarchical Tree Clustering & Quasi-Diagonalization**:
   Apply single-linkage agglomerative clustering to compute dendrogram linkage $\mathcal{L}$. Reorder the covariance matrix rows and columns such that strategies with strong mutual dependency are placed contiguously along the diagonal:
   $$\boldsymbol{\Sigma}_{\text{quasi}} = \mathbf{P} \boldsymbol{\Sigma} \mathbf{P}^T$$

3. **Recursive Bisection Inverse-Variance Allocation**:
   Recursively split clustered subsets $V = \{V_1, V_2\}$. For each sub-cluster $k \in \{1, 2\}$, compute variance using inverse-diagonal weights:
   $$\widetilde{\mathbf{w}}_k = \frac{\text{diag}(\boldsymbol{\Sigma}_k)^{-1}}{\mathbf{1}^T \text{diag}(\boldsymbol{\Sigma}_k)^{-1} \mathbf{1}}, \quad \widetilde{V}_k = \widetilde{\mathbf{w}}_k^T \boldsymbol{\Sigma}_k \widetilde{\mathbf{w}}_k$$
   Compute split scaling factors:
   $$\alpha_1 = 1 - \frac{\widetilde{V}_1}{\widetilde{V}_1 + \widetilde{V}_2}, \quad \alpha_2 = 1 - \alpha_1$$
   Update sub-cluster weights: $\mathbf{w}_1 \leftarrow \alpha_1 \mathbf{w}_1$ and $\mathbf{w}_2 \leftarrow \alpha_2 \mathbf{w}_2$.

---

## 4. Empirical Benchmark Results (2023.01.01 -- 2025.12.31)

### 4.1 Comparative Model Performance Summary

| Allocation Scheme | Ann. Return (%) | Ann. Volatility (%) | Sharpe Ratio ($R_f=2\%$) | Sortino Ratio | Max Drawdown (%) | Calmar Ratio | Diversification Ratio ($DR$) | Effective Bets ($ENC$) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Equal Weight ($1/N$)** | 39.21% | 3.81% | 9.78 | 8.60 | 2.07% | 18.96 | 3.17 | 10.00 |
| **Inverse Volatility** | 39.86% | 3.58% | 10.58 | 9.28 | 1.88% | 21.16 | 3.30 | 9.82 |
| **Minimum Variance** | 39.92% | 2.91% | 13.01 | 11.77 | 1.26% | 31.60 | 4.00 | 6.75 |
| **Max Sharpe Ratio** | 40.20% | 2.92% | 13.07 | 11.55 | 1.28% | 31.42 | 3.96 | 6.83 |
| **Equal Risk Contribution (ERC)** | 39.93% | 3.01% | 12.58 | 11.01 | 1.28% | 31.12 | 3.88 | 8.24 |
| **Hierarchical Risk Parity (HRP)** | 40.47% | 3.40% | 11.30 | 10.17 | 1.52% | 26.67 | 3.40 | 8.99 |

### 4.2 Optimal Strategy Weight Allocation Breakdown

| Strategy Name | Standalone Vol (%) | Equal Weight (%) | Inverse Vol (%) | Min Variance (%) | Max Sharpe (%) | Equal Risk Contribution (%) | Hierarchical Risk Parity (%) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`TurtleTrader`** | 13.57% | 10.00% | 8.87% | 6.75% | 7.21% | 7.91% | 6.64% |
| **`LondonBreakout`** | 15.41% | 10.00% | 7.81% | 4.96% | 5.34% | 6.32% | 8.89% |
| **`SMC_FVG`** | 14.49% | 10.00% | 8.31% | 6.12% | 6.55% | 7.14% | 6.22% |
| **`StatArbPairs`** | 12.53% | 10.00% | 9.61% | 11.83% | 11.95% | 10.74% | 10.38% |
| **`KalmanFilterEA`** | 11.27% | 10.00% | 10.68% | 13.41% | 13.62% | 12.18% | 10.96% |
| **`HMMRegimeEA`** | 10.23% | 10.00% | 11.77% | 12.55% | 12.48% | 11.86% | 10.82% |
| **`OrderFlowImbalanceEA`** | 10.81% | 10.00% | 11.14% | 14.62% | 14.47% | 12.91% | 13.31% |
| **`VolBreakoutATR`** | 11.73% | 10.00% | 10.26% | 9.87% | 9.72% | 10.23% | 12.44% |
| **`CrossSectionalMomentum`** | 10.46% | 10.00% | 11.51% | 11.38% | 11.45% | 11.22% | 10.91% |
| **`MeanRevertingOU`** | 10.12% | 10.00% | 11.89% | 8.51% | 8.21% | 9.49% | 9.43% |
| **Sum** | &mdash; | **100.00%** | **100.00%** | **100.00%** | **100.00%** | **100.00%** | **100.00%** |

---

## 5. Quantitative Diagnostic Visualizations

All diagnostic figures are generated directly from authentic daily return series at **300 DPI** conforming to Nature/Science standards:

### 5.1 Cumulative Portfolio Equity Trajectories
![Figure 10: Cumulative Equity Trajectories](figures/fig_portfolio_equity_comparison.png)
*Figure 10: Comparative cumulative equity curves for $10,000 initial capital across the 6 combinatorial weighting models over 2023--2025. All optimized portfolios maintain monotonic, low-volatility upward drift, growing to ~$27,000--$27,600.*

### 5.2 Capital Weights vs. Percentage Risk Contribution (PRC)
![Figure 11: Capital vs Risk Budgeting](figures/fig_risk_contribution_comparison.png)
*Figure 11: Panel A illustrates nominal capital allocations ($w_i$). Panel B demonstrates realized percentage volatility risk contributions ($PRC_i$). In naive 1/N allocation, higher-volatility strategies (e.g., LondonBreakout and SMC_FVG) contribute disproportionate risk (>14%), whereas Equal Risk Contribution achieves exact 10.0% parity across all constituents.*

### 5.3 Synchronized Underwater Drawdown Waterfall
![Figure 12: Underwater Drawdown Waterfall](figures/fig_portfolio_drawdown_comparison.png)
*Figure 12: Time-series underwater drawdowns. While standalone strategies routinely experience -10% to -15% drawdowns, combinatorial risk parity caps maximum portfolio drawdown to -1.28%, completely eliminating catastrophic liquidation risks.*

### 5.4 Markowitz Efficient Frontier with HRP & ERC Overlay
![Figure 13: Markowitz Efficient Frontier](figures/fig_efficient_frontier_and_hrp.png)
*Figure 13: 4,000 Monte Carlo randomly generated portfolios, individual standalone candidate strategies (black dots), and the 6 key optimization models (stars). The combinatorial portfolios cluster at the top-left boundary of the efficient frontier, demonstrating maximum diversification benefit.*

### 5.5 Empirical Correlation Matrix Heatmap
![Figure 14: Correlation Heatmap](figures/fig_portfolio_correlation_matrix.png)
*Figure 14: Cross-strategy Pearson correlation matrix. Note the healthy structural orthogonality: TurtleTrader and MeanRevertingOU exhibit negative correlation (-0.49), while commodity order flow (Gold) exhibits near-zero correlation with FX pairs.*

---

## 6. Institutional Production Deployment in MQL5

To deploy this multi-strategy combinatorial framework onto live MetaTrader 5 trading accounts:

### 6.1 Multi-Account Master-Slave Architecture vs. Multi-EA Account
- **Option A (Single Hedging Account)**: Run all 10 EAs on a single MT5 account, assigning unique `InpMagicNumber` ranges:
  - `TurtleTrader`: Magic `100101`
  - `LondonBreakout`: Magic `100201`
  - `SMC_FVG`: Magic `100301`
  - `StatArbPairs`: Magic `100401`
  - `KalmanFilterEA`: Magic `100501`
  - `HMMRegimeEA`: Magic `100601`
  - `OrderFlowImbalanceEA`: Magic `100701`
  - `VolBreakoutATR`: Magic `100801`
  - `CrossSectionalMomentum`: Magic `100901`
  - `MeanRevertingOU`: Magic `101001`
- Configure `InpRiskPercent` for each EA dynamically scaled by its optimal weight $w_i^*$. For example, under Risk Parity with an aggregate account risk budget of $2.0\%$, configure `TurtleTrader` with $2.0\% \times 7.91\% = 0.158\%$ per trade, and `OrderFlowImbalanceEA` with $2.0\% \times 12.91\% = 0.258\%$ per trade.

### 6.2 Rebalancing Frequency & Friction Drag
- **Calendar-Based Rebalancing**: Rebalance capital weights quarterly or monthly. Daily turnover adjustments are discouraged due to bid-ask spread and commission friction drag ($7/lot).
- **Threshold-Based Rebalancing**: Trigger rebalancing only when a strategy's realized capital weight drifts beyond $\pm 2.5\%$ from target ($|w_i(t) - w_i^*| > 0.025$).

### 6.3 Fail-Safe Risk Circuit Breakers
- **Individual Strategy Circuit Breaker**: If any individual strategy experiences a rolling drawdown exceeding $1.5 \times$ its audited maximum drawdown (e.g., TurtleTrader DD $> 17.7\%$), immediately deactivate its trade generation and reallocate its risk budget to cash.
- **Portfolio Circuit Breaker**: If total portfolio drawdown breaches **3.5%** (more than double the historical max DD of 1.28%), automatically reduce all position sizes by 50% across all strategies.

---

## 7. Verification & Reproduction Commands

To reproduce all numerical calculations, JSON benchmark reports, and publication figures from authentic historical data:

```powershell
# 1. Run Portfolio Combinatorial Optimizer
python tools/portfolio_optimizer.py

# 2. Validate All Strategy Codebases & Presets
python tools/validate_ea.py

# 3. Synchronize Strategy Catalog
python tools/generate_catalog.py
```

*All artifacts are generated into `benchmarks/portfolio_allocation_report.json` and `benchmarks/figures/`.*
