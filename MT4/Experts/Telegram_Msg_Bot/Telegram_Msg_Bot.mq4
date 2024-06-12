

//bot token
const string telegramBotToken = "xxxx:yyyyyyyy";
//getTelegramId
const string chatId ="xxxx";
//telegram 
const string telegramApiUrl = "https://api.telegram.org";

const int UrlDefinedError=4066;

 void OnStart(void)
{
// can optionally change to trade just taken
   SendTelegramMessage(telegramApiUrl,telegramBotToken, chatId, "Test Msg" + TimeToString(TimeLocal()));

   bool SendTelegramMessage(string url, string token, string chat, string text, string fileName=""){

    string headers = "";
    string requestUrl="";
    char postData[];
    char resultData[];
    string resultHeaders;
    int timeout =1000;

    requestUrl = StringFormat("%s/bot%s/sendmessage?chat_id=%s&text=%s",url,token,chat,text);

    ResetLastError();
    int response = WebRequest("POST",requestUrl,headers,timeout,postData,resultData,resultHeaders);

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





   }
   
// end