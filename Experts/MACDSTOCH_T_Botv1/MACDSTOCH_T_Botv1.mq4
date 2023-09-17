//+------------------------------------------------------------------+
//|                                            MACDSTOCH_T_Botv1.mq4 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict
//+------------------------------------------------------------------+
//| Global Variables                                  |
//+------------------------------------------------------------------+
/*Telegram*/
const string TelegramBotToken = "5729595430:AAFM4onuWbbNYw6UlO1ZSsYhYcAxKVK7od8";
const string ChatId           = "-1001951546595";
const string TelegramApiUrl   = "https://api.telegram.org"; // Add this to Allow URLs
const int    UrlDefinedError  = 4066; 

#define EMOJI_TOP    "\xF51D";
 #define EMOJI_DELIGHTED "\xF60A";




//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
  {
//---
   
   string msg = "Bot has started " + EMOJI_TOP;
   SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) ); // no image attache
//---
   return(INIT_SUCCEEDED);
  }
  
  //+------------------------------------------------------------------+
//| Telegram functions                                 |
//+------------------------------------------------------------------+
  bool SendTelegramMessage( string url, string token, string chat, string text) {

   string headers    = "";
   string requestUrl = "";
   char   postData[];
   char   resultData[];
   string resultHeaders;
   int    timeout = 5000; // 1 second, may be too short for a slow connection'
   
   requestUrl = StringFormat( "%s/bot%s/sendmessage?chat_id=%s&text=%s", url, token, chat, text, "&parse_mode=HTML" );
   int response = WebRequest( "POST", requestUrl, headers, timeout, postData, resultData, resultHeaders );
   ResetLastError();
   switch ( response ) {
   case -1: {
      int errorCode = GetLastError();
      Print( "Error in WebRequest. Error code  =", errorCode );
      if ( errorCode == UrlDefinedError ) {
         //--- url may not be listed
         PrintFormat( "Add the address '%s' in the list of allowed URLs", url );
      }
      break;
   }
   case 200:
      //--- Success
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
   int    timeout = 5000; // 1 second, may be too short for a slow connection'
   
   requestUrl = StringFormat( "%s/bot%s/sendmessage?chat_id=%s&text=%s", url, token, chat, text, "&parse_mode=HTML" );
   int response = WebRequest( "POST", requestUrl, headers, timeout, postData, resultData, resultHeaders );
   ResetLastError();
   switch ( response ) {
   case -1: {
      int errorCode = GetLastError();
      Print( "Error in WebRequest. Error code  =", errorCode );
      if ( errorCode == UrlDefinedError ) {
         //--- url may not be listed
         PrintFormat( "Add the address '%s' in the list of allowed URLs", url );
      }
      break;
   }
   case 200:
      //--- Success
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
  
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
    //send message 2 telegram when bot is powered off.
    string msg = "Bot has ended ";
    SendTelegramMessage( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) );
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //---


  /* AutoTrade settings*/
 double lotSize = 0.05; // define lot size
 double open_price=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
 double close_price=SymbolInfoDouble(_Symbol,SYMBOL_BID);
 //double stopLoss_ATR= open_price-2*atr*_Point;
 //double takeprofit_ATR = open_price +4*atr*_Point;
 double SL = Bid-150*Point; //Define stop loss
 double TP = Ask+450*Point;  // define TP
 double SL_sell = close_price+150*SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
 double TP_sell = close_price-450*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
 



//signal
string signal = "";

//define the EA
double K0 = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,0,MODE_MAIN,0);
double D0 = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);
double K1 = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,0,MODE_MAIN,1);
double D1 = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,0,MODE_SIGNAL,1);


//define MACD
double macd = iMACD(_Symbol,_Period,12,26,9,PRICE_CLOSE,MODE_MAIN,0);

/*ATR STOPLOSS SETTINGS
double atr=iATR(_Symbol,_Period,14,0);
double SL =NormalizeDouble(open_price-(atr*1.5),_Digits);
double TP = NormalizeDouble(open_price+(atr*2),_Digits); */




//conditions
if (macd>0)
{
if((K0 > 80)&&(D0 >80)) 
if((D0>K0)&&(D1 < K1)) 
  {
   signal = "sell";
  }
}

if (macd<0)
{
if((K0 < 20)&&(D0 < 20)) 
if((D0<K0)&&(D1 > K1)) 
  {
   signal = "buy";
  }
}
double entryPrice_b = Ask;
double entryPrice_s = Bid;

  
if(signal == "buy" && OrdersTotal()==0)
  {
  OrderSend(_Symbol,OP_BUY,lotSize,entryPrice_b,3,SL,TP,"Buy Taken",0,0,Red);
  string msg = "Buy order executed @ " + DoubleToStr(entryPrice_b,_Digits) + "\n" + 
  "SL: " + DoubleToStr(SL,_Digits) + "\n" +
  "TP: " + DoubleToStr(TP,_Digits) ;
   SendTelegramMessage_alert( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) );
   
   
  }
  
if(signal == "sell" && OrdersTotal()==0)
  {
   OrderSend(_Symbol,OP_SELL,lotSize,entryPrice_s,3,SL_sell,TP_sell,"Sell Taken",0,0,Red);
   //OrderSend(_Symbol,OP_SELL,0.01,Bid,3,stoploss,Bid-500*_Point,"Sell Taken",0,0,Red);
   
   //send telegram message
  string msg = "Sell order executed @ " + DoubleToStr(entryPrice_s,_Digits) + "\n" + 
  "SL: " + DoubleToStr(SL_sell,_Digits) + "\n" +
  "TP: " + DoubleToStr(TP_sell,_Digits) ;
   SendTelegramMessage_alert( TelegramApiUrl, TelegramBotToken, ChatId,
                                msg+ "\n" + TimeToString( TimeLocal() ) );
   
   
  }
  

//testing purposes
Comment ("The current signal is:", signal);


  }
//+------------------------------------------------------------------+
