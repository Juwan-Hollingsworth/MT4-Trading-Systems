//+------------------------------------------------------------------+
//|                                                    MA_YT_TUT.mq4 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict


enum ENUM_RISK_TYPE 
{
RISK_TYPE_FIXED_LOTS, //fixed lots
RISK_TYPE_EQUITY_PERCENT //equity percentage
};

enum ENUM_POSITION_TYPE 
{
POSITION_TYPE_BUY= ORDER_TYPE_BUY,
POSITION_TYPE_SELL= ORDER_TYPE_SELL,
};

struct STradeData{
long ticket;
double priceOpen;
double takeProfit;

STradeData(){
    ticket=0;
    priceOpen=0;
    takeProfit=0;
}

void Init(){
    ticket=PositionTicket();
    priceOpen=PositionPriceOpen();
    takeProfit=PositionTakeProfit();
}
};

struct SGroupData{
datetime time;
STradeData trades[3];

SGroupData(){
    time=0;
}

};

//+------------------------------------------------------------------+
//| Inputs                                 |
//+------------------------------------------------------------------+

input int periodA= 20; //fast ema
input int periodB= 50; //fast ema



// Standard Features
input long InpMagic= 232323; //Magic number
input string InpTradeComment = "YT_TUT"; //Trade comment
input double InpRisk=1.0; //Risk Percentage per position

//Entry Inputs
input double InpStopLossPips = 25.0;      // Stop loss in pips
input double InpTakeProfit1Pips = 15.0;   // Take profit 1 in pips
input double InpTakeProfit2Pips = 35.0;   // Take profit 2 in pips
input double InpTakeProfit3Pips = 50.0;   // Take profit 3 in pips
input ENUM_RISK_TYPE InpRiskType = RISK_TYPE_FIXED_LOTS; //default type

 double SL = Bid-750*Point; //Define stop loss
 double TP = Ask+2250*Point;  // define TP
 double SL_sell = Ask+750*SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
 double TP_sell = Bid-2250*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
 
 
//Management
input bool InpUseBreakEven = false; // Move to break even on first TP?


//+------------------------------------------------------------------+
//| Global Variables                                |
//+------------------------------------------------------------------+

double RangeGap = 0;
double StopLoss= 0;
double TakeProfit1 = 0;
double TakeProfit2 = 0;
double TakeProfit3 = 0;

int PositionCount = 0;

long Magic1 =0;
long Magic2 =0;
long Magic3 =0;


double BuyEntryPrice = 0;
double SellEntryPrice = 0;

double currentPrice = 0;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

//Calc risk settings & intialize other vairables.
StopLoss = PipsToDouble(InpStopLossPips);
TakeProfit1 = PipsToDouble(InpTakeProfit1Pips);
TakeProfit2 = PipsToDouble(InpTakeProfit2Pips);
TakeProfit3 = PipsToDouble(InpTakeProfit3Pips);

BuyEntryPrice = 0;
SellEntryPrice = 0;

Magic1 = InpMagic;
Magic2 = InpMagic+1;
Magic3 = InpMagic+1;

//in case a trade closed while shut down
PositionCount=0;
UpdateBreakEven();


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
  // Check if there are any open positions
   if (PositionCount != PositionsTotal()){
          UpdateBreakEven();

    };
//---

string signal="";
//Calculate a simple moving average for 20 candles 
double MA_1=iMA(Symbol(),_Period,periodA,0,MODE_SMA,PRICE_CLOSE,0);
double Last_MA_1=iMA(Symbol(),_Period,periodA,0,MODE_SMA,PRICE_CLOSE,1);
//Calculate a simple moving average for 50 candles 
double MA_2=iMA(Symbol(),_Period,periodB,0,MODE_SMA,PRICE_CLOSE,0);
double Last_MA_2=iMA(Symbol(),_Period,periodB,0,MODE_SMA,PRICE_CLOSE,1);


//+------------------------------------------------------------------+
//| Exexcution Logic                                                 |
//+------------------------------------------------------------------+

// [BUY]- When the 20 crosses above the 50 ema 
if((Last_MA_1<Last_MA_2)&&(MA_1>MA_2))
{
//Calculate the current price for buy entry 
    currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK); 
     OpenTrade(ORDER_TYPE_BUY, currentPrice);
        BuyEntryPrice = 0;
        SellEntryPrice = 0;
        
        // Update PositionCount
    PositionCount++;
        
        // Sleep for 5 minutes (300 seconds)
            Sleep(300000);
  

}
//[SELL]- When the 50 crosses above the 20 ema 
if((Last_MA_1>Last_MA_2)&&(MA_1<MA_2))
{
currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID); 
  //Open a sell trade when the price is below or equal to the entry price.
        OpenTrade(ORDER_TYPE_SELL, currentPrice);
        BuyEntryPrice = 0;
        SellEntryPrice = 0;
        
        // Update PositionCount
    PositionCount++;
        
        // Sleep for 5 minutes (300 seconds)
            Sleep(300000);
};

  }
//+------------------------------------------------------------------+
// functions
//+------------------------------------------------------------------+
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

void UpdateBreakEven(){
    if (!InpUseBreakEven) return;

    SGroupData groupList[];
    int groupCount = LoadGroupData(groupList);

    for (int i = groupCount -1;i>=0;i--){
        if(groupList[i].trades[0].ticket>0)continue;
        if(groupList[i].trades[0].ticket>0)SetBreakEven(groupList[i].trades[1]);
        if(groupList[i].trades[0].ticket>0)SetBreakEven(groupList[i].trades[1]);
    }

    PositionCount=PositionsTotal();
};

void SetBreakEven(STradeData &trade){
    bool success = OrderModify(trade.ticket, trade.priceOpen, trade.priceOpen, trade.takeProfit,0);
}

int LoadGroupData (SGroupData &groupList[]){
    int groupCount=0;
    ArrayResize(groupList, 0);
    for (int i=PositionsTotal()-1;i>=0;i--){
        if (!PositionSelectByIndex(i)) continue;
        if(PositionStopLoss() == PositionPriceOpen()) continue; //already @ breakeven

        int index = -1;
        datetime timeOpen = PositionTimeOpen();
        for(int j=0;j<groupCount; j++){
            if(MathAbs(timeOpen-groupList[j].time) < 300){
                index=j;
                break;
            }
        }

        //if nothing found add one to the end
        if(index<0){
            index = groupCount;
            groupCount++;
            ArrayResize(groupList, groupCount);
            groupList[index].time=timeOpen;
        }

        if (PositionMagic() == Magic1) groupList[index].trades[0].Init();
        if (PositionMagic() == Magic2) groupList[index].trades[1].Init();
        if (PositionMagic() == Magic3) groupList[index].trades[2].Init();

    }

    return groupCount;
}

bool PositionSelectByIndex(int index){

    if (!OrderSelect(index, SELECT_BY_POS, MODE_TRADES)) return false;
    if (OrderSymbol() !=Symbol()) return false;
    if (OrderMagicNumber()!=Magic1&& OrderMagicNumber() !=Magic2 && OrderMagicNumber() !=Magic3) return false;
    if (OrderType() != ORDER_TYPE_BUY && OrderType() !=ORDER_TYPE_SELL) return false;
    return true;



}

//set trade size based on equity or risk
void OpenTrade(ENUM_ORDER_TYPE type, double price){
    // Open a trade with the specified type, price, stop loss, and take profit levels.
    double sl = 0;
    if (type == ORDER_TYPE_BUY){
        sl= price - StopLoss; //buy
    }else {
        sl = price + StopLoss; //sell
    };
     // If opening TP1 fails, do not attempt to place other trades. 
    if(!OpenTrade(type, price, sl, TakeProfit1, Magic1)) return;
    if(!OpenTrade(type, price, sl, TakeProfit2, Magic2))return;
    if(!OpenTrade(type, price, sl, TakeProfit3, Magic3)) return;

}

bool OpenTrade(ENUM_ORDER_TYPE type, double price, double sl , double takeProfit, long magic){
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
        volume = GetRiskVolume(InpRisk/100, MathAbs(price-sl));
     } else {
        volume = InpRisk;
     };


    //Place a trade MT4
    #ifdef __MQL4__
    int ticket = OrderSend(Symbol(), type, volume, price, 0, sl, tp, InpTradeComment, (int)magic);
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

      msg = "Auto-Bot has started 🚀 ";

       msg = "🔔 Ka-Ching! Sell Trade Placed 🔔 ";
       msg += "📈 Order executed @: ";
        msg += "📈"
         msg += "💹 2MA-CSR-NAS100-5MIN 💹";
}

msg += "The 2MA-CSR BOT has started 🤓 ";
 msg += "Bot has ended 😔 ";

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




//mt4 specific
int      PositionsTotal() { return OrdersTotal(); }
double   PositionStopLoss() { return OrderStopLoss(); }
double   PositionPriceOpen() { return OrderOpenPrice(); }
int      PositionTicket() { return OrderTicket(); }
datetime PositionTimeOpen() { return OrderOpenTime(); }
double   PositionTakeProfit() { return OrderTakeProfit(); }
int      PositionType() { return OrderType(); }
long     PositionMagic() { return OrderMagicNumber(); }

