//+------------------------------------------------------------------+
//|                                                  BreakoutSnF.mq4 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com
//|
//|   Trading Strategy:
//|   This Expert Advisor (EA) is designed to trade the USDJPY currency pair.
//|   It follows a breakout strategy based on a 24-hour range starting at 6 PM EST.
//|   The EA enters trades 7 pips above and below the range, with 3 buy entries and
//|   3 sell entries. Each entry has a stop loss of 25 pips and take profits at
//|   15, 35, and 50 pips.
//|   Risk management aims for 1% risk per position based on stop loss, with a
//|   maximum of 3% total risk per day. The EA cancels the other side of the trade
//|   when one side is triggered.
//|
//|   MT4/MT5 CTrader files: https://www.mql5.com/en/code/39161
//+------------------------------------------------------------------+

#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#ifdef __MQL5__
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
CTrade Trade;
CPositionInfo PositionInfo;
#endif

enum ENUM_RISK_TYPE 
{
RISK_TYPE_FIXED_LOTS, //fixed lots
RISK_TYPE_EQUITY_PERCENT //equity percentage
};

//+------------------------------------------------------------------+
//| Inputs                                  |
//+------------------------------------------------------------------+
//Time range - 6pmEST
input int InpRangeStartHour = 1; // Range Start Hour
input int InpRangeStartMinute= 0; // Range Start Minute
input int InpRangeEndHour = 1; // Range End Hour
input int InpRangeEndMinute = 0; // Range End Minute

//Entry Inputs
input double InpRangeGapPips = 7.0;       // Entry gap in pips
input double InpStopLossPips = 25.0;      // Stop loss in pips
input double InpTakeProfit1Pips = 15.0;   // Take profit 1 in pips
input double InpTakeProfit2Pips = 35.0;   // Take profit 2 in pips
input double InpTakeProfit3Pips = 50.0;   // Take profit 3 in pips

// Standard Features
input long InpMagic= 232323; //Magic number
input string InpTradeComment = "Breakout Snf Strategy"; //Trade comment
input double InpRisk=1.0; //Risk Percentage per position
input ENUM_RISK_TYPE InpRiskType = RISK_TYPE_FIXED_LOTS; //default type


//+------------------------------------------------------------------+
//| Global Variables                                |
//+------------------------------------------------------------------+

double RangeGap = 0;
double StopLoss= 0;
double TakeProfit1 = 0;
double TakeProfit2 = 0;
double TakeProfit3 = 0;


datetime StartTime=0;
datetime EndTime= 0;
bool InRange = false;

double BuyEntryPrice = 0;
double SellEntryPrice = 0;

bool Target1Hit = false;


;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
    //initialize risk settings and validate inputs. 
    bool inputsOK=true;
    
// Validate range times
if (InpRangeStartHour < 0 || InpRangeStartHour > 23){
    Alert("Start hour must be from 0-23");
     inputsOK=false;
   
}

if (InpRangeStartMinute < 0 || InpRangeStartMinute > 59){
    Alert("Start hour must be from 0-59");
     inputsOK=false;
}

if (InpRangeEndHour < 0 || InpRangeEndHour > 23){
    Alert("Start hour must be from 0-23");
     inputsOK=false;
}

if (InpRangeEndMinute < 0 || InpRangeEndMinute > 59){
    Alert("Start hour must be from 0-59");
     inputsOK=false;
}

if (InpRangeGapPips <= 0 ){
    Alert("range gap must be grater than 0");
     inputsOK=false;
}

if (InpStopLossPips < 0 ){
    Alert("stop loss must be grater than 0");
     inputsOK=false;
}

if (InpTakeProfit1Pips < 0 ){
    Alert("tp1 must be grater than 0");
     inputsOK=false;
}

if (InpTakeProfit2Pips < 0 ){
    Alert("tp2 must be grater than 0");
     inputsOK=false;
}

if (InpTakeProfit3Pips < 0 ){
    Alert("tp3 must be grater than 0");
     inputsOK=false;
}

if (InpRisk <= 0 ){
    Alert("risk must be greater than 0");
     inputsOK=false;
}

