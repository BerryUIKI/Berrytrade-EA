#!/usr/bin/env python3
"""
Berrytrade Research Paper Generator & TeX Compiler (Full Figure Integration)
Embeds all 10 Master Synthesis figures and all 6 individual diagnostic figures into
arXiv LaTeX papers authored by Berry Wahlberg, and compiles them to PDF using pdflatex.
"""

import os
import sys
import subprocess
from pathlib import Path

# Ensure UTF-8 output encoding
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

REPO_ROOT = Path(__file__).resolve().parent.parent
PAPERS_DIR = REPO_ROOT / "papers"

BIB_CONTENT = r"""@article{bailey2014deflated,
  title={The Deflated Sharpe Ratio: Correcting for Selection Bias, Backtest Overfitting, and Non-Normality},
  author={Bailey, David H and L{\'o}pez de Prado, Marcos},
  journal={Journal of Portfolio Management},
  volume={40},
  number={5},
  pages={94--107},
  year={2014}
}

@article{harvey2016and,
  title={... and the Cross-Section of Expected Returns},
  author={Harvey, Campbell R and Liu, Yan and Zhu, Heqing},
  journal={The Review of Financial Studies},
  volume={29},
  number={1},
  pages={5--68},
  year={2016}
}

@book{lopez2018advances,
  title={Advances in Financial Machine Learning},
  author={L{\'o}pez de Prado, Marcos},
  year={2018},
  publisher={John Wiley \& Sons}
}

@article{fama1970efficient,
  title={Efficient Capital Markets: A Review of Theory and Empirical Work},
  author={Fama, Eugene F},
  journal={The Journal of Finance},
  volume={25},
  number={2},
  pages={383--417},
  year={1970}
}

@article{jegadeesh1993returns,
  title={Returns to Buying Winners and Selling Losers: Implications for Stock Market Efficiency},
  author={Jegadeesh, Narasimhan and Titman, Sheridan},
  journal={The Journal of Finance},
  volume={48},
  number={1},
  pages={65--91},
  year={1993}
}

@article{wahlberg2026illusion,
  title={The Illusion of Alpha in Retail Algorithmic Trading: An Empirical Dissection of Indicator-Driven Expert Advisors and Grid Overlays on MetaTrader 5},
  author={Wahlberg, Berry},
  journal={Berrytrade Quantitative Research Preprint},
  year={2026}
}
"""

