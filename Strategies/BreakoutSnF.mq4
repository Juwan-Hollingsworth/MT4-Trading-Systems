//+------------------------------------------------------------------+
//|                                                  BreakoutSnF.mq4 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com







// TF: USDJPY

// Find a 24 hour high and low rnage beased on 6pmEST
// Entries are at 7 pips above and leow the rnage
// 3 entries above and 3 entries below
// Ea entry has a SL of 25 pips
// Tp = 15,35,50pips

// Risk 1% per position - will be based on SL
// roral 3% risk per day
// Assumed using quitu risk
// Cancel other sides of trades



 |
//+------------------------------------------------------------------+

#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Inputs                                  |
//+------------------------------------------------------------------+
//Time range - 6pmEST
input int InpRangeStartHour = 1; // Range Start Hour
input int InpRangeStartMinute= 0; // Range Start Minute
input int InpRangeEndHour = 1; // Range End Hour
input int InpRangeEndMinute = 0; // Range End Minute

//Entry Inputs
input double InpRangeGapPips=7.0;
input double InpStopLossPips=25.0;
input double InpTakeProfit1Pips=15.0;
input double InpTakeProfit2Pips=35.0;
input double InpTakeProfit3Pips=50.0;

// Stnd Features
input long InpMagic= 232323; //Magic number
input string InpTradeComment = "Breakout SnF" //Trade comment
input double InpRiskPercent=1.0;


;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
