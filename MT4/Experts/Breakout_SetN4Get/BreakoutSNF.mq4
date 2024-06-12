/*
//|                                                  BreakoutSNF.mq4 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |

   Strategy YT: 
   Asset: USDJPY
   Rules: 
   Find a 24 hour high and low range based on 6pmEST
   Entries are at 7 pips above and below the range
   3 entries above and 3 entries below
   Each entry has sl 25pip
   Seperate tp for each entry 15,35, 50 pips
   
   risk 1% per position - will be based on 25pips sl
   roral 3% risk per day 
   Assumed using equity to risk 
   
   Not in OG strategy:
   wne one entry is hit cancel the opposing trade
   if entry is not hit on day then cancel and clear
   
   Optional 
   When one profit is hit move the sl to break even 


*/

#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Inputs                                  |
//+------------------------------------------------------------------+
//Time range inputs
input int InpRangeStartHour = 1; // Range Start Hour
input int InpRangeStartMinute=0;  // Range Start Min
input int InpRangeEndHour = 1;  // Range End Hour
input int InpRangeEndMinute = 1; // Range End Min

//Entry inputs
input double InpRangeGapPips = 7.0; // Entry gap from range
input double InpStopLossPips = 25.0; // SL pips
input double InpTakeProfit1Pips = 15.0; // TP 1
input double InpTakeProfit2Pips = 35.0; // TP 2
input double InpTakeProfit3Pips = 50.0; // TP 3

//Management
input long InpMagic = 123456; // Magic #
input string InpTradeComment = "SNF Breakout"; // Trade comment
input double InpRiskPercent = 1.0; //Risk percent

//+------------------------------------------------------------------+
//| Global variables                                 |
//+------------------------------------------------------------------+
double RangeGap = 0;
double StopLoss = 0;
double TakeProfit1 = 0;
double TakeProfit2 = 0;
double TakeProfit3 = 0;
double Risk = 0;


datetime StartTime = 0;
datetime EndTime = 0;
bool InRange = false;

double BuyEntryPrice =0;
double SellEntryPrice = 0;

int MagicNumber = 0;  // Variable to store the current magic number

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

 
   // conditional for verification
   bool inputsOK = true;

   //Validate range time 
   if(InpRangeStartHour < 0 || InpRangeStartHour >23 ) {
   Print("Starthour must be from 0-23");
  inputsOK = false;
   }
     if(InpRangeStartMinute < 0 || InpRangeStartMinute >59 ) {
   Print("Starthour must be from 0-23");
   inputsOK = false;
   }
     if(InpRangeEndHour < 0 || InpRangeEndHour >23 ) {
   Print("Starthour must be from 0-23");
   inputsOK = false;
   }
     if(InpRangeEndMinute < 0 || InpRangeEndMinute >59 ) {
   Print("Starthour must be from 0-23");
  inputsOK = false;
   }
   
   //Validate range gap, sl 
    if(InpRangeGapPips < 0 ) {
   Print("Range gap must be in the range 0-59");
    inputsOK = false;
   }
   
   if(InpStopLossPips < 0 ) {
   Print("Range gap must be >= 0");
    inputsOK = false;
   }
   
   if(InpTakeProfit1Pips< 0 ) {
   Print("TP must be >= 0");
   inputsOK = false;
   }
    if(InpTakeProfit2Pips< 0 ) {
   Print("TP must be >= 0");
   inputsOK = false;
   }
    if(InpTakeProfit3Pips< 0 ) {
   Print("TP must be >= 0");
   inputsOK = false;
   }
    if(InpRiskPercent <= 0 ) {
   Print("Risk must be > 0");
   inputsOK = false;
   }
   
   if(!inputsOK) return INIT_PARAMETERS_INCORRECT;
   
   Risk = InpRiskPercent/100;
   
   RangeGap = PipsToDouble(InpRangeGapPips);
   StopLoss = PipsToDouble(InpStopLossPips);
   TakeProfit1 = PipsToDouble(InpTakeProfit1Pips);
   TakeProfit2 = PipsToDouble(InpTakeProfit2Pips);
   TakeProfit3 = PipsToDouble(InpTakeProfit3Pips);
   BuyEntryPrice = 0;
   SellEntryPrice = 0;
       
   //Find the setup for the starting time range
   datetime now = TimeCurrent();
   EndTime = SetNextTime(now+60, InpRangeEndHour, InpRangeEndMinute);
   StartTime = SetPrevTime(EndTime, InpRangeStartHour, InpRangeStartMinute);
   InRange = (StartTime <= now && EndTime > now);
   
   // Set the initial magic number
   MagicNumber = (int)InpMagic;
   
   
   
   
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){

   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Determine if we are in the specified time range
    datetime now = TimeCurrent(); // Get current time
    bool currentlyInRange = (StartTime <= now && now < EndTime);

    // Check to see if range is exited
    // Global variable defaults to false
    if (InRange && !currentlyInRange) {
        SetTradeEntries();
    }

    // If passed the Endtime, move the range forward
    if (now >= EndTime) {
        EndTime = SetNextTime(EndTime + 60, InpRangeEndHour, InpRangeEndMinute);
        StartTime = SetPrevTime(EndTime, InpRangeStartHour, InpRangeStartMinute);
    }

    InRange = currentlyInRange;

    /* Trade conditions */
    double currentPrice = 0;
    // If buy entry price is greater than zero, has it reached the entry?
    if (BuyEntryPrice > 0) {
        currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        // Place buy order at current price
        if (currentPrice >= BuyEntryPrice) {
            OpenTrade(ORDER_TYPE_BUY, currentPrice, TakeProfit1);
            OpenTrade(ORDER_TYPE_BUY, currentPrice, TakeProfit2);
            OpenTrade(ORDER_TYPE_BUY, currentPrice, TakeProfit3);
            BuyEntryPrice = 0;
            SellEntryPrice = 0;
        }
    }

    if (SellEntryPrice > 0) {
        currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);

        if (currentPrice <= BuyEntryPrice) {
            OpenTrade(ORDER_TYPE_SELL, currentPrice, TakeProfit1);
            OpenTrade(ORDER_TYPE_SELL, currentPrice, TakeProfit2);
            OpenTrade(ORDER_TYPE_SELL, currentPrice, TakeProfit3);
            BuyEntryPrice = 0;
            SellEntryPrice = 0;
        }
    }
}