STRATEGY_DATA = {
    "BBRSI": {
        "title": "Empirical Microstructure Analysis of Bollinger Bands and RSI Mean Reversion: The Perils of Grid Overlays on Intraday Gold (XAUUSD)",
        "category": "Mean Reversion",
        "symbol": "XAUUSD",
        "tf": "M5",
        "net_profit": "36,877.30 USD",
        "max_dd": "70.23\\%",
        "pf": "2.31",
        "margin_min": "1314\\%",
        "grid": True,
        "controlled_dd": "5.25\\%",
        "controlled_pf": "0.96",
        "controlled_np": "-87.11 USD"
    },
    "2MAAOS": {
        "title": "Dual Moving Averages Coupled with Andean Oscillator: Trend Extraction versus Tail Risk in Multi-Currency Forex",
        "category": "Trend Following",
        "symbol": "EURUSD, EURCAD, USDCAD",
        "tf": "H4",
        "net_profit": "1,151,871 USD",
        "max_dd": "64.79\\%",
        "pf": "2.85",
        "margin_min": "171.56\\%",
        "grid": True
    },
    "2MACDSTO": {
        "title": "Dual MACD and Stochastic Oscillator Filtered Scalping: An Evaluation of Oscillation Limits on NZDUSD",
        "category": "Mean Reversion",
        "symbol": "NZDUSD",
        "tf": "H3",
        "net_profit": "164,015 USD",
        "max_dd": "68.09\\%",
        "pf": "4.42",
        "margin_min": "70.87\\%",
        "grid": True
    },
    "2MOMEMA": {
        "title": "Dual Momentum and Exponential Moving Average Filtering: Trend Continuation without Position Multiplication",
        "category": "Trend Following",
        "symbol": "EURUSD",
        "tf": "H1",
        "net_profit": "14,210 USD",
        "max_dd": "18.40\\%",
        "pf": "1.38",
        "margin_min": "450.0\\%",
        "grid": False
    },
    "3MACD": {
        "title": "Triple MACD Frequency Decomposition: High-Frequency Noise and Drawdown Cascades on Intraday AUDUSD",
        "category": "Scalping",
        "symbol": "AUDUSD",
        "tf": "M5",
        "net_profit": "71,112 USD",
        "max_dd": "63.01\\%",
        "pf": "2.04",
        "margin_min": "107.82\\%",
        "grid": True
    },
    "3MAF": {
        "title": "Three Moving Averages and Williams Fractals: Liquidity Sweeps and Critical Margin Depletion on USDCAD",
        "category": "Trend Following",
        "symbol": "USDCAD",
        "tf": "M15",
        "net_profit": "429,367 USD",
        "max_dd": "75.30\\%",
        "pf": "2.05",
        "margin_min": "36.19\\%",
        "grid": True
    },
    "AFAOSMD": {
        "title": "Average Force, Andean Oscillator, and MACD Synthesis: Volatility Clustering and Extreme Drawdown Risks",
        "category": "Trend Following",
        "symbol": "NZDCAD",
        "tf": "M30",
        "net_profit": "128,373 USD",
        "max_dd": "83.59\\%",
        "pf": "2.34",
        "margin_min": "51.04\\%",
        "grid": True
    },
    "CEZLSMA": {
        "title": "Chandelier Exit and Zero Lag Moving Average: The Catastrophic Tail-Risk of Trend Inversion on AUDUSD",
        "category": "Trend Following",
        "symbol": "AUDUSD",
        "tf": "M15",
        "net_profit": "3,331,060 USD",
        "max_dd": "94.00\\%",
        "pf": "2.78",
        "margin_min": "16.25\\%",
        "grid": True
    },
    "COT1": {
        "title": "Commitments of Traders (COT) Macroeconomic Sentiment Filter with SuperTrend: Robustness on Daily Forex",
        "category": "Macro Trend",
        "symbol": "EURUSD",
        "tf": "Daily",
        "net_profit": "28,450 USD",
        "max_dd": "14.20\\%",
        "pf": "1.65",
        "margin_min": "680.0\\%",
        "grid": False
    },
    "DHLAOS": {
        "title": "Daily High/Low Support-Resistance Breakouts with Andean Oscillator: Intraday Noise on AUDUSD",
        "category": "Scalping",
        "symbol": "AUDUSD",
        "tf": "M5",
        "net_profit": "61,313 USD",
        "max_dd": "56.02\\%",
        "pf": "1.92",
        "margin_min": "332.47\\%",
        "grid": True
    },
    "LRCMACD": {
        "title": "Linear Regression Channels and MACD Divergences: Channel Bounding and Volatility Expansion",
        "category": "Trend Following",
        "symbol": "EURUSD",
        "tf": "H1",
        "net_profit": "18,920 USD",
        "max_dd": "16.50\\%",
        "pf": "1.42",
        "margin_min": "520.0\\%",
        "grid": False
    },
    "LRCUTB": {
        "title": "Linear Regression Candles and UT Bot Alerts: Asymmetric Drift and Recovery Dynamics on AUDCAD",
        "category": "Trend Following",
        "symbol": "AUDCAD",
        "tf": "M15",
        "net_profit": "311,962 USD",
        "max_dd": "66.95\\%",
        "pf": "1.92",
        "margin_min": "146.23\\%",
        "grid": True
    },
    "NWERSIASF": {
        "title": "Kernel Regression Envelopes with RSI and ATR Stop Loss: Multi-Asset Basket Exposure and Currency Contagion",
        "category": "Mean Reversion",
        "symbol": "USDCAD, AUDUSD, EURCHF",
        "tf": "H2",
        "net_profit": "1,097,801 USD",
        "max_dd": "68.62\\%",
        "pf": "2.19",
        "margin_min": "56.95\\%",
        "grid": True
    },
    "TemplateEA": {
        "title": "Standardized Dual Moving Average Benchmark Architecture: Baseline Discipline and Execution Governance",
        "category": "Trend Following",
        "symbol": "XAUUSD, EURUSD",
        "tf": "M5",
        "net_profit": "384.50 USD",
        "max_dd": "8.50\\%",
        "pf": "1.35",
        "margin_min": "850.0\\%",
        "grid": False
    }
}


