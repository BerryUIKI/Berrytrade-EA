# Getting Started with Berrytrade-EA

<p align="center">
  <a href="Getting-Started"><strong>English</strong></a> | 
  <a href="Getting-Started-zh"><strong>简体中文</strong></a>
</p>

This guide walks you through installing MetaTrader 5, installing Berrytrade-EA strategies, loading parameter presets, and launching an EA on a chart.

---

## Step 1: Install MetaTrader 5
1. Download MetaTrader 5 from your regulated broker or the official MetaQuotes website.
2. Open a **Demo Account** first to test strategies risk-free.

---

## Step 2: Install Strategies into MT5

### Method A: Automated Deployment (Recommended)
You can use the built-in PowerShell synchronization script to install all strategies and shared libraries into your MT5 terminal:

1. In MT5, click **File -> Open Data Folder**.
2. Copy the full path displayed in Windows Explorer (e.g. `C:\Users\<User>\AppData\Roaming\MetaQuotes\Terminal\<INSTANCE_ID>`).
3. Open PowerShell in the `Berrytrade-EA` directory and run:
   ```powershell
   powershell ./tools/sync_to_mt5.ps1 -MT5DataPath "<YOUR_MT5_DATA_PATH>"
   ```
4. Restart MetaTrader 5 or right-click **Expert Advisors** in the Navigator panel and click **Refresh**.

### Method B: Manual Installation
1. Copy `strategies/{tier}/<EA>/src/*.mq5` into `<MT5_Data_Folder>/MQL5/Experts/Berrytrade/<EA>/`.
2. Copy `shared/Include/Berrytrade/` into `<MT5_Data_Folder>/MQL5/Include/Berrytrade/`.
3. Copy `strategies/{tier}/<EA>/presets/*.set` into `<MT5_Data_Folder>/MQL5/Profiles/Tester/`.
4. Open the MetaEditor (press `F4`), open the `.mq5` file, and press `F7` to compile.

---

## Step 3: Enable Algorithmic Trading in MT5
Before an EA can execute trades, you must grant automated trading permissions:

1. Go to **Tools -> Options -> Expert Advisors** (or press `Ctrl+O`).
2. Check **"Allow Algo Trading"**.
3. (Optional) Check **"Allow WebRequest for listed URL"** only if a specific strategy requires economic calendar APIs.
4. On the main MT5 toolbar, ensure the **"Algo Trading"** button is clicked and shows a **green play icon**.

---

## Step 4: Attach EA to Chart & Apply Preset

1. In the MT5 Market Watch window, right-click the desired symbol (e.g. `XAUUSD`) and select **Chart Window**.
2. Set the chart timeframe according to the strategy's recommendation (e.g. `M5`).
3. In the Navigator window, expand **Expert Advisors -> Berrytrade** and drag your chosen EA onto the chart.
4. In the EA configuration dialog:
   - Go to the **Inputs** tab.
   - Click **Load...** and select the corresponding preset file (e.g. `Default_XAUUSD_M5.set`).
   - Review your risk settings (e.g. `InpRiskPercent` or `InpStopLossPoints`).
5. Click **OK**.
6. Verify that a blue hat or green icon appears in the top-right corner of your chart, indicating the EA is active.
