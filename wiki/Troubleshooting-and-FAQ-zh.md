# 常见问题与排错指南 (Troubleshooting & FAQ)

<p align="center">
  <a href="Troubleshooting-and-FAQ"><strong>English</strong></a> | 
  <a href="Troubleshooting-and-FAQ-zh"><strong>简体中文</strong></a>
</p>

本指南汇总了在 MetaTrader 5 (MT5) 中安装、编译及运行 Berrytrade-EA 策略时最常见的问题与解决方案。

---

## 1. 高频问题排查

### 问题一：EA 已经挂载到图表上，但一直不开单？
**请按以下顺序检查：**
1. **顶部“算法交易”总开关**：查看 MT5 顶部工具栏，“算法交易”图标是否为**绿色播放符号**。如果是红色方块，点击将其打开。
2. **图表右上角权限**：按键盘快捷键 `F7` 调出 EA 属性设置，切换到 **常规 (Common)** 选项卡，确保勾选了 **“允许算法交易 (Allow Algo Trading)”**。
3. **查看日志终端**：按快捷键 `Ctrl+T` 调出工具箱，查看 **智能交易系统 (Experts)** 和 **日志 (Journal)** 标签：
   - 若出现 `trade disabled by broker`，说明经纪商账号只读或未开通真实交易权限，或者当前处于休市时间。
   - 若出现 `spread exceeds maximum`，说明当前点差高于策略设定的最大容忍点差 `InpMaxSpreadPoints`，EA 正在风控等待点差回落。

---

### 问题二：报错 “Invalid Stops”（错误码 4756 / 10016）
**原因**：设定的止损价（Stop-Loss）或止盈价（Take-Profit）距离当前市价过近，违反了经纪商规定的最小挂单/止损间距（`SYMBOL_TRADE_STOPS_LEVEL`）。  
**解决方法**：
- 在 EA 参数设置中调大止损点数 `InpStopLossPoints` 和止盈点数 `InpTakeProfitPoints`。
- 在 MT5 品种列表中右键点击该品种 -> 选择 **规格 (Specification)**，查看该品种的“止损位”最小限制。

---

### 问题三：报错 “Volume Invalid” 或 “Not Enough Money”（错误码 10014 / 10019）
**原因**：
- 计算出来的下单手数小于经纪商最小下单手数（如 0.01），或者不满足手数步长限制。
- 账户可用预付款不足以支付所选交易品种的开仓保证金。  
**解决方法**：
- 确认当前账户净值满足该策略 `metadata.json` 中标注的“最低建议本金”。
- 微调 EA 参数中的单笔风险比例 `InpRiskPercent` 或直接指定固定手数。

---

### 问题四：MetaEditor 编译时报错找不到 `#include <Berrytrade\...>`
**原因**：未将公共依赖库复制到 MT5 的全局头文件目录。  
**解决方法**：
- 运行自动部署脚本：
  ```powershell
  powershell ./tools/sync_to_mt5.ps1 -MT5DataPath "<您的MT5数据目录路径>"
  ```
- 或手动将 `shared/Include/Berrytrade` 文件夹复制到 `<MT5数据目录>/MQL5/Include/` 下。

---

### 问题五：可以在云服务器 (VPS) 上挂机吗？
**非常推荐**：对于需要 5x24 小时不间断运行的量化 EA，推荐在靠近经纪商机房（如伦敦、纽约或法兰克福）的 Windows VPS 上运行，能够避免家庭断网、停电或系统更新重启造成的持仓失控风险。