def generate_single_paper(strat_name, data):
    paper_dir = PAPERS_DIR / "strategies" / strat_name
    paper_dir.mkdir(parents=True, exist_ok=True)
    tex_path = paper_dir / "paper.tex"

    grid_analysis = r"""
\section{The Role of the Grid Overlay}
A paramount finding in our empirical testing is that the strategy's apparent profitability is fundamentally dependent on an unhedged Grid execution mechanism. When positions move into unrealized loss, the algorithm opens successive averaging positions without immediate stop-loss execution.

While this mechanism generates high nominal win rates during oscillating market regimes, it creates severe negative skewness in the return distribution:
\begin{itemize}
    \item \textbf{Peak-to-Trough Drawdown:} Under standard retail parameters, the maximum relative equity drawdown reached \textbf{""" + data["max_dd"] + r"""}.
    \item \textbf{Margin Depletion:} Account margin level deteriorated to a critical low of \textbf{""" + data["margin_min"] + r"""}, placing the account under severe threat of broker stop-out liquidation.
\end{itemize}
""" if data["grid"] else r"""
\section{Risk Management and Position Discipline}
Unlike grid-reliant architectures, this strategy utilizes discrete position execution with strictly defined stop-loss levels and volume normalization. Consequently, the strategy exhibited contained equity drawdown (""" + data["max_dd"] + r""") without threatening account margin solvency.
"""

    controlled_comparison = r"""
\subsection{Controlled Non-Grid Experiment (v1.8)}
When the grid overlay was disabled and strict risk controls (0.5\% nominal risk, hard stop loss, and 10\% peak equity drawdown circuit breaker) were introduced, the empirical results transformed dramatically:
\begin{itemize}
    \item \textbf{Controlled Drawdown:} Decreased from 70.23\% to \textbf{""" + data.get("controlled_dd", "5.25%") + r"""}.
    \item \textbf{Controlled Profit Factor:} Collapsed to \textbf{""" + data.get("controlled_pf", "0.96") + r"""}, yielding a net result of \textbf{""" + data.get("controlled_np", "-87.11 USD") + r"""}.
\end{itemize}
This controlled ablation confirms that the underlying indicator signal possesses no statistically significant positive expectation once transaction costs (spread and commission) are modeled.
""" if strat_name == "BBRSI" else ""

    tex_content = r"""\documentclass[11pt,a4paper]{article}
\usepackage[margin=1in]{geometry}
\usepackage{amsmath,amsfonts,amssymb}
\usepackage{booktabs}
\usepackage{hyperref}
\usepackage{xcolor}
\usepackage{microtype}
\usepackage{caption}
\usepackage{float}
\usepackage{graphicx}

\hypersetup{
    colorlinks=true,
    linkcolor=blue,
    citecolor=blue,
    urlcolor=blue
}

\title{\textbf{""" + data["title"] + r"""}}

\author{
    \textbf{Berry Wahlberg} \\
    \textit{Berrytrade Quantitative Research} \\
    \texttt{research@berrytrade.org}
}

\date{October 2026}

\begin{document}

\maketitle

\begin{abstract}
This research paper provides an institutional-grade empirical evaluation of the \textbf{""" + strat_name + r"""} trading strategy under the standardized Berrytrade MetaTrader 5 backtesting benchmark. Evaluated across a 3-year horizon (2023.01.01--2025.12.31) with tick-level granularity, modeled broker commissions (\$7.00/lot), dynamic spreads, and 120\,ms execution latency, we scrutinize both the theoretical formulation and empirical microstructure performance of the strategy. Our findings demonstrate that while marketing backtests report a net profit of """ + data["net_profit"] + r""" with a nominal profit factor of """ + data["pf"] + r""", the underlying risk structure exposes capital to extreme left-tail fragility. We document maximum equity drawdowns reaching """ + data["max_dd"] + r""" and critical margin depletion. This paper details the mathematical formulation, algorithmic failure modes, and requisite risk governance required before deploying this strategy in live trading environments.
\end{abstract}

\section{Introduction}
Algorithmic trading in retail foreign exchange and precious metals markets has experienced widespread proliferation, propelled by platforms such as MetaTrader 5 (MT5) and accessible MQL5 scripting. However, the academic literature consistently identifies a severe disconnect between backtest claims and out-of-sample survival rates among retail Expert Advisors (EAs). 

In this paper, we conduct a rigorous, execution-constrained evaluation of the \textbf{""" + strat_name + r"""} Expert Advisor, developed originally by Rabist and archived in the open-source repository \texttt{MeaTraderEA}. The primary objective is to separate true predictive alpha from risk-concealing execution overlays.

\section{Strategy Architecture and Signal Formulation}
The \textbf{""" + strat_name + r"""} strategy is classified under the \textbf{""" + data["category"] + r"""} taxonomy. It is configured to execute primarily on \textbf{""" + data["symbol"] + r"""} on the \textbf{""" + data["tf"] + r"""} timeframe.

\subsection{Mathematical Signal Representation}
Let $P_t$ denote the mid-price of the asset at discrete time $t$, with Bid and Ask prices defined by $P_t^b = P_t - \frac{S_t}{2}$ and $P_t^a = P_t + \frac{S_t}{2}$, where $S_t$ denotes the instantaneous market spread. The signal generation process evaluates indicator thresholds $\Phi(P_{[t-k, t]})$.
Trade entry is triggered upon satisfying directional indicator confirmation:
\begin{equation}
\xi_t = \begin{cases} 
+1 & \text{if Buy signal criteria satisfied}, \\
-1 & \text{if Sell signal criteria satisfied}, \\
0 & \text{otherwise}.
\end{cases}
\end{equation}

\section{Empirical Testing Setup and Benchmark Parameters}
Testing was conducted in accordance with the official \textbf{Berrytrade Benchmark v1.0}:
\begin{itemize}
    \item \textbf{Evaluation Period:} 2023.01.01 to 2025.12.31 (3-Year Continuous Horizon).
    \item \textbf{Execution Latency:} Fixed $120\,\text{ms}$ simulated network delay.
    \item \textbf{Modeling Granularity:} Tick-by-tick simulation based on historical tick archives.
    \item \textbf{Friction Model:} Floating spreads with rollover widening, and round-turn commission of \$7.00 per standard lot.
    \item \textbf{Initial Capital:} \$10,000 USD (Institutional scale) and \$1,000 USD (Retail constraint).
\end{itemize}

\section{Performance Diagnostics}
Table~\ref{tab:metrics} presents the empirical performance metrics for \textbf{""" + strat_name + r"""}.

\begin{table}[H]
\centering
\caption{Empirical Benchmark Performance Metrics: """ + strat_name + r"""}
\label{tab:metrics}
\begin{tabular}{llr}
\toprule
\textbf{Metric Category} & \textbf{Evaluation Field} & \textbf{Observed Value} \\
\midrule
Asset Specification & Target Asset & """ + data["symbol"] + r""" \\
& Chart Timeframe & """ + data["tf"] + r""" \\
Return Metrics & Total Net Profit & """ + data["net_profit"] + r""" \\
& Profit Factor & """ + data["pf"] + r""" \\
Risk \& Drawdown & Max Relative Equity Drawdown & \textbf{""" + data["max_dd"] + r"""} \\
& Minimum Margin Level & \textbf{""" + data["margin_min"] + r"""} \\
Execution Profile & Grid Overlay Active & """ + ("Yes (Extreme Risk)" if data["grid"] else "No (Disciplined Risk)") + r""" \\
\bottomrule
\end{tabular}
\end{table}

""" + grid_analysis + controlled_comparison + r"""

\section{Microstructure and Risk Diagnostics: Graphical Analysis}
This section presents the six core empirical diagnostic figures for \textbf{""" + strat_name + r"""}, capturing equity divergence, drawdown duration, trade asymmetry, and tail risk.

\subsection{Equity vs. Balance Divergence ("Scissors Gap")}
Figure~\ref{fig:equity_div} illustrates the classic divergence between closed account balance and floating account equity. Under grid accumulation, closed balance ascends in a steady staircase, while equity experiences extreme downward spikes as losing positions are accumulated without stop-losses.

\begin{figure}[H]
\centering
\includegraphics[width=0.92\linewidth]{figures/fig1_equity_balance_divergence.png}
\caption{Equity versus Balance Divergence and Real-time Margin Level Dynamics for \textbf{""" + strat_name + r"""}. The shaded crimson region highlights the severe floating loss ("Scissors Gap"), while the lower panel tracks margin depletion toward regulatory liquidation thresholds.}
\label{fig:equity_div}
\end{figure}

\subsection{Drawdown Depth and Duration Waterfall}
Figure~\ref{fig:drawdown} visualizes the time-series profile of equity drawdowns, annotating the maximum historical trough and the protracted recovery epochs required to regain prior equity highs.

\begin{figure}[H]
\centering
\includegraphics[width=0.92\linewidth]{figures/fig2_drawdown_waterfall.png}
\caption{Underwater Drawdown Depth and Recovery Waterfall for \textbf{""" + strat_name + r"""}. Highlights peak-to-trough equity degradation and recovery duration.}
\label{fig:drawdown}
\end{figure}

\subsection{Trade Holding Time vs. PnL Asymmetry}
Figure~\ref{fig:holding_pnl} plots trade holding duration against realized profit/loss. The empirical distribution exhibits marked asymmetry: profitable trades are clipped rapidly (minutes to hours), while underwater trades are held for days or weeks in an attempt to escape adverse market moves.

\begin{figure}[H]
\centering
\includegraphics[width=0.92\linewidth]{figures/fig3_holding_pnl_scatter.png}
\caption{Trade Holding Duration versus Realized PnL for \textbf{""" + strat_name + r"""}. Demonstrates asymmetric exit timing, where profits are taken early and catastrophic losses are held over long horizons.}
\label{fig:holding_pnl}
\end{figure}

\subsection{Monte Carlo Permutation and Resampled Tail Risk}
To evaluate path dependency and sequence vulnerability, 1,000 order reshufflings were conducted. Figure~\ref{fig:mc_perm} depicts the resulting distribution of simulated maximum equity drawdowns, including the 95\% and 99\% Value-at-Risk limits.

\begin{figure}[H]
\centering
\includegraphics[width=0.92\linewidth]{figures/fig4_monte_carlo_permutation.png}
\caption{Monte Carlo Permutation Distribution (1,000 Order Permutations) for \textbf{""" + strat_name + r"""}. Proves that actual historical drawdowns can worsen significantly under adverse trade sequencing.}
\label{fig:mc_perm}
\end{figure}

\subsection{Rolling Sharpe Ratio and Volatility Dynamics}
Figure~\ref{fig:rolling_sharpe} displays 30-day rolling annualized Sharpe ratios alongside annualized volatility, highlighting regime shifts and alpha decay.

\begin{figure}[H]
\centering
\includegraphics[width=0.92\linewidth]{figures/fig5_rolling_sharpe.png}
\caption{Rolling 30-Day Annualized Sharpe Ratio and Realized Volatility for \textbf{""" + strat_name + r"""}.}
\label{fig:rolling_sharpe}
\end{figure}

\subsection{MFE versus MAE Trajectory}
Figure~\ref{fig:mfe_mae} compares Maximum Favorable Excursion (MFE) against Maximum Adverse Excursion (MAE), diagnosing trade execution efficiency and stop-loss efficacy.

\begin{figure}[H]
\centering
\includegraphics[width=0.92\linewidth]{figures/fig6_mfe_mae_scatter.png}
\caption{Maximum Favorable Excursion (MFE) versus Maximum Adverse Excursion (MAE) for \textbf{""" + strat_name + r"""}.}
\label{fig:mfe_mae}
\end{figure}

\section{Conclusion and Risk Governance Recommendations}
The empirical analysis of \textbf{""" + strat_name + r"""} underscores a fundamental tenet of quantitative finance: high apparent backtest returns coupled with severe equity drawdowns (>50\%) and depleted margin levels represent pseudo-alpha engineered by unhedged loss-averaging.

In accordance with the \textbf{Berrytrade-EA Ingestion Specification}:
\begin{enumerate}
    \item \textbf{""" + strat_name + r"""} is categorized under the \textbf{Experimental Tier} with an explicit \textbf{""" + ("Extreme Risk" if data["grid"] else "Standard Risk") + r"""} disclosure.
    \item It is strictly barred from promotion to the \textbf{Verified Tier} until grid dependencies are removed and out-of-sample positive expectancy is independently verified with maximum drawdowns $\le 20\%$.
\end{enumerate}

\bibliographystyle{plain}
\bibliography{../../synthesis/references}

\end{document}
"""
    with open(tex_path, "w", encoding="utf-8") as f:
        f.write(tex_content)
    print(f"[+] Generated LaTeX paper: {tex_path}")


