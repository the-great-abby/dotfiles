# Trading Tracking Guide: Stocks, Options, and Financial Trades

## 🎯 Overview

Tracking your trades (stocks, options, and other financial instruments) is essential for:
- **Performance Analysis**: Understanding what works and what doesn't
- **Tax Preparation**: Documenting trades for tax reporting
- **Learning**: Improving your trading strategy over time
- **Risk Management**: Monitoring exposure and managing risk
- **Compliance**: Maintaining records for regulatory requirements

This guide shows you how to track trades in your GTD system and Second Brain.

---

## 📋 Essential Information to Track

### 1. **Trade Details**
**Critical Information:**
- Trade date and time
- Instrument type (stock, option, ETF, etc.)
- Symbol/ticker
- Trade direction (buy/sell)
- Quantity/shares
- Entry price
- Exit price (if closed)
- Commission/fees
- Net profit/loss
- Trade status (open, closed, expired)

**Why it matters:**
- Accurate record keeping
- Tax reporting
- Performance tracking
- Strategy evaluation

### 2. **Strategy & Analysis**
**Critical Information:**
- Trading strategy (day trade, swing trade, long-term hold)
- Entry rationale (why you entered)
- Exit rationale (why you exited)
- Technical analysis (support, resistance, indicators)
- Fundamental analysis (if applicable)
- Market conditions
- Risk/reward ratio
- Stop loss level
- Take profit target

**Why it matters:**
- Learn from successes and failures
- Refine your strategy
- Understand what works
- Improve decision-making

### 3. **Risk Management**
**Critical Information:**
- Position size
- Risk per trade (% of portfolio)
- Stop loss level
- Maximum loss
- Risk/reward ratio
- Portfolio exposure
- Sector concentration
- Correlation with other positions

**Why it matters:**
- Protect capital
- Manage risk
- Avoid overexposure
- Maintain discipline

### 4. **Performance Metrics**
**Critical Information:**
- Win rate
- Average win
- Average loss
- Profit factor
- Maximum drawdown
- Sharpe ratio (if applicable)
- Monthly/quarterly/yearly returns
- Best/worst trades

**Why it matters:**
- Measure performance
- Identify strengths and weaknesses
- Set realistic goals
- Track progress

### 5. **Options-Specific Information**
**Critical Information:**
- Option type (call/put)
- Strike price
- Expiration date
- Premium paid/received
- Greeks (Delta, Gamma, Theta, Vega)
- Implied volatility
- Open interest
- Volume
- Assignment risk

**Why it matters:**
- Options have unique risks
- Time decay is critical
- Greeks affect pricing
- Expiration dates matter

---

## 🗺️ Organizing Trading Information

### PARA Method Organization

**Projects:**
- Active trading strategies
- Tax preparation (year-end)
- Strategy development
- Backtesting projects

**Areas:**
- **Finances** (trading as part of financial management)
- **Investments** (if separate from general finances)

**Resources:**
- Trade logs
- Strategy notes
- Market analysis
- Performance reports
- Tax documents
- Educational materials

**Archives:**
- Completed trades (closed positions)
- Old strategies
- Historical performance
- Tax records

### MOC Structure

Create a MOC for your trading:

```bash
gtd-brain-moc create "Trading Portfolio"
```

**MOC Sections:**
- Active Trades
- Closed Trades
- Strategies
- Performance Analysis
- Market Notes
- Educational Resources
- Tax Records

---

## 📝 Trade Note Templates

### Stock Trade Template

```markdown
# Trade: [SYMBOL] - [Date]

---
tags:
  - trade
  - stock
  - [strategy-type]
  - [status]
date: [YYYY-MM-DD]
symbol: [SYMBOL]
type: stock
status: [open/closed]
---

## Trade Details
- **Date**: [YYYY-MM-DD]
- **Symbol**: [SYMBOL]
- **Direction**: [Buy/Sell]
- **Quantity**: [shares]
- **Entry Price**: $[price]
- **Exit Price**: $[price] (if closed)
- **Commission**: $[amount]
- **Net P/L**: $[amount]

## Strategy
- **Strategy Type**: [Day Trade/Swing Trade/Long-term Hold]
- **Entry Rationale**: [Why you entered]
- **Exit Rationale**: [Why you exited/plan to exit]

## Analysis
### Technical Analysis
- Support: $[price]
- Resistance: $[price]
- Indicators: [list]
- Chart patterns: [description]

### Fundamental Analysis
- Sector: [sector]
- Company: [brief description]
- Catalyst: [what drove the trade]

## Risk Management
- **Position Size**: $[amount] ([%] of portfolio)
- **Risk Per Trade**: [%]
- **Stop Loss**: $[price]
- **Take Profit**: $[price]
- **Risk/Reward Ratio**: [ratio]

## Performance
- **P/L**: $[amount]
- **Return %**: [%]
- **Holding Period**: [days]

## Notes
[Additional observations, lessons learned, etc.]

## Links
- [[Trading Portfolio MOC]]
- [[Strategy - [Name]]]
- [[Market Analysis - [Date]]]
```

