/*Strategy: MACD_ADX.mq4*/
//Last modified 4/24/22
#property strict
const string TelegramBotToken = "5729595430:AAFM4onuWbbNYw6UlO1ZSsYhYcAxKVK7od8";
const string ChatId           = "-1001951546595";
const string TelegramApiUrl   = "https://api.telegram.org";
const int    UrlDefinedError  = 4066; 
#define EMOJI_TOP    "\xF51D";
#define EMOJI_DELIGHTED "\xF60A";


/* Time range settings -- Set allowable trading hours  */
// 10am NYC Start operation hour
input int startHour = 14; // Start hour 
// 2PM NYC Last operation hour
input int  lastHour = 18; // End hour  

bool CheckActiveHours()
{
   // Disable trading operations by default. 
   bool OperationsAllowed = false;
   // Check if the current hour is between the allowed hours of operations. If so, return true.
   if ((startHour == lastHour) && (Hour() == startHour))
      OperationsAllowed = true;
   if ((startHour < lastHour) && (Hour() >= startHour) && (Hour() <= lastHour))
      OperationsAllowed = true;
   if ((startHour > lastHour) && (((Hour() >= lastHour) && (Hour() <= 23)) || ((Hour() <= startHour) && (Hour() > 0))))
      OperationsAllowed = true;
   
   return OperationsAllowed;
}

//+------------------------------------------------------------------+
//| Inputs                                         |
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| Global Variables                                |
//+------------------------------------------------------------------+

double StopLoss= 0;
double TakeProfit= 0;
double BuyEntryPrice = 0;
double SellEntryPrice = 0;
string msg = "";



int OnInit()
  {

   
   string msg = "Bot has started 🙂 ";
   SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) ); 
  

   return(INIT_SUCCEEDED);
   
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

    string msg = "Bot has ended 😔 ";
    SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) );
  }
  
  
//+------------------------------------------------------------------+
//  Telegram FX
//+------------------------------------------------------------------+

  
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

void SendTradeDetailsToTelegram() {
    string message = "Siberian Brisket Bot 🏧\n";
    message += "--------------------\n"; 
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
             message += "--------------------\n"; 
                tradeType = "";
                stopLossValue = 0;
            }
            message += " Executed @ Price: " + DoubleToStr(price, 2) + "\n";
             message += "--------------------\n"; 
            lastPrice = price; // Update the last price
        }

        // Set trade type and stop loss only once
        if (StringLen(tradeType) == 0) {
            tradeType = (price > 0) ? "Buy" : "Sell";
            stopLossValue = stopLoss;
        }
        

        message += "TP:" + IntegerToString(i + 1) + ": " + DoubleToStr(takeProfit, 2) + "\n";
    }

    // Check if there are trade details remaining to be added
     message += "--------------------\n"; 
    if (StringLen(tradeType) > 0) {
        message += "Order Type: "+ tradeType + "\n" +"Stop Loss: " + DoubleToStr(stopLossValue, 2) + "\n";
    }
     message += "--------------------\n"; 
      message += "[Sto-Break v1]\n";
       message += "[UJ-TF5m]\n"; 
      message += "--------------------\n"; 
       message += "--------------------\n"; 

    // Reset the counter and clear the trade details
    TradeCounter = 0;
    ArrayInitialize(TradePrices, 0);
    ArrayInitialize(TakeProfits, 0);

    SendTelegramMessage(TelegramApiUrl, TelegramBotToken, ChatId, message);
}
  


void OnTick()
  {


 /* AutoTrade settings*/
 double lotSize = 0.01; 
 double SL = Bid-750*Point; 
 double TP = Ask+2250*Point;  
 double SL_sell = Ask+750*Point; 
 double TP_sell = Bid-2250*Point;

string signal = "";

/*Indicators*/
//ADX
double adx = iADX(_Symbol,_Period,14,PRICE_CLOSE,0,0);
double lastadx = iADX(_Symbol,_Period,14,PRICE_CLOSE,0,1);
//MACD
double macd = iMACD(_Symbol,_Period,12,26,9,PRICE_CLOSE,MODE_MAIN,0);

/*Conditions*/
if (adx>lastadx)
{
if(macd<0)  
  {
   signal = "buy";
  }
}

if (adx<lastadx)
{
if(macd>0)  
  {
   signal = "sell";
  }
}

 /*Order-Execution*/
if(signal == "buy" && OrdersTotal()==0 && CheckActiveHours() == true)
  {
  OrderSend(_Symbol,OP_BUY,lotSize,Ask,3,SL,TP,"Buy Taken",0,0,Red);
  string msg = "[Buy order executed @] ";
   msg += DoubleToStr(Ask, _Digits);
   msg += " [SL:] ";
   msg += DoubleToStr(SL, _Digits);
   msg += " [TP:] ";
   msg += DoubleToStr(TP, _Digits);
   SendTelegramMessage_alert( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) ); 
   
  }
  
if(signal == "sell" && OrdersTotal()==0 && CheckActiveHours() == true)
  {
   OrderSend(_Symbol,OP_SELL,lotSize,Bid,3,SL_sell,TP_sell,"Sell Taken",0,0,Red);
  string msg = "[Sell order executed @] ";
    msg += DoubleToStr(Bid, _Digits);
    msg += " [SL:] ";
    msg += DoubleToStr(SL_sell, _Digits);
    msg += " [TP:] ";
    msg += DoubleToStr(TP_sell, _Digits);
   SendTelegramMessage_alert( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) ); 
  }
 

}


//+------------------------------------------------------------------+
//  FUNCTIONS
//+------------------------------------------------------------------+

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