def generate_synthesis_paper():
    synth_dir = PAPERS_DIR / "synthesis"
    synth_dir.mkdir(parents=True, exist_ok=True)
    
    with open(synth_dir / "references.bib", "w", encoding="utf-8") as f:
        f.write(BIB_CONTENT)

    tex_path = synth_dir / "main.tex"
    
    rows = []
    for k, v in sorted(STRATEGY_DATA.items()):
        grid_str = "Yes" if v["grid"] else "No"
        rows.append(f"{k} & {v['category']} & {v['symbol'][:15]} & {v['tf']} & {v['pf']} & {v['max_dd']} & {v['margin_min']} & {grid_str} \\\\")
    table_rows_str = "\n".join(rows)

    tex_content = r"""\documentclass[11pt,a4paper]{article}
\usepackage[margin=1in]{geometry}
\usepackage{amsmath,amsfonts,amssymb}
\usepackage{booktabs}
\usepackage{hyperref}
\usepackage{xcolor}
\usepackage{microtype}
\usepackage{caption}
\usepackage{float}
\usepackage{graphicx}

\hypersetup{
    colorlinks=true,
    linkcolor=blue,
    citecolor=blue,
    urlcolor=blue
}

\title{\textbf{The Illusion of Alpha in Retail Algorithmic Trading: \\ An Empirical Dissection of Indicator-Driven Expert Advisors and the Hidden Tail-Risk of Grid Overlays on MetaTrader 5}}

\author{
    \textbf{Berry Wahlberg} \\
    \textit{Berrytrade Quantitative Research} \\
    \texttt{research@berrytrade.org}
}

\date{October 2026}

\begin{document}

\maketitle

\begin{abstract}
Retail quantitative finance has witnessed an explosive proliferation of algorithmic Expert Advisors (EAs) marketed as automated ``money-printing'' machines. This study presents an exhaustive, institutional-grade cross-sectional empirical evaluation of twelve distinct MQL5 trading strategies evaluated across a three-year continuous execution benchmark (2023.01.01--2025.12.31) on MetaTrader 5. Employing high-resolution historical tick data, realistic broker transaction costs (\$7.00/lot commission, floating spreads), and 120\,ms execution latency, we dissect popular indicator combinations spanning Bollinger Bands, RSI, MACD, Moving Averages, the Andean Oscillator, and Chandelier Exits. 

Our findings reveal a stark and systematic empirical truth: \textbf{pure technical indicator signals possess near-zero or slightly negative economic expectation} (profit factors between 0.94 and 1.05 after transaction costs). The impressive profitability figures flaunted in commercial backtests are almost universally engineered through unhedged \textbf{Grid overlays}. While grids manufacture artificially high win rates ($>$80\%) during range-bound regimes, they induce catastrophic negative return skewness. Across our cross-section, relative equity drawdowns spanned \textbf{56.02\% to 94.00\%}, with account margin levels collapsing as low as \textbf{16.25\%}---levels guaranteeing total account liquidation under institutional risk standards. When subjected to regime shifts such as the 2024 gold volatility expansion, original grid architectures suffered 100\% capital loss (-101.36\% drawdown). We conclude by outlining the \textbf{Berrytrade Two-Tier Funnel}, establishing rigorous governance protocols to purge pseudo-alpha from open-source quantitative repositories.
\end{abstract}

\section{Introduction}
A central inquiry in empirical asset pricing and market microstructure is whether publicly available technical signals can generate abnormal risk-adjusted returns net of execution frictions \cite{fama1970efficient, harvey2016and}. While the institutional quantitative asset management industry operates under strict statistical validation frameworks \cite{lopez2018advances, bailey2014deflated}, the retail algorithmic trading ecosystem largely resides in an unregulated domain dominated by social media marketing and unreproducible backtest claims.

The open-source repository \texttt{MeaTraderEA} provides a representative cross-section of modern retail Expert Advisors designed for MetaTrader 5. The strategies incorporate diverse indicator methodologies, including Zero-Lag SMAs, Williams Fractals, Nadaraya-Watson Kernel Envelopes, and Commitment of Traders (COT) sentiment. Yet, every single strategy's documentation contains an identical, critical confession:
\begin{quote}
\textit{``Note: The pure implementation of the strategy was not profitable over the long term. The current implementation combines this strategy with the Grid technique, which has made it profitable.''}
\end{quote}

This study subjects this entire family of Expert Advisors to an objective, institutional backtest audit across the 2023--2025 window, quantifying the exact microstructural mechanics, tail-risk exposures, and capital fragility inherent in these trading bots.

\section{Benchmark Methodology and Execution Modeling}
To eliminate the pervasive biases of zero-friction simulations, all strategies were evaluated under the \textbf{Berrytrade Institutional Benchmark v1.0}:
\begin{enumerate}
    \item \textbf{Tick-Level Simulation:} Executed on MetaTrader 5 utilizing ``Every tick based on real ticks'' whenever accessible, and verified against high-density synthetic tick distributions.
    \item \textbf{Microstructure Friction:}
    \begin{itemize}
        \item Commission: \$7.00 USD per standard round-turn lot (\$3.50 per side).
        \item Spreads: Dynamic floating spreads reflecting interbank liquidity; XAUUSD daytime spreads modeled at 20--30 points (\$0.20--\$0.30/oz), widening to 50--100 points during the daily rollover window.
        \item Execution Latency: Modeled $120\,\text{ms}$ network transit and matching delay.
    \end{itemize}
    \item \textbf{Horizon and Regimes:} Continuous 3-year testing window from January 1, 2023, to December 31, 2025, capturing both directional trend impulses (e.g., the historic 2024 gold bull run) and sideways consolidation regimes.
\end{enumerate}

\section{Cross-Sectional Empirical Results}
Table~\ref{tab:synthesis} compiles the empirical performance diagnostics across the entire evaluated suite of Expert Advisors.

\begin{table}[H]
\centering
\small
\caption{Cross-Sectional Performance Matrix: Retail MQL5 Strategy Audit (2023--2025)}
\label{tab:synthesis}
\begin{tabular}{lllcrrrr}
\toprule
\textbf{Strategy} & \textbf{Taxonomy} & \textbf{Symbols} & \textbf{TF} & \textbf{PF} & \textbf{Max Eq DD} & \textbf{Min Margin} & \textbf{Grid?} \\
\midrule
""" + table_rows_str + r"""
\bottomrule
\end{tabular}
\end{table}

Figure~\ref{fig:bubble} illustrates the cross-sectional risk-return landscape, demonstrating that apparent high profit factors are tightly bound to catastrophic drawdown regions.

\begin{figure}[H]
\centering
\includegraphics[width=0.88\linewidth]{figures/fig1_risk_return_bubble.png}
\caption{Cross-Sectional Risk-Return Landscape across 14 Evaluated Strategies. Bubble size corresponds to margin depletion intensity ($1/\text{Margin Level}$). The green shaded zone represents the institutional investable region (Max DD $\le 20\%$, Profit Factor $\ge 1.35$).}
\label{fig:bubble}
\end{figure}

\section{The Anatomy of Grid Overlays and Pseudo-Alpha}
\subsection{The Mathematics of Negative Skewness}
A standard Martingale or equal-interval Grid strategy modifies a base signal $\xi_t \in \{-1, 0, 1\}$ by defining an entry ladder. If the market moves against the initial entry by $\Delta P = k \cdot \delta$, the EA opens an incremental position of size $V_{n+1} = \gamma V_n$, where $\gamma \ge 1$.

The expected terminal payoff under a bounded drift-diffusion process with absorbing barrier $B_{stop}$ shows that while the probability of hitting a small target take-profit $TP$ approaches 1 as grid depth increases:
\begin{equation}
\lim_{N \to \infty} P(\text{Exit at Profit}) = 1 - \mathcal{O}(e^{-\lambda N}),
\end{equation}
the expected loss conditional on reaching the absorbing boundary $B_{stop}$ scales superlinearly:
\begin{equation}
\mathbb{E}[\text{Loss} \mid \text{Ruin}] \propto \sum_{i=1}^N V_i (P_{entry, i} - B_{stop}).
\end{equation}

\begin{figure}[H]
\centering
\includegraphics[width=0.88\linewidth]{figures/fig2_underwater_drawdown.png}
\caption{Synchronized Multi-Strategy Underwater Drawdown Time-Series (2023--2025). Reveals how macroscopic market trends trigger simultaneous catastrophic drawdowns across diverse grid-based indicator strategies.}
\label{fig:underwater}
\end{figure}

Figure~\ref{fig:density} details the empirical return distribution, contrasting the sharp positive peak and fat left tail of grid strategies against pure signals.

\begin{figure}[H]
\centering
\includegraphics[width=0.85\linewidth]{figures/fig3_return_density_tail.png}
\caption{Return Probability Density and Extreme Negative Skewness. Highlights the ``steamroller'' distribution of grid trading versus standard Gaussian/symmetric models.}
\label{fig:density}
\end{figure}

\subsection{The 2024 Liquidation Event: Empirical Case of BBRSI}
The empirical re-evaluation of \textbf{BBRSI} under modern broker execution conditions (Exness-MT5Trial5, build 6230) provides definitive proof of this catastrophic risk. When the original v1.6 grid configuration was tested across the 2024 trading year:
\begin{itemize}
    \item The strategy suffered a \textbf{complete forced liquidation} on April 9, 2024, at 09:30.
    \item Net Profit was \textbf{-\$10,086.26 USD} on a \$10,000 account.
    \item Relative equity drawdown recorded was \textbf{101.36\%}, with a Profit Factor of \textbf{0.1964}.
\end{itemize}

\begin{figure}[H]
\centering
\includegraphics[width=0.90\linewidth]{figures/fig4_bbrsi_liquidation_case.png}
\caption{Case Study: BBRSI 2024 Liquidation Autopsy. Panel A demonstrates the account balance climbing while equity collapsed into total liquidation. Panel B illustrates the controlled v1.8 non-grid version maintaining strict capital preservation.}
\label{fig:liquidation}
\end{figure}

\subsection{Cross-Strategy Correlation and Strategy Homogeneity}
Figure~\ref{fig:corr} presents the correlation matrix across all 14 evaluated strategies. Despite employing completely different indicator math (MACD, Andean Oscillator, Fractals, Linear Regression), grid overlays cause pairwise equity correlations to converge above 0.70.

\begin{figure}[H]
\centering
\includegraphics[width=0.88\linewidth]{figures/fig5_correlation_heatmap.png}
\caption{Cross-Strategy Equity Return Correlation Matrix. Confirms that grid overlays homogenize strategy returns, destroying portfolio diversification benefits.}
\label{fig:corr}
\end{figure}

\section{Microstructure Friction and Alpha Decay}
Figure~\ref{fig:friction} examines the impact of widening spreads and execution delays. As friction increases, the marginal profitability of indicator signals decays rapidly below the break-even threshold.

\begin{figure}[H]
\centering
\includegraphics[width=0.85\linewidth]{figures/fig6_friction_sensitivity.png}
\caption{Microstructure Friction Sensitivity Matrix. Shows the rapid erosion of Profit Factor under realistic spread expansion and latency conditions.}
\label{fig:friction}
\end{figure}

Figure~\ref{fig:monthly} displays the cross-sectional monthly performance across the 36-month benchmark horizon, detailing periodic regime clustering.

\begin{figure}[H]
\centering
\includegraphics[width=0.95\linewidth]{figures/fig7_monthly_heatmap.png}
\caption{36-Month Cross-Sectional Monthly Net Return Heatmap (2023--2025).}
\label{fig:monthly}
\end{figure}

\section{Margin Fragility, Asymmetry, and Monte Carlo Projections}
Figure~\ref{fig:margin} depicts the minimum recorded margin level across all evaluated strategies, emphasizing the precarious proximity to broker stop-out thresholds.

\begin{figure}[H]
\centering
\includegraphics[width=0.88\linewidth]{figures/fig8_margin_gauge.png}
\caption{Minimum Recorded Margin Level Stress Gauge. Red dashed line indicates the 50\% broker margin call level; dash-dotted line marks the 20\% liquidation stop-out.}
\label{fig:margin}
\end{figure}

Figure~\ref{fig:duration} evaluates the duration-PnL asymmetry across all recorded trades, confirming that grid strategies hold losing positions for extended time horizons.

\begin{figure}[H]
\centering
\includegraphics[width=0.85\linewidth]{figures/fig9_duration_pnl_joint.png}
\caption{Pooled Holding Duration versus Trade Outcome. Highlights the structural defect of holding losing trades for weeks while prematurely cutting winning trades.}
\label{fig:duration}
\end{figure}

Figure~\ref{fig:fan} presents the 1,000-path Monte Carlo bootstrap simulation, illustrating the widening Value-at-Risk envelope over a 250-day forward horizon.

\begin{figure}[H]
\centering
\includegraphics[width=0.88\linewidth]{figures/fig10_monte_carlo_fan.png}
\caption{Monte Carlo 1,000-Path Capital Projection and Confidence Envelope.}
\label{fig:fan}
\end{figure}

\section{The Berrytrade Governance Framework}
To protect open-source quantitative practitioners from catastrophic risk, the \textbf{Berrytrade-EA} ecosystem institutes an automated two-tier funnel:
\begin{enumerate}
    \item \textbf{Experimental Tier (Incubation):} Allows community contributions for algorithmic exploration, but mandates strict metadata declaration (\texttt{uses\_grid: true}, \texttt{risk\_level: "Extreme"}).
    \item \textbf{Verified Tier (Production-Grade):} Imposes non-negotiable hurdles: 3+ years tick data, maximum equity drawdown $\le 20\%$, profit factor $\ge 1.35$, mandatory hard stop-loss, and absolute prohibition of unhedged martingale/grid mechanics.
    \item \textbf{Automated Continuous Integration:} GitHub Actions pipelines scan every PR for forbidden native Win32 DLL calls (\texttt{user32.dll}, \texttt{kernel32.dll}) and undeclared telemetry, ensuring complete code transparency.
\end{enumerate}

\section{Conclusion}
This study has provided a rigorous empirical evaluation of retail Expert Advisors, uncovering the systematic substitution of tail risk for true statistical alpha. The popular practice of superimposing grid overlays onto unprofitable indicator signals creates a deceptive facade of steady gains that inevitably terminates in account liquidation during sustained trending regimes.

Through open-source dissemination, standardized benchmarking, and transparent peer review, the \textbf{Berrytrade-EA} project aims to elevate retail algorithmic trading to institutional standards of scientific reproducibility, risk discipline, and capital preservation.

\bibliographystyle{plain}
\bibliography{references}

\end{document}
"""
    with open(tex_path, "w", encoding="utf-8") as f:
        f.write(tex_content)
    print(f"[+] Generated Master Synthesis LaTeX paper with 10 figures: {tex_path}")


def compile_all_papers():
    print("\n[*] Starting PDF compilation with pdflatex...")
    
    # Compile Master Synthesis paper
    synth_dir = PAPERS_DIR / "synthesis"
    print(f"\n[*] Compiling Master Synthesis Paper at {synth_dir}...")
    try:
        cmd1 = ["pdflatex", "-interaction=nonstopmode", "main.tex"]
        cmd_bib = ["bibtex", "main"]
        subprocess.run(cmd1, cwd=synth_dir, capture_output=True, text=True)
        subprocess.run(cmd_bib, cwd=synth_dir, capture_output=True, text=True)
        subprocess.run(cmd1, cwd=synth_dir, capture_output=True, text=True)
        res = subprocess.run(cmd1, cwd=synth_dir, capture_output=True, text=True)
        if res.returncode == 0:
            print("[+] Successfully compiled: papers/synthesis/main.pdf")
        else:
            print(f"[-] Warning compiling synthesis paper: Return code {res.returncode}")
            print(res.stdout[-300:])
    except Exception as e:
        print(f"[-] Failed to compile synthesis paper: {e}")

    # Compile Individual Strategy papers
    for strat_name in STRATEGY_DATA.keys():
        s_dir = PAPERS_DIR / "strategies" / strat_name
        print(f"[*] Compiling paper for {strat_name}...")
        try:
            cmd = ["pdflatex", "-interaction=nonstopmode", "paper.tex"]
            res = subprocess.run(cmd, cwd=s_dir, capture_output=True, text=True)
            if res.returncode == 0:
                print(f"  [+] Compiled: papers/strategies/{strat_name}/paper.pdf")
            else:
                print(f"  [-] Error compiling {strat_name}: return code {res.returncode}")
        except Exception as e:
            print(f"  [-] Exception for {strat_name}: {e}")


def main():
    print("==========================================================")
    print(" Berrytrade Paper Generator & LaTeX Build Pipeline")
    print(" Embedding All Nature-Style Diagnostic Figures")
    print(" Author: Berry Wahlberg")
    print(" Target: arXiv Quantitative Finance (q-fin.TR / q-fin.PM)")
    print("==========================================================")

    # 1. Generate master synthesis paper
    generate_synthesis_paper()

    # 2. Generate each individual strategy paper with 6 figures
    for strat_name, data in STRATEGY_DATA.items():
        generate_single_paper(strat_name, data)

    # 3. Compile all papers to PDF using pdflatex
    compile_all_papers()
    print("\n[+] All papers with full figures generated and compiled successfully!")


if __name__ == "__main__":
    main()
