/*Strategy: MACD_ADX.mq4*/
//Last modified 4/24/22
#property strict
const string TelegramBotToken = "5729595430:AAFM4onuWbbNYw6UlO1ZSsYhYcAxKVK7od8";
const string ChatId           = "-1001951546595";
const string TelegramApiUrl   = "https://api.telegram.org";
const int    UrlDefinedError  = 4066; 
#define EMOJI_TOP    "\xF51D";
#define EMOJI_DELIGHTED "\xF60A";


/* Check if trading is active */
int StartHour = 14; // 10am NYC Start operation hour
int  LastHour = 18; // 2PM NYC Last operation hour
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

int OnInit()
  {

   
   string msg = "Bot has started :) ";
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

    string msg = "Bot has ended ";
    SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) );
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
