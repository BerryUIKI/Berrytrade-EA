# 策略选型与全景手册 (Strategy Catalog)

<p align="center">
  <a href="Strategy-Catalog"><strong>English</strong></a> | 
  <a href="Strategy-Catalog-zh"><strong>简体中文</strong></a>
</p>

本页提供 Berrytrade-EA 仓库中已入库策略的详细横向对比，帮助您根据自身资金体量、关注品种与风险承受度挑选合适的量化策略。

---

## 当前已入库策略列表

### 1. TemplateEA
- **质量梯队**：`experimental`（孵化实验区）
- **策略类型**：趋势跟踪 (Trend Following)
- **推荐品种**：`XAUUSD` (现货黄金), `EURUSD` (欧元美元)
- **推荐周期**：`M5` (5分钟图)
- **风险等级**：🟢 低风险 (Low Risk)
- **最低建议本金**：$1,000 美元
- **核心逻辑**：采用双 EMA 均线金叉死叉确认动量方向，配合动态净值百分比仓位换算、ATR 硬止损及周五晚间自动平仓离场保护机制。
- **源码与预设**：[查看 TemplateEA 源码与参数目录](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/TemplateEA)

---

## 策略与市场行情适配矩阵

| 市场特征 / 行情阶段 | 推荐策略类型 | 核心风控考量点 |
| :--- | :--- | :--- |
| **单边强趋势行情** | 趋势跟踪 (`trend_following`) | 捕捉长波段收益；在横盘震荡时会承受连续轻微磨损 |
| **箱体震荡 / 盘整行情** | 均值回归 (`mean_reversion`) | 在通道上下轨高抛低吸；必须具备突破止损机制 |
| **欧美盘开盘高波动** | 突破交易 (`breakout`) | 爆发力强，顺势动能明显；需防范假突破洗盘 |
| **亚盘夜间低波动** | 剥头皮 (`scalping`) | 极度依赖超低原始点差与延迟低于 10ms 的极速 VPS |

---

## 如何提议新策略入库？

若您有出色的交易理念或指标想移植为 MT5 EA：
1. 访问 GitHub 发起 [策略提案 Issue (Strategy Proposal)](https://github.com/BerryUIKI/Berrytrade-EA/issues/new?template=ea_submission_proposal.md)。
2. 社区中的量化开发者将协助进行 MQL5 代码实现、参数优化与基准回测。
