/*
Strategy: 2MA Crossover
Version: 3.0
*/
//Last modified 4/24/22
#property strict
const string TelegramBotToken = "5729595430:AAFM4onuWbbNYw6UlO1ZSsYhYcAxKVK7od8";
const string ChatId           = "-1001951546595";
const string TelegramApiUrl   = "https://api.telegram.org";
const int    UrlDefinedError  = 4066; 
#define EMOJI_TOP    "\xF51D";
#define EMOJI_DELIGHTED "\xF60A";

//+------------------------------------------------------------------+
//| Notes                                    |
//+------------------------------------------------------------------+

/*
1. Add balance to every order placed 
2. Add updated balance to every closed order
3. Send closed orders to Telegram

*/

//+------------------------------------------------------------------+
//| Time Management                                      |
//+------------------------------------------------------------------+
/* Set allowable trading hours */
// 10am NYC Start operation hour
input int StartHour = 14; // Start hour 
// 2PM NYC Last operation hour
input int  LastHour = 18; // End hour  

/* Time check logic */
bool CheckActiveHours()
{
   // Set operations disabled by default.
   bool OperationsAllowed = false;
   // Check if the current hour is between the allowed hours of operations. If so, return true.
   if ((StartHour == LastHour) && (Hour() == StartHour))
      OperationsAllowed = true;
   if ((StartHour < LastHour) && (Hour() >= StartHour) && (Hour() <= LastHour))
      OperationsAllowed = true;
   if ((StartHour > LastHour) && (((Hour() >= LastHour) && (Hour() <= 23)) || ((Hour() <= StartHour) && (Hour() > 0))))
      OperationsAllowed = true;
   return OperationsAllowed;
}


//+------------------------------------------------------------------+
//| Inputs                                         |
//+------------------------------------------------------------------+

input int periodA= 20; //fast ema
input int periodB= 50; //fast ema

//Entry Inputs
input double InpStopLossPips = 25.0;      // Stop loss in pips
input double InpTakeProfitPips = 15.0;  // Take profit 1 in pips
input double volume = 1;  //fixed size   

//+------------------------------------------------------------------+
//| Global Variables                                |
//+------------------------------------------------------------------+


double StopLoss= 0;
double TakeProfit = 0;


int PositionCount = 0;

double currentPrice=0;

string msg = "";

int OnInit()
  {

   
    msg = "Auto-Bot has started 🚀 ";
  
   SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) ); 
   return(INIT_SUCCEEDED);
  }
  
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
  

void OnDeinit(const int reason)
  {

   msg = "Bot has ended 😔 ";
    SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) );
  }

void OnTick()
  {
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


// Check if there are no open positions
    if (OrdersTotal() == 0) {
// [BUY]- When the 20 crosses above the 50 ema 
if((Last_MA_1<Last_MA_2)&&(MA_1>MA_2))
{
//Calculate the current price for buy entry 
    currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK); 
    
    
    
     // Update StopLoss and TakeProfit for buy orders
    StopLoss = currentPrice - PipsToDouble(InpStopLossPips);
    TakeProfit = currentPrice + PipsToDouble(InpTakeProfitPips);
    
    OrderSend(_Symbol,OP_BUY,volume,currentPrice,3,StopLoss,TakeProfit,"Buy Taken",0,0,Green);
   msg = "🔔 Ka-Ching! Buy Trade Placed 🔔 ";
   msg += "\n";
         msg += "--------------------"; 
         msg += "\n";
   msg += "📈 Order executed @: ";
   msg += DoubleToStr(currentPrice, _Digits);
   msg += " 📈";
    msg += "\n";
   msg += "--------------------"; 
    msg += "\n";
   msg += " [SL:] ";
   msg += DoubleToStr(StopLoss, _Digits);
    msg += " 🚫";
   msg += "\n";
          msg += "--------------------";
           msg += "\n";
   msg += " [TP:] ";
   msg += DoubleToStr(TakeProfit, _Digits);
      msg += " 💰";
   msg += "\n";
          msg += "--------------------";
           msg += "\n";
          msg += "--------------------";
           msg += "\n";
          msg += "💹 2MA-CSR-NAS100-5MIN 💹";
          msg += "\n";
          msg += "--------------------\n";
   SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) ); 
  
      
        
        // Sleep for 5 minutes (300 seconds)
            Sleep(300000);
  

}
//[SELL]- When the 50 crosses above the 20 ema 
else if((Last_MA_1>Last_MA_2)&&(MA_1<MA_2))
{
   currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    
    // Update StopLoss and TakeProfit for sell orders
    StopLoss = currentPrice + PipsToDouble(InpStopLossPips);
    TakeProfit = currentPrice - PipsToDouble(InpTakeProfitPips);
     
  //Open a sell trade when the price is below or equal to the entry price.
        OrderSend(_Symbol,OP_SELL,volume,currentPrice,3,StopLoss,TakeProfit,"Sell Taken",0,0,Red);
        msg = "🔔 Ka-Ching! Sell Trade Placed 🔔 ";
        msg += "\n";
         msg += "--------------------"; 
         msg += "\n";
        msg += "📉 Order executed @: ";
          msg += DoubleToStr(currentPrice, _Digits);
            msg += "📉";
           msg += "\n";
   msg += "--------------------"; 
    msg += "\n";
          msg += " [SL:] ";
          msg += DoubleToStr(StopLoss, _Digits);
          msg += " 🚫";
           msg += "\n";
          msg += "--------------------";
           msg += "\n";
          msg += " [TP:] ";
          msg += DoubleToStr(TakeProfit, _Digits);
          msg += "💰";
          msg += "\n";
          msg += "--------------------";
           msg += "\n";
          msg += "--------------------";
           msg += "\n";
          msg += "💹 2MA-CSR-NAS100-5MIN 💹";
          msg += "\n";
          msg += "--------------------\n";
          
         SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                      msg+ "\n" + TimeToString( TimeLocal() ) );
        
        
    // Sleep for 5 minutes (300 seconds)
        Sleep(300000);
};
  }

  }
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