if (!inputsOK) return INIT_PARAMETERS_INCORRECT;

//Calc risk settings & intialize other vairables.

RangeGap = PipsToDouble(InpRangeGapPips);
StopLoss = PipsToDouble(InpStopLossPips);
TakeProfit1 = PipsToDouble(InpTakeProfit1Pips);
TakeProfit2 = PipsToDouble(InpTakeProfit2Pips);
TakeProfit3 = PipsToDouble(InpTakeProfit3Pips);

BuyEntryPrice = 0;
SellEntryPrice = 0;

#ifdef __MQL5__
Trade.SetExpertMagicNumber(InpMagic);
#endif

// Find the setup for the starting time range 
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
  {}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
// Main trading logic that executes on every tick.

datetime now = TimeCurrent(); //get current server time
bool currentlyInRange = (StartTime<= now && now < EndTime); // check if currently inside the range

if (InRange && !currentlyInRange) {
    //perform exiting range
    SetTradeEntries();
}

if (now >= EndTime){
    //Move to the next time range
    EndTime = setNextTime(EndTime+60, InpRangeEndHour, InpRangeEndMinute);
    StartTime= setPrevTime(EndTime, InpRangeStartHour, InpRangeStartMinute);
}

InRange = currentlyInRange;

double currentPrice = 0;
if (BuyEntryPrice>0){
    //Calculate the current price for buy entry 
    currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK); //Current price is the entry price for a buy trade

    if (currentPrice >=BuyEntryPrice){
        //Open a buy trade when the price is above or equal to the entry price. 
        OpenTrade(ORDER_TYPE_BUY, currentPrice);
        BuyEntryPrice = 0;
        SellEntryPrice = 0;
    }

}

if (SellEntryPrice > 0){
    //Calculate the current price for sell entry. 
    currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID); //Current price is the entry price for a buy trade

    if (currentPrice <= SellEntryPrice){
        //Oopen a sell trade when the price is below or equal to the entry price.
        OpenTrade(ORDER_TYPE_SELL, currentPrice);
        BuyEntryPrice = 0;
        SellEntryPrice = 0;
    }

}
   
  }
//+------------------------------------------------------------------+
datetime setNextTime(datetime now, int hour, int minute){
    //Calculate the next time based on the current time, hour, minute.
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
    //Calculate the previous time based on the current time, hour, minute.
    MqlDateTime nowStruct;
    TimeToStruct(now, nowStruct);

    nowStruct.sec = 0;
    datetime nowTime = StructToTime(nowStruct);

    nowStruct.hour = hour;
    nowStruct.min = minute;
    datetime prevTime = StructToTime(nowStruct);

    while (prevTime >= nowTime || !IsTradingDay(prevTime)){
        prevTime -= 86400;
    }
return prevTime;

}

bool IsTradingDay( datetime time){

    //Check if the given time falls within a trading day.
    MqlDateTime timeStruct;
    TimeToStruct(time, timeStruct);
    datetime fromTime;
    datetime toTime;
    return SymbolInfoSessionTrade(Symbol(), (ENUM_DAY_OF_WEEK)timeStruct.day_of_week, 0, fromTime, toTime);


}

double PipsToDouble(double pips){

    //Convert pips to a double value based on the symbol's point value.
   return PipsToDouble(Symbol(), pips);
}

double PipsToDouble(string symbol, double pips){
 // Convert pips to a double value based on the symbol's point value.
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    if(digits ==3 || digits == 5){
        pips =pips*10;
    }
    double value = pips * SymbolInfoDouble(symbol, SYMBOL_POINT);
    return value;
}

void SetTradeEntries(){
  // Set buy and sell entry prices based on the highest high and lowest low within the time range.
    int startBar = iBarShift(Symbol(), Period(), StartTime, false);
    int endBar = iBarShift(Symbol(), Period(), EndTime, false)+1;
    double high = iHigh(Symbol(), Period(), iHighest(Symbol(),Period(), MODE_HIGH, startBar-endBar+1, endBar));
  double low = iLow(Symbol(), Period(), iLowest(Symbol(),Period(), MODE_LOW, startBar-endBar+1, endBar)); 
  //Save the entry prices.
  BuyEntryPrice = high + RangeGap; //7 pips above high price of the rnage
  SellEntryPrice = low - RangeGap;
  
}