### Options Trade Template

```markdown
# Trade: [SYMBOL] [Call/Put] - [Date]

---
tags:
  - trade
  - options
  - [strategy-type]
  - [status]
date: [YYYY-MM-DD]
symbol: [SYMBOL]
type: option
status: [open/closed/expired]
---

## Trade Details
- **Date**: [YYYY-MM-DD]
- **Symbol**: [SYMBOL]
- **Option Type**: [Call/Put]
- **Strike**: $[price]
- **Expiration**: [YYYY-MM-DD]
- **Premium Paid/Received**: $[amount]
- **Quantity**: [contracts]
- **Commission**: $[amount]
- **Net P/L**: $[amount]

## Options Details
- **Delta**: [value]
- **Gamma**: [value]
- **Theta**: [value]
- **Vega**: [value]
- **Implied Volatility**: [%]
- **Open Interest**: [number]
- **Volume**: [number]

## Strategy
- **Strategy Type**: [Buy Call/Buy Put/Sell Call/Sell Put/Spread/etc.]
- **Entry Rationale**: [Why you entered]
- **Exit Rationale**: [Why you exited/plan to exit]

## Risk Management
- **Position Size**: $[amount] ([%] of portfolio)
- **Risk Per Trade**: [%]
- **Max Loss**: $[amount]
- **Max Profit**: $[amount]
- **Breakeven**: $[price]
- **Assignment Risk**: [Low/Medium/High]

## Performance
- **P/L**: $[amount]
- **Return %**: [%]
- **Holding Period**: [days]
- **Outcome**: [Profit/Loss/Expired]

## Notes
[Additional observations, lessons learned, etc.]

## Links
- [[Trading Portfolio MOC]]
- [[Strategy - [Name]]]
- [[Market Analysis - [Date]]]
```

---

## 🛠️ How to Track Trades

### Method 1: Individual Trade Notes (Recommended)

Create a note for each trade:

```bash
# Stock trade
gtd-brain create "Trade - AAPL 2025-01-15" Resources

# Options trade
gtd-brain create "Trade - TSLA Call 2025-01-15" Resources

# Use template
gtd-brain-template create "Stock Trade" "Trade - AAPL 2025-01-15" Resources
```

### Method 2: Daily Trade Log

Create a daily log for all trades:

```bash
# Create daily trade log
gtd-brain create "Trading Log - 2025-01-15" Resources

# Add to daily log
addInfoToDailyLog "Trade: Bought 100 shares AAPL @ $150 (Finances)"
```

### Method 3: Strategy Notes

Track trades by strategy:

```bash
# Create strategy note
gtd-brain create "Strategy - Day Trading" Resources

# Link trades to strategy
gtd-brain-connect create "Trade - AAPL 2025-01-15" "Strategy - Day Trading"
```

### Method 4: MOC Organization

Add all trades to your Trading Portfolio MOC:

```bash
# Create MOC
gtd-brain-moc create "Trading Portfolio"

# Add trade to MOC
gtd-brain-moc add "Trading Portfolio" "Trade - AAPL 2025-01-15"
```

---

## 📊 Performance Tracking

### Monthly Performance Review

Create a monthly performance note:

```bash
gtd-brain create "Performance - January 2025" Resources
```

**Track:**
- Total trades
- Win rate
- Total P/L
- Best trade
- Worst trade
- Lessons learned
- Strategy adjustments

### Quarterly Performance Review

During quarterly financial review:

```bash
gtd-review quarterly
# Answer question about financial review
# Review trading performance
```

**Review:**
- Quarterly performance
- Strategy effectiveness
- Risk management
- Goal progress
- Adjustments needed

### Annual Performance Review

During annual financial review:

```bash
gtd-review yearly
# Complete annual financial review
# Review trading performance for the year
```

**Review:**
- Annual performance
- Tax implications
- Strategy evolution
- Goal achievement
- Plan for next year

---

## 🎯 Integration with GTD System

### Create Trading Area/Project

```bash
# Create or use Finances area
gtd-area create "Finances"

# Create trading project
gtd-project create "Active Trading Strategy" --area="Finances"

# Create tax preparation project
gtd-project create "Tax Preparation - Trading" --area="Finances"
```

### Track Trading Tasks

```bash
# Daily tasks
gtd-task add "Review open positions" --area="Finances"
gtd-task add "Check stop losses" --area="Finances"
gtd-task add "Log today's trades" --area="Finances"

# Weekly tasks
gtd-task add "Review weekly performance" --area="Finances"
gtd-task add "Update trade log" --area="Finances"

# Monthly tasks
gtd-task add "Monthly performance review" --area="Finances"
gtd-task add "Review and adjust strategy" --area="Finances"
```

### Link to Daily Logs

```bash
# Quick trade log
addInfoToDailyLog "Trade: Sold 100 AAPL @ $155, +$500 (Finances)"

# Detailed log
addInfoToDailyLog "Trade: Bought TSLA call, strike $200, exp 1/31, premium $5 (Finances)"
```