//
datetime SetNextTime(datetime now, int hour, int minute){

   MqlDateTime nowStruct;
   TimeToStruct(now, nowStruct);
   
   nowStruct.sec = 0;
   datetime nowTime = StructToTime(nowStruct);
   
   nowStruct.hour = hour;
   nowStruct.min = minute;
   datetime nextTime = StructToTime(nowStruct);
   
   while (nextTime <nowTime || !IsTradingDay(nextTime)){
   
   nextTime += 86400;
   }
   
   return nextTime;
   
  }
  
  datetime SetPrevTime(datetime now, int hour, int minute){

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
  
  //check if a session exist for current day if not condition is false
  bool IsTradingDay(datetime time){
  MqlDateTime timeStruct;
  TimeToStruct(time, timeStruct);
  datetime fromTime;
  datetime toTime;
  return SymbolInfoSessionTrade(Symbol(),(ENUM_DAY_OF_WEEK)timeStruct.day_of_week,0,fromTime, toTime);
  }
  
  double PipsToDouble(double pips){
    return PipsToDouble(Symbol(), pips);
    }
  
  double PipsToDouble( string symbol, double pips){
  int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
  if (digits == 3 || digits ==5) {
  pips = pips*10;
  }
  double value = pips*SymbolInfoDouble(symbol, SYMBOL_POINT);
  return value;
  }

  void SetTradeEntries(){
       // get bar # for the start and end of time range 
    int startBar = iBarShift(Symbol(), PERIOD_M1, StartTime,false);
    int endBar = iBarShift(Symbol(), PERIOD_M1, EndTime-60,false);

    //get the high and low price
    double high = iHigh(Symbol(), PERIOD_M1, iHighest(Symbol(),PERIOD_M1, MODE_HIGH,startBar-endBar+1, endBar) );
    double low = iLow(Symbol(), PERIOD_M1, iLowest(Symbol(),PERIOD_M1, MODE_LOW,startBar-endBar+1, endBar) );

    //save entry prices
    BuyEntryPrice = high + RangeGap;
    SellEntryPrice = low - RangeGap;
  }

  void OpenTrade(ENUM_ORDER_TYPE type, double price){

    double sl = 0;

    if (type==ORDER_TYPE_BUY){
      sl= price - StopLoss;
    }else {
      sl = price + StopLoss;
    }

   OpenTrade(type, price, sl, TakeProfit1);
   OpenTrade(type, price, sl, TakeProfit2);
   OpenTrade(type, price, sl, TakeProfit3);

    

  }

  bool OpenTrade(ENUM_ORDER_TYPE type, double price, double takeprofit){

    double tp=0;
    double sl;
    
    if (type ==ORDER_TYPE_BUY){
      tp= price+takeprofit;
    }else {
      tp=price - takeprofit;
    }
    int digits= (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
    price = NormalizeDouble(price, digits);
    sl = NormalizeDouble(sl, digits);
    tp = NormalizeDouble(tp, digits);

    double volume = 0.01;
    
    //trade logic here
    
    return true;
 
    
    
  }
 //+------------------------------------------------------------------+ 