# Troubleshooting & FAQ

<p align="center">
  <a href="Troubleshooting-and-FAQ"><strong>English</strong></a> | 
  <a href="Troubleshooting-and-FAQ-zh"><strong>简体中文</strong></a>
</p>

This troubleshooting guide resolves the most common errors encountered when installing, compiling, or executing Berrytrade-EA strategies in MetaTrader 5.

---

## 1. Top Issues & Solutions

### Q1: The EA is on the chart, but it never opens any trades.
**Check the following:**
1. **Algo Trading Button**: Look at the top toolbar in MT5. Is the "Algo Trading" button green? If it is red, click it to activate automated trading.
2. **Chart Smiley / Hat Icon**: In the top-right corner of the chart, is there a grey hat or a sad face icon?
   - Press `F7` on the chart, go to the **Common** tab, and verify that **"Allow Algo Trading"** is checked.
3. **Check the Journal Tab**: Open the **Toolbox** (press `Ctrl+T`) and inspect the **Experts** and **Journal** tabs:
   - If you see `trade disabled by broker`, your broker account may not have trading permissions enabled, or the market is currently closed.
   - If you see `spread exceeds maximum`, the current market spread is higher than `InpMaxSpreadPoints`.

---

### Q2: Error "Invalid Stops" (Error 4756 / 10016).
**Cause**: The requested Stop-Loss or Take-Profit price is too close to the current Bid/Ask price, violating the broker's minimum `SYMBOL_TRADE_STOPS_LEVEL`.  
**Solution**:
- In the EA inputs, increase `InpStopLossPoints` and `InpTakeProfitPoints` to exceed your broker's minimum stop level.
- Check contract specifications in MT5 by right-clicking the symbol in Market Watch -> **Specification**.

---

### Q3: Error "Volume Invalid" or "Not Enough Money" (Error 10014 / 10019).
**Cause**:
- The calculated lot size is either smaller than the minimum allowed volume (e.g. 0.01) or does not align with the broker's volume step (e.g. 0.01 steps).
- Your account does not have sufficient free margin to cover the required initial margin.  
**Solution**:
- Ensure your deposit meets the minimum deposit listed in the strategy's `metadata.json`.
- In EA inputs, adjust `InpRiskPercent` or decrease lot size.

---

### Q4: MetaEditor gives compilation errors on `#include <Berrytrade\...>`
**Cause**: The shared header files were not copied or linked into MT5's `Include` directory.  
**Solution**:
- Run the sync tool:
  ```powershell
  powershell ./tools/sync_to_mt5.ps1 -MT5DataPath "<YOUR_MT5_DATA_PATH>"
  ```
- Or manually copy `shared/Include/Berrytrade` into `<MT5_DATA_PATH>/MQL5/Include/Berrytrade`.

---

### Q5: Can I run Berrytrade-EA on a VPS?
**Yes, highly recommended**: For strategies requiring 24/5 continuous monitoring, a Windows-based Virtual Private Server (VPS) located in London, New York, or Frankfurt (close to your broker's servers) minimizes execution latency and eliminates the risk of home power or internet outages.