### Review During Financial Reviews

```bash
# Weekly financial review
make gtd-wizard → 6) Review → 4) Financial review → 1) Weekly
# Review open positions

# Monthly financial review
make gtd-wizard → 6) Review → 4) Financial review → 2) Monthly
# Review trading performance

# Quarterly financial review
make gtd-wizard → 6) Review → 4) Financial review → 3) Quarterly
# Review strategy and performance

# Annual financial review
make gtd-wizard → 6) Review → 4) Financial review → 4) Annual
# Review annual performance and tax prep
```

---

## 💡 Pro Tips

### 1. **Log Trades Immediately**
- Don't wait to log trades
- Log before you forget details
- Use quick capture for fast logging

### 2. **Use Templates**
- Create templates for common trade types
- Standardize information
- Make logging faster

### 3. **Link Related Notes**
- Link trades to strategies
- Link to market analysis
- Link to performance reviews

### 4. **Review Regularly**
- Weekly: Review open positions
- Monthly: Review performance
- Quarterly: Review strategy
- Annually: Review and plan

### 5. **Track Lessons Learned**
- What worked?
- What didn't?
- What would you do differently?
- Update strategies based on learnings

### 6. **Maintain Tax Records**
- Keep all trade records
- Document wash sales
- Track cost basis
- Prepare for tax season

### 7. **Use Tags Consistently**
- `#trade`
- `#stock` or `#options`
- `#day-trade` or `#swing-trade`
- `#profit` or `#loss`
- `#strategy-[name]`

---

## 🚀 Quick Start Setup

### 1. Create Trading Structure

```bash
# Create MOC
gtd-brain-moc create "Trading Portfolio"

# Create strategy notes
gtd-brain create "Strategy - Day Trading" Resources
gtd-brain create "Strategy - Swing Trading" Resources
gtd-brain create "Strategy - Options" Resources

# Link to MOC
gtd-brain-moc add "Trading Portfolio" "Strategy - Day Trading"
```

### 2. Create Templates

```bash
# Create stock trade template
gtd-brain-template create "Stock Trade" "Template" Resources

# Create options trade template
gtd-brain-template create "Options Trade" "Template" Resources
```

### 3. Set Up GTD Integration

```bash
# Ensure Finances area exists
gtd-area create "Finances"

# Create trading project
gtd-project create "Active Trading" --area="Finances"
```

### 4. Create Review Habits

```bash
# Daily review habit
gtd-habit create "Review open positions" --frequency="daily" --area="Finances"

# Weekly performance review
gtd-habit create "Weekly trading review" --frequency="weekly" --area="Finances"
```

---

## 📊 Example Workflow

### Before Trading
```bash
# Review market conditions
gtd-brain create "Market Analysis - 2025-01-15" Resources

# Plan trade
gtd-brain create "Trade Plan - AAPL 2025-01-15" Resources
```

### During Trading
```bash
# Quick log
addInfoToDailyLog "Trade: Bought 100 AAPL @ $150 (Finances)"
```

### After Trading
```bash
# Create detailed trade note
gtd-brain create "Trade - AAPL 2025-01-15" Resources
# Fill in template

# Link to MOC
gtd-brain-moc add "Trading Portfolio" "Trade - AAPL 2025-01-15"

# Link to strategy
gtd-brain-connect create "Trade - AAPL 2025-01-15" "Strategy - Day Trading"
```

### Weekly Review
```bash
# Review open positions
gtd-brain list --tag="trade" --tag="open"

# Update performance
gtd-brain create "Performance - Week 3 Jan 2025" Resources
```

### Monthly Review
```bash
# Monthly performance review
gtd-review monthly
# Answer financial review questions
# Review trading performance
```

---

## 🎯 Key Metrics to Track

### Trade-Level Metrics
- Entry price
- Exit price
- P/L per trade
- Holding period
- Win/loss

### Portfolio-Level Metrics
- Total trades
- Win rate
- Average win
- Average loss
- Profit factor
- Maximum drawdown
- Monthly return
- Yearly return

### Strategy-Level Metrics
- Strategy win rate
- Strategy average return
- Strategy risk/reward
- Strategy performance vs. market

---

## 📚 Additional Resources

### Your GTD System
- `gtd-area create "Finances"` - Create financial area
- `gtd-brain-moc create "Trading Portfolio"` - Create trading MOC
- `gtd-review monthly` - Monthly financial review
- `gtd-review quarterly` - Quarterly financial review
- `gtd-review yearly` - Annual financial review

### Guides
- `zsh/FINANCIAL_REVIEW_GUIDE.md` - Financial review guide
- `zsh/PATHFINDER_ADVENTURE_TRACKING.md` - Example of detailed tracking (similar structure)

---

## 🎲 Your Trading Tracking System is Ready!

You now have a complete system for tracking:
- ✅ Individual trades (stocks and options)
- ✅ Trading strategies
- ✅ Performance metrics
- ✅ Risk management
- ✅ Tax records
- ✅ Integration with GTD reviews

Start tracking your trades today! 📈✨