void OpenTrade(ENUM_ORDER_TYPE type, double price){
    // Open a trade with the specified type, price, stop loss, and take profit levels.
    double sl = 0;
    if (type == ORDER_TYPE_BUY){
        sl= price - StopLoss; //buy
    }else {
        sl = price + StopLoss; //sell
    };
     // If opening TP1 fails, do not attempt to place other trades. 
    if(!OpenTrade(type, price, sl, TakeProfit1)) return;
    if(!OpenTrade(type, price, sl, TakeProfit2))return;
    if(!OpenTrade(type, price, sl, TakeProfit3)) return;

}

//set trade size based on equity or risk


bool OpenTrade(ENUM_ORDER_TYPE type, double price, double sl , double takeProfit){
    // Open a trade with the specified type, price, stop loss, and take profit levels.
    if (takeProfit == 0) return true;


    double tp = 0;

    if (type== ORDER_TYPE_BUY){
        tp=price + takeProfit; //buy
    }else{
        tp= price-takeProfit; //sell
    }

    int digits  = (int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS);
    price = NormalizeDouble(price, digits);

    sl= NormalizeDouble(sl,digits);
    tp= NormalizeDouble(tp, digits);

     double volume = 0;
     if (InpRiskType == RISK_TYPE_EQUITY_PERCENT){
        volume = GetRiskVolume(Risk, MathAbs(price-sl));
     } else {
        volume = InpRisk;
     }


    //Place a trade MT4
    #ifdef __MQL4__
    int ticket = OrderSend(Symbol(), type, volume, price, 0, sl, tp, InpTradeComment, (int)InpMagic);
    //if order send fails ticket will = 0
    if (ticket <= 0){
         PrintFormat("Error opening trade, type=%s, volume=%f, price=%f, sl=%f, tp=%f", EnumToString(type), volume, price, sl, tp);
         return false;
    }
    #endif
 // Place a trade in MT5.
    #ifdef __MQL5__
   if (!Trade.PositionOpen(Symbol(), type, volume, price, sl, tp, InpTradeComment )){
    PrintFormat("Error opening trade, type=%s, volume=%f, price=%f, sl=%f, tp=%f", EnumToString(type), volume, price, sl, tp);
    return false;
   };
   #endif

   return true;

}

double GetRiskVolume(double risk, double loss){

    // Calculate trade volume based on equity and risk percentage.

    double equity = AccountInfoDouble(ACCOUNT_EQUITY); //calc equity
    double riskAmount = equity*risk; //amount i want to risk 

    double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE); //smallest movement price can have 
    double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    double lossTicks= loss/ tickSize; // calc # of ticks I am prepared to lose

    double volume = riskAmount / (lossTicks*tickValue); // tot. loss of a single lot size
    volume = NormalizeVolume(volume);

    return volume;

}

double NormalizeVolume(double volume){

     // Normalize the trade volume to match symbol constraints.
    if (volume <= 0) return 0; // nothing to do here
    double max = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); //max # of lots allowed to trade
    double min = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); //min # of lots allowed to trade
    double step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP); //increment between lot sizes

    double result = MathRound(volume/step)*step; //round volume to nearest int value -> rounding volume based on the result of the step
    if (result>max) result = max;
    if (result<min) result = min; // might want to change to 0 later on 

    return result; 
}

void MoveSLToBreakEven(int ticket, double price, double sl, double tp, int digits){
    if (type == ORDER_TYPE_BUY && takeProfit == TakeProfit1 && Target1Hit) {
        // Modify stop loss to break even
        double newSL = price;
        newSL = NormalizeDouble(newSL, digits);

        // Modify the stop loss for the trade
        if (!Trade.PositionModify(ticket, price, newSL, tp)) {
            Print("Error modifying stop loss to break even: ", GetLastError());
        }
    }

}
