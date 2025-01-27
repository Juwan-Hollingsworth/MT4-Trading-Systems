//+------------------------------------------------------------------+
//|                                           Telegram_Signal_EA.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict

#include <Telegram.mqh>

//--- input parameters
input string InpChannelName="ForexSignalChannel";//Channel Name
input string InpToken="6154194790:AAEfjcWjyixZwAX84liw8dhjVsBZoSbJJwI";//Token

//--- global variables
CCustomBot bot;
int macd_handle;
datetime time_signal=0;
bool checked;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   time_signal=0;

   bot.Token(InpToken);

#ifdef __MQL5__
   macd_handle=iMACD(NULL,0,12,26,9,PRICE_CLOSE);
   if(macd_handle==INVALID_HANDLE)
      return(INIT_FAILED);
//--- add the indicator to the chart
   int total=(int)ChartGetInteger(0,CHART_WINDOWS_TOTAL);
   ChartIndicatorAdd(0,total,macd_handle);
#endif

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(reason==REASON_PARAMETERS ||
         reason==REASON_RECOMPILE ||
         reason==REASON_ACCOUNT)
   {
      checked=false;
   }

//--- delete the indicator
#ifdef __MQL5__
   int total=(int)ChartGetInteger(0,CHART_WINDOWS_TOTAL);
   for(int subwin=total-1; subwin>=0; subwin--)
   {
      int amount=ChartIndicatorsTotal(0,subwin);
      for(int i=amount-1; i>=0; i--)
      {
         string name=ChartIndicatorName(0,subwin,i);
         if(StringFind(name,"MACD",0)==0)
            ChartIndicatorDelete(0,subwin,name);
      }
   }
#endif
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id==CHARTEVENT_KEYDOWN &&
         lparam=='Q')
   {

      bot.SendMessage(InpChannelName,"ee\nAt:100\nDDDD");
   }
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

   if(!checked)
   {
      if(StringLen(InpChannelName)==0)
      {
         Print("Error: Channel name is empty");
         Sleep(10000);
         return;
      }

      int result=bot.GetMe();
      if(result==0)
      {
         Print("Bot name: ",bot.Name());
         checked=true;
      }
      else
      {
         Print("Error: ",GetErrorDescription(result));
         Sleep(10000);
         return;
      }
   }

//--- get time
   datetime time[1];
   if(CopyTime(NULL,0,0,1,time)!=1)
      return;

//--- check the signal on each bar
   if(time_signal!=time[0])
   {
      //--- first calc
      if(time_signal==0)
      {
         time_signal=time[0];
         return;
      }

      double macd[2]= {0.0};
      double signal[2]= {0.0};

#ifdef __MQL4__
      for(int i=0; i<=1; i++)
      {
         macd[i]=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,i);
         signal[i]=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,i);
      }
#endif

#ifdef __MQL5__
      if(CopyBuffer(macd_handle,0,1,2,macd)!=2)
         return;
      if(CopyBuffer(macd_handle,1,1,2,signal)!=2)
         return;
#endif

      time_signal=time[0];

      //--- Send signal BUY
      if(macd[1]>signal[1] &&
            macd[0]<=signal[0] &&
            macd[0]<0.0)
      {
         string msg=StringFormat("Name: MACD Signal\xF4E3\nSymbol: %s\nTimeframe: %s\nType: Buy\nPrice: %s\nTime: %s",
                                 _Symbol,
                                 StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period),7),
                                 DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits),
                                 TimeToString(time[0]));
         int res=bot.SendMessage(InpChannelName,msg);
         if(res!=0)
            Print("Error: ",GetErrorDescription(res));
      }

      //--- Send signal SELL
      if(macd[1]<signal[1] &&
            macd[0]>=signal[0] &&
            macd[0]>0.0)
      {
         string msg=StringFormat("Name: MACD Signal\xF4E3\nSymbol: %s\nTimeframe: %s\nType: Sell\nPrice: %s\nTime: %s",
                                 _Symbol,
                                 StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period),7),
                                 DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits),
                                 TimeToString(time[0]));
         int res=bot.SendMessage(InpChannelName,msg);
         if(res!=0)
            Print("Error: ",GetErrorDescription(res));
      }
   }
}
//+------------------------------------------------------------------+
