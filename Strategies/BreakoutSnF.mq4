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
input string InpTradeComment = "Breakout SnF"; //Trade comment
input double InpRiskPercent=1.0;


//+------------------------------------------------------------------+
//| Global Variables                                |
//+------------------------------------------------------------------+

double RangeGap = 0;
double StopLoss= 0;
double TakeProfit1 = 0;
double TakeProfit2 = 0;
double TakeProfit3 = 0;
double Risk = 0;

datetime StartTime=0;
datetime EndTime= 0;
bool InRange = false;



;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
    double Risk = InpRiskPercent/100;

    Alert("RiskPercent = " + string(InpRiskPercent) + ", Risk = " +string(Risk));
    bool inputsOK=true;
    
// Validate range times
if (InpRangeStartHour < 0 || InpRangeStartHour > 23){
    Print("Start hour must be from 0-23");
    bool inputsOK=false;
   
}

if (InpRangeStartMinute < 0 || InpRangeStartMinute > 59){
    Print("Start hour must be from 0-59");
    bool inputsOK=false;
}

if (InpRangeEndHour < 0 || InpRangeEndHour > 23){
    Print("Start hour must be from 0-23");
    bool inputsOK=false;
}

if (InpRangeEndMinute < 0 || InpRangeEndMinute > 59){
    Print("Start hour must be from 0-59");
    bool inputsOK=false;
}

if (InpRangeGapPips <= 0 ){
    Print("range gap must be grater than 0");
    bool inputsOK=false;
}

if (InpStopLossPips < 0 ){
    Print("stop loss must be grater than 0");
    bool inputsOK=false;
}

if (InpTakeProfit1Pips < 0 ){
    Print("tp1 must be grater than 0");
    bool inputsOK=false;
}

if (InpTakeProfit2Pips < 0 ){
    Print("tp2 must be grater than 0");
    bool inputsOK=false;
}

if (InpTakeProfit3Pips < 0 ){
    Print("tp3 must be grater than 0");
    bool inputsOK=false;
}

if (InpRiskPercent <= 0 ){
    Print("risk must be greater than 0");
    bool inputsOK=false;
}

if (!inputsOK) return INIT_PARAMETERS_INCORRECT;

RangeGap = PipsToDouble(InpRangeGapPips);
StopLoss = PipsToDouble(InpStopLossPips);
TakeProfit1 = PipsToDouble(InpTakeProfit1Pips);
TakeProfit2 = PipsToDouble(InpTakeProfit2Pips);
TakeProfit3 = PipsToDouble(InpTakeProfit3Pips);

// 1. find the setup for the starting time range 
datetime now = TimeCurrent(); 

EndTime= setNextTime(now+60, InpRangeEndHour, InpRangeEndMinute);
StartTime = setPrevTime(EndTime, InpRangeStartHour, InpRangeStartMinute);
InRange = (StartTime <= now && EndTime > now);


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
datetime setNextTime(datetime now, int hour, int minute){
    MqlDateTime nowStruct;
    TimeToStruct(now, nowStruct);

    nowStruct.sec = 0;
    datetime nowTime = StructToTime(nowStruct);

    nowStruct.hour = hour;
    nowStruct.min = minute;
    datetime nextTime = StructToTime(nowStruct);

    while (nextTime < nowTime || !IsTradingDay(nextTime)){
        nextTime +=86400;
    }
return nextTime;

}


datetime setPrevTime(datetime now, int hour, int minute){
    MqlDateTime nowStruct;
    TimeToStruct(now, nowStruct);

    nowStruct.sec = 0;
    datetime nowTime = StructToTime(nowStruct);

    nowStruct.hour = hour;
    nowStruct.min = minute;
    datetime prevTime = StructToTime(nowStruct);

    while (prevTime < nowTime || !IsTradingDay(prevTime)){
        prevTime -=86400;
    }
return prevTime;

}

bool IsTradingDay( datetime time){
    MqlDateTime timeStruct;
    TimeToStruct(time, timeStruct);
    datetime fromTime;
    datetime toTime;
    return SymbolInfoSessionTrade(Symbol(), (ENUM_DAY_OF_WEEK)timeStruct.day_of_week, 0, fromTime, toTime);


}

double PipsToDouble(double pips){
   return PipsToDouble(Symbol(), pips);
}

double PipsToDouble(string symbol, double pips){
    //casting change (int) change return value to an int
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    if(digits ==3 || digits == 5){
        pips =pips*10;
    }
    double value = pips * SymbolInfoDouble(symbol, SYMBOL_POINT);
    return value;
}