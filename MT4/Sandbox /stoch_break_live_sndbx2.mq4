/*Strategy: MACD_ADX.mq4*/
//Last modified 4/24/22
#property strict
const string TelegramBotToken = "5729595430:AAFM4onuWbbNYw6UlO1ZSsYhYcAxKVK7od8";
const string ChatId           = "-1001951546595";
const string TelegramApiUrl   = "https://api.telegram.org";
const int    UrlDefinedError  = 4066; 
#define EMOJI_TOP    "\xF51D";
#define EMOJI_DELIGHTED "\xF60A";

#ifdef __MQL5__
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
CTrade Trade;
CPositionInfo PositionInfo;
#endif

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
input double InpRiskPercent=1.0; //Risk Percentage per position


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

double BuyEntryPrice = 0;
double SellEntryPrice = 0;

string msg = "";

double lastSentEntryPrice = 0.0;


int TradeCounter = 0;
double TradePrices[3];
double TakeProfits[3];
double TradeStops[3];



int OnInit()
  {

   
   string msg = "Bot has started :) ";
   SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) ); 
  
   
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

if (InpRiskPercent <= 0 ){
    Alert("risk must be greater than 0");
     inputsOK=false;
}

if (!inputsOK) return INIT_PARAMETERS_INCORRECT;

//Calc risk settings & intialize other vairables.
Risk           = InpRiskPercent / 100;
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
  {

    string msg = "Bot has ended ";
    SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) );
  }
  
  
  //--------------------
  
  bool SendTelegramMessage( string url, string token, string chat, string text) {

   string headers    = "";
   string requestUrl = "";
   char   postData[];
   char   resultData[];
   string resultHeaders;
   int    timeout = 5000; 
   
   requestUrl = StringFormat( "%s/bot%s/sendmessage?chat_id=%s&text=%s", url, token, chat, text, "&parse_mode=HTML" );
   int response = WebRequest( "POST", requestUrl, headers, timeout, postData, resultData, resultHeaders );
   ResetLastError();
   switch ( response ) {
   case -1: {
      int errorCode = GetLastError();
      Print( "Error in WebRequest. Error code  =", errorCode );
      if ( errorCode == UrlDefinedError ) {
         
         PrintFormat( "Add the address '%s' in the list of allowed URLs", url );
      }
      break;
   }
   case 200:
     
      Print( "The message has been successfully sent" );
      break;
   default: {
      string result = CharArrayToString( resultData );
      PrintFormat( "Unexpected Response '%i', '%s'", response, result );
      break;
   }
   }

   return ( response == 200 );
}

bool SendTelegramMessage_alert( string url, string token, string chat, string text) {

   string headers    = "";
   string requestUrl = "";
   char   postData[];
   char   resultData[];
   string resultHeaders;
   int    timeout = 5000;
   
   requestUrl = StringFormat( "%s/bot%s/sendmessage?chat_id=%s&text=%s", url, token, chat, text, "&parse_mode=HTML" );
   int response = WebRequest( "POST", requestUrl, headers, timeout, postData, resultData, resultHeaders );
   ResetLastError();
   switch ( response ) {
   case -1: {
      int errorCode = GetLastError();
      Print( "Error in WebRequest. Error code  =", errorCode );
      if ( errorCode == UrlDefinedError ) {
        
         PrintFormat( "Add the address '%s' in the list of allowed URLs", url );
      }
      break;
   }
   case 200:
     
      Print( "The message has been successfully sent" );
       Sleep(300000);
      break;
   default: {
      string result = CharArrayToString( resultData );
      PrintFormat( "Unexpected Response '%i', '%s'", response, result );
      break;
   }
   }

   return ( response == 200 );
}

bool GetPostData( char &postData[], string &headers, string chat, string text, string fileName ) {

   ResetLastError();

   if ( !FileIsExist( fileName ) ) {
      PrintFormat( "File '%s' does not exist", fileName );
      return ( false );
   }

   int flags = FILE_READ | FILE_BIN;
   int file  = FileOpen( fileName, flags );
   if ( file == INVALID_HANDLE ) {
      int err = GetLastError();
      PrintFormat( "Could not open file '%s', error=%i", fileName, err );
      return ( false );
   }

   int   fileSize = ( int )FileSize( file );
   uchar photo[];
   ArrayResize( photo, fileSize );
   FileReadArray( file, photo, 0, fileSize );
   FileClose( file );

   string hash = "";
   AddPostData( postData, hash, "chat_id", chat );
   if ( StringLen( text ) > 0 ) {
      AddPostData( postData, hash, "caption", text );
   }
   AddPostData( postData, hash, "photo", photo, fileName );
   ArrayCopy( postData, "--" + hash + "--\r\n" );

   headers = "Content-Type: multipart/form-data; boundary=" + hash + "\r\n";

   return ( true );
}

void AddPostData( uchar &data[], string &hash, string key = "", string value = "" ) {

   uchar valueArr[];
   StringToCharArray( value, valueArr, 0, StringLen( value ) );

   AddPostData( data, hash, key, valueArr );
   return;
}

void AddPostData( uchar &data[], string &hash, string key, uchar &value[], string fileName = "" ) {

   if ( hash == "" ) {
      hash = Hash();
   }

   ArrayCopy( data, "\r\n" );
   ArrayCopy( data, "--" + hash + "\r\n" );
   if ( fileName == "" ) {
      ArrayCopy( data, "Content-Disposition: form-data; name=\"" + key + "\"\r\n" );
   }
   else {
      ArrayCopy( data, "Content-Disposition: form-data; name=\"" + key + "\"; filename=\"" +
                          fileName + "\"\r\n" );
   }
   ArrayCopy( data, "\r\n" );
   ArrayCopy( data, value, ArraySize( data ) );
   ArrayCopy( data, "\r\n" );

   return;
}

void ArrayCopy( uchar &dst[], string src ) {

   uchar srcArray[];
   StringToCharArray( src, srcArray, 0, StringLen( src ) );
   ArrayCopy( dst, srcArray, ArraySize( dst ), 0, ArraySize( srcArray ) );
   return;
}

string Hash() {

   uchar  tmp[];
   string seed = IntegerToString( TimeCurrent() );
   int    len  = StringToCharArray( seed, tmp, 0, StringLen( seed ) );
   string hash = "";
   for ( int i = 0; i < len; i++ )
      hash += StringFormat( "%02X", tmp[i] );
   hash = StringSubstr( hash, 0, 16 );

   return ( hash );
   
}
  


void OnTick()
  {
 
       //define the stoch EA
double K0 = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,0,MODE_MAIN,0);
double D0 = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);
double K1 = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,0,MODE_MAIN,1);
double D1 = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,0,MODE_SIGNAL,1);

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
    
    if((K0 < 20)&&(D0 < 20)) 
if((D0<K0)&&(D1 > K1)&& currentPrice >=BuyEntryPrice ){
        //Open a buy trade when the price is above or equal to the entry price. 
        OpenTrade(ORDER_TYPE_BUY, currentPrice);
        BuyEntryPrice = 0;
        SellEntryPrice = 0;
    }

}

if (SellEntryPrice > 0){
    //Calculate the current price for sell entry. 
    currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID); //Current price is the entry price for a buy trade
if((K0 > 80)&&(D0 >80)) 
if((D0>K0)&&(D1 < K1)&& currentPrice <= SellEntryPrice ){
        //Oopen a sell trade when the price is below or equal to the entry price.
        OpenTrade(ORDER_TYPE_SELL, currentPrice);
        BuyEntryPrice = 0;
        SellEntryPrice = 0;
    }

}

}


//+------------------------------------------------------------------+

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
    int startBar = iBarShift(Symbol(), PERIOD_M1, StartTime, false);
    int endBar = iBarShift(Symbol(), PERIOD_M1, EndTime-60, false);
    double high = iHigh(Symbol(), PERIOD_M1, iHighest(Symbol(),PERIOD_M1, MODE_HIGH, startBar-endBar+1, endBar));
  double low = iLow(Symbol(), PERIOD_M1, iLowest(Symbol(),PERIOD_M1, MODE_LOW, startBar-endBar+1, endBar)); 
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

     // Calculate trade volume based on risk.
    double volume = GetRiskVolume(Risk, MathAbs(price-sl));

    //Place a trade MT4
    #ifdef __MQL4__
    int ticket = OrderSend(Symbol(), type, volume, price, 0, sl, tp, InpTradeComment, (int)InpMagic);
    //if order send fails ticket will = 0
    if (ticket <= 0){
         PrintFormat("Error opening trade, type=%s, volume=%f, price=%f, sl=%f, tp=%f", EnumToString(type), volume, price, sl, tp);
         return false;
    }
    
    // Increment the trade counter and store trade details
    TradeCounter++;
    TradePrices[TradeCounter - 1] = price;
    TakeProfits[TradeCounter - 1] = price+takeProfit;
    TradeStops[TradeCounter - 1] = sl;
    
    // Check if the counter has reached 3, and if so, send a Telegram message
    if (TradeCounter == 3) {
        SendTradeDetailsToTelegram();
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

void SendTradeDetailsToTelegram() {
    string message = "Alert! Trade Placed:\n";
    double lastPrice = 0; // Variable to track the last price
    string tradeType = ""; // Variable to track the trade type
    double stopLossValue = 0; // Variable to track the stop loss value

    for (int i = 0; i < 3; i++) {
        double price = TradePrices[i];
        double takeProfit = TakeProfits[i];
        double stopLoss = TradeStops[i];

        // Check if the current price is the same as the last one
        if (price != lastPrice) {
            // If trade type is not empty, add it to the message
            if (StringLen(tradeType) > 0) {
                message += tradeType + "Stop Loss: " + DoubleToStr(stopLossValue, 2) + "\n";
                tradeType = "";
                stopLossValue = 0;
            }
            message +=  "Executed @ Price: " + DoubleToStr(price, 2) + "\n";
            lastPrice = price; // Update the last price
        }

        // Set trade type and stop loss only once
        if (StringLen(tradeType) == 0) {
            tradeType = (price > 0) ? "Buy" : "Sell";
            stopLossValue = stopLoss;
        }

        message += "Take Profit" + IntegerToString(i + 1) + ": " + DoubleToStr(takeProfit, 2) + "\n";
    }

    // Check if there are trade details remaining to be added
    if (StringLen(tradeType) > 0) {
        message += "Order Type: "+ tradeType + "\n" +"Stop Loss: " + DoubleToStr(stopLossValue, 2) + "\n";
    }

    // Reset the counter and clear the trade details
    TradeCounter = 0;
    ArrayInitialize(TradePrices, 0);
    ArrayInitialize(TakeProfits, 0);

    SendTelegramMessage(TelegramApiUrl, TelegramBotToken, ChatId, message);
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




