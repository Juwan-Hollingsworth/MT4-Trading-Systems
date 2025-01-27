//+------------------------------------------------------------------+
//|                                              Telegram_Bot_EA.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict

#include <Comment.mqh>
#include <Telegram.mqh>

const ENUM_TIMEFRAMES _periods[] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_M30,PERIOD_H1,PERIOD_H4,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
//+------------------------------------------------------------------+
//|   CMyBot                                                         |
//+------------------------------------------------------------------+
class CMyBot: public CCustomBot
{
private:
   ENUM_LANGUAGES    m_lang;
   string            m_symbol;
   ENUM_TIMEFRAMES   m_period;
   string            m_template;
   CArrayString      m_templates;

public:
   //+------------------------------------------------------------------+
   void              Language(const ENUM_LANGUAGES _lang)
   {
      m_lang=_lang;
   }

   //+------------------------------------------------------------------+
   int               Templates(const string _list)
   {
      m_templates.Clear();
      //--- parsing
      string text=StringTrim(_list);
      if(text=="")
         return(0);

      //---
      while(StringReplace(text,"  "," ")>0);
      StringReplace(text,";"," ");
      StringReplace(text,","," ");

      //---
      string array[];
      int amount=StringSplit(text,' ',array);
      amount=fmin(amount,5);

      for(int i=0; i<amount; i++)
      {
         array[i]=StringTrim(array[i]);
         if(array[i]!="")
            m_templates.Add(array[i]);
      }

      return(amount);
   }

   //+------------------------------------------------------------------+
   int               SendScreenShot(const long _chat_id,
                                    const string _symbol,
                                    const ENUM_TIMEFRAMES _period,
                                    const string _template=NULL)
   {
      int result=0;

      long chart_id=ChartOpen(_symbol,_period);
      if(chart_id==0)
         return(ERR_CHART_NOT_FOUND);

      ChartSetInteger(ChartID(),CHART_BRING_TO_TOP,true);

      //--- updates chart
      int wait=60;
      while(--wait>0)
      {
         if(SeriesInfoInteger(_symbol,_period,SERIES_SYNCHRONIZED))
            break;
         Sleep(500);
      }

      if(_template!=NULL)
         if(!ChartApplyTemplate(chart_id,_template))
            PrintError(_LastError,InpLanguage);

      ChartRedraw(chart_id);
      Sleep(500);

      ChartSetInteger(chart_id,CHART_SHOW_GRID,false);

      ChartSetInteger(chart_id,CHART_SHOW_PERIOD_SEP,false);

      string filename=StringFormat("%s%d.gif",_symbol,_period);

      if(FileIsExist(filename))
         FileDelete(filename);
      ChartRedraw(chart_id);

      Sleep(100);

      if(ChartScreenShot(chart_id,filename,800,600,ALIGN_RIGHT))
      {
         
         Sleep(100);
         
         //--- Need for MT4 on weekends !!!
         ChartRedraw(chart_id);
         
         bot.SendChatAction(_chat_id,ACTION_UPLOAD_PHOTO);

         //--- waitng 30 sec for save screenshot
         wait=60;
         while(!FileIsExist(filename) && --wait>0)
            Sleep(500);

         //---
         if(FileIsExist(filename))
         {
            string screen_id;
            result=bot.SendPhoto(screen_id,_chat_id,filename,_symbol+"_"+StringSubstr(EnumToString(_period),7));
         }
         else
         {
            string mask=m_lang==LANGUAGE_EN?"Screenshot file '%s' not created.":"Файл скриншота '%s' не создан.";
            PrintFormat(mask,filename);
         }
      }

      ChartClose(chart_id);
      return(result);
   }

   //+------------------------------------------------------------------+
   void              ProcessMessages(void)
   {

#define EMOJI_TOP    "\xF51D"
#define EMOJI_BACK   "\xF519"
#define KEYB_MAIN    (m_lang==LANGUAGE_EN)?"[[\""Account Info Please"\"],[\"Quotes\"],[\"Charts\"]]":"[[\"Информация\"],[\"Котировки\"],[\"Графики\"]]"
#define KEYB_SYMBOLS "[[\""+EMOJI_TOP+"\",\"GBPUSD\",\"EURUSD\"],[\"NAS100\",\"USDJPY\",\"EURJPY\"],[\"USDCAD\",\"USDCHF\",\"EURCHF\"]]"
#define KEYB_PERIODS "[[\""+EMOJI_TOP+"\",\"M1\",\"M5\",\"M15\"],[\""+EMOJI_BACK+"\",\"M30\",\"H1\",\"H4\"],[\" \",\"D1\",\"W1\",\"MN1\"]]"

      for(int i=0; i<m_chats.Total(); i++)
      {
         CCustomChat *chat=m_chats.GetNodeAtIndex(i);
         if(!chat.m_new_one.done)
         {
            chat.m_new_one.done=true;
            string text=chat.m_new_one.message_text;

            //--- start
            if(text=="/start" || text=="/help")
            {
               chat.m_state=0;
               string msg="The bot works with your trading account:\n";
               msg+="/info - get account information\n";
               msg+="/quotes - get quotes\n";
               msg+="/charts - get chart images\n";

               if(m_lang==LANGUAGE_RU)
               {
                  msg="Бот работает с вашим торговым счетом:\n";
                  msg+="/info - запросить информацию по счету\n";
                  msg+="/quotes - запросить котировки\n";
                  msg+="/charts - запросить график\n";
               }

               SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_MAIN,false,false));
               continue;
            }

            //---
            if(text==EMOJI_TOP)
            {
               chat.m_state=0;
               string msg=(m_lang==LANGUAGE_EN)?"Choose a menu item":"Выберите пункт меню";
               SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_MAIN,false,false));
               continue;
            }

            //---
            if(text==EMOJI_BACK)
            {
               if(chat.m_state==31)
               {
                  chat.m_state=3;
                  string msg=(m_lang==LANGUAGE_EN)?"Enter a symbol name like 'EURUSD'":"Введите название инструмента, например 'EURUSD'";
                  SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
               }
               else if(chat.m_state==32)
               {
                  chat.m_state=31;
                  string msg=(m_lang==LANGUAGE_EN)?"Select a timeframe like 'H1'":"Введите период графика, например 'H1'";
                  SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_PERIODS,false,false));
               }
               else
               {
                  chat.m_state=0;
                  string msg=(m_lang==LANGUAGE_EN)?"Choose a menu item":"Выберите пункт меню";
                  SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_MAIN,false,false));
               }
               continue;
            }

            //---
            if(text=="/info" || text=="Account Info" || text=="Информация")
            {
               chat.m_state=1;
               string currency=AccountInfoString(ACCOUNT_CURRENCY);
               string msg=StringFormat("%d: %s\n",AccountInfoInteger(ACCOUNT_LOGIN),AccountInfoString(ACCOUNT_SERVER));
               msg+=StringFormat("%s: %.2f %s\n",(m_lang==LANGUAGE_EN)?"Balance":"Баланс",AccountInfoDouble(ACCOUNT_BALANCE),currency);
               msg+=StringFormat("%s: %.2f %s\n",(m_lang==LANGUAGE_EN)?"Profit":"Прибыль",AccountInfoDouble(ACCOUNT_PROFIT),currency);
               msg+=StringFormat("%s: %.2f %s\n",(m_lang==LANGUAGE_EN)?"Running":"Прибыль",AccountInfoDouble(ACCOUNT_PROFIT),currency);
               SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_MAIN,false,false));
            }

            //---
            if(text=="/quotes" || text=="Quotes" || text=="Котировки")
            {
               chat.m_state=2;
               string msg=(m_lang==LANGUAGE_EN)?"Enter a symbol name like 'EURUSD'":"Введите название инструмента, например 'EURUSD'";
               SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
               continue;
            }

            //---
            if(text=="/charts" || text=="Charts" || text=="Графики")
            {
               chat.m_state=3;
               string msg=(m_lang==LANGUAGE_EN)?"Enter a symbol name like 'EURUSD'":"Введите название инструмента, например 'EURUSD'";
               SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
               continue;
            }

            //--- Quotes
            if(chat.m_state==2)
            {
               string mask=(m_lang==LANGUAGE_EN)?"Invalid symbol name '%s'":"Инструмент '%s' не найден";
               string msg=StringFormat(mask,text);
               StringToUpper(text);
               string symbol=text;
               if(SymbolSelect(symbol,true))
               {
                  double open[1]= {0};

                  m_symbol=symbol;
                  //--- upload history
                  for(int k=0; k<3; k++)
                  {
#ifdef __MQL4__
                     double array[][6];
                     ArrayCopyRates(array,symbol,PERIOD_D1);
#endif

                     Sleep(2000);
                     CopyOpen(symbol,PERIOD_D1,0,1,open);
                     if(open[0]>0.0)
                        break;
                  }

                  int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
                  double bid=SymbolInfoDouble(symbol,SYMBOL_BID);

                  CopyOpen(symbol,PERIOD_D1,0,1,open);
                  if(open[0]>0.0)
                  {
                     double percent=100*(bid-open[0])/open[0];
                     //--- sign
                     string sign=ShortToString(0x25B2);
                     if(percent<0.0)
                        sign=ShortToString(0x25BC);

                     msg=StringFormat("%s: %s %s (%s%%)",symbol,DoubleToString(bid,digits),sign,DoubleToString(percent,2));
                  }
                  else
                  {
                     msg=(m_lang==LANGUAGE_EN)?"No history for ":"Нет истории для "+symbol;
                  }
               }

               SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
               continue;
            }

            //--- Charts
            if(chat.m_state==3)
            {

               StringToUpper(text);
               string symbol=text;
               if(SymbolSelect(symbol,true))
               {
                  m_symbol=symbol;

                  chat.m_state=31;
                  string msg=(m_lang==LANGUAGE_EN)?"Select a timeframe like 'H1'":"Введите период графика, например 'H1'";
                  SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_PERIODS,false,false));
               }
               else
               {
                  string mask=(m_lang==LANGUAGE_EN)?"Invalid symbol name '%s'":"Инструмент '%s' не найден";
                  string msg=StringFormat(mask,text);
                  SendMessage(chat.m_id,msg,ReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
               }
               continue;
            }

            //Charts->Periods
            if(chat.m_state==31)
            {
               bool found=false;
               int total=ArraySize(_periods);
               for(int k=0; k<total; k++)
               {
                  string str_tf=StringSubstr(EnumToString(_periods[k]),7);
                  if(StringCompare(str_tf,text,false)==0)
                  {
                     m_period=_periods[k];
                     found=true;
                     break;
                  }
               }

               if(found)
               {
                  //--- template
                  chat.m_state=32;
                  string str="[[\""+EMOJI_BACK+"\",\""+EMOJI_TOP+"\"]";
                  str+=",[\"None\"]";
                  for(int k=0; k<m_templates.Total(); k++)
                     str+=",[\""+m_templates.At(k)+"\"]";
                  str+="]";

                  SendMessage(chat.m_id,(m_lang==LANGUAGE_EN)?"Select a template":"Выберите шаблон",ReplyKeyboardMarkup(str,false,false));
               }
               else
               {
                  SendMessage(chat.m_id,(m_lang==LANGUAGE_EN)?"Invalid timeframe":"Неправильно задан период графика",ReplyKeyboardMarkup(KEYB_PERIODS,false,false));
               }
               continue;
            }
            //---
            if(chat.m_state==32)
            {
               m_template=text;
               if(m_template=="None")
                  m_template=NULL;
               int result=SendScreenShot(chat.m_id,m_symbol,m_period,m_template);
               if(result!=0)
                  Print(GetErrorDescription(result,InpLanguage));
            }
         }
      }
   }
};

//+------------------------------------------------------------------+
#define EXPERT_NAME     "Telegram Bot"
#define EXPERT_VERSION  "1.00"
#property version       EXPERT_VERSION
#define CAPTION_COLOR   clrWhite
#define LOSS_COLOR      clrOrangeRed

//+------------------------------------------------------------------+
//|   Input parameters                                               |
//+------------------------------------------------------------------+
input ENUM_LANGUAGES    InpLanguage=LANGUAGE_EN;//Language
input ENUM_UPDATE_MODE  InpUpdateMode=UPDATE_NORMAL;//Update Mode
input string            InpToken="";//Token
input string            InpUserNameFilter="";//Whitelist Usernames
input string            InpTemplates="ADX;BollingerBands;Momentum";//Templates

//---
CComment       comment;
CMyBot         bot;
ENUM_RUN_MODE  run_mode;
datetime       time_check;
int            web_error;
int            init_error;
string         photo_id=NULL;
//+------------------------------------------------------------------+
//|   OnInit                                                         |
//+------------------------------------------------------------------+
int OnInit()
{

//---
   run_mode=GetRunMode();

//--- stop working in tester
   if(run_mode!=RUN_LIVE)
   {
      PrintError(ERR_RUN_LIMITATION,InpLanguage);
      return(INIT_FAILED);
   }

   int y=40;
   if(ChartGetInteger(0,CHART_SHOW_ONE_CLICK))
      y=120;
   comment.Create("myPanel",20,y);
   comment.SetColor(clrDimGray,clrBlack,220);
//--- set language
   bot.Language(InpLanguage);

//--- set token
   init_error=bot.Token(InpToken);

//--- set filter
   bot.UserNameFilter(InpUserNameFilter);

//--- set templates
   bot.Templates(InpTemplates);

//--- set timer
   int timer_ms=3000;
   switch(InpUpdateMode)
   {
   case UPDATE_FAST:
      timer_ms=1000;
      break;
   case UPDATE_NORMAL:
      timer_ms=2000;
      break;
   case UPDATE_SLOW:
      timer_ms=3000;
      break;
   default:
      timer_ms=3000;
      break;
   };
   EventSetMillisecondTimer(timer_ms);
   OnTimer();
//--- done
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|   OnDeinit                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   if(reason==REASON_CLOSE ||
         reason==REASON_PROGRAM ||
         reason==REASON_PARAMETERS ||
         reason==REASON_REMOVE ||
         reason==REASON_RECOMPILE ||
         reason==REASON_ACCOUNT ||
         reason==REASON_INITFAILED)
   {
      time_check=0;
      comment.Destroy();
   }
//---
   EventKillTimer();
   ChartRedraw();
}
//+------------------------------------------------------------------+
//|   OnChartEvent                                                   |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   comment.OnChartEvent(id,lparam,dparam,sparam);
}
//+------------------------------------------------------------------+
//|   OnTimer                                                        |
//+------------------------------------------------------------------+
void OnTimer()
{

//--- show init error
   if(init_error!=0)
   {
      //--- show error on display
      CustomInfo info;
      GetCustomInfo(info,init_error,InpLanguage);

      //---
      comment.Clear();
      comment.SetText(0,StringFormat("%s v.%s",EXPERT_NAME,EXPERT_VERSION),CAPTION_COLOR);
      comment.SetText(1,info.text1, LOSS_COLOR);
      if(info.text2!="")
         comment.SetText(2,info.text2,LOSS_COLOR);
      comment.Show();

      return;
   }

//--- show web error
   if(run_mode==RUN_LIVE)
   {

      //--- check bot registration
      if(time_check<TimeLocal()-PeriodSeconds(PERIOD_H1))
      {
         time_check=TimeLocal();
         if(TerminalInfoInteger(TERMINAL_CONNECTED))
         {
            //---
            web_error=bot.GetMe();
            if(web_error!=0)
            {
               //---
               if(web_error==ERR_NOT_ACTIVE)
               {
                  time_check=TimeCurrent()-PeriodSeconds(PERIOD_H1)+300;
               }
               //---
               else
               {
                  time_check=TimeCurrent()-PeriodSeconds(PERIOD_H1)+5;
               }
            }
         }
         else
         {
            web_error=ERR_NOT_CONNECTED;
            time_check=0;
         }
      }

      //--- show error
      if(web_error!=0)
      {
         comment.Clear();
         comment.SetText(0,StringFormat("%s v.%s",EXPERT_NAME,EXPERT_VERSION),CAPTION_COLOR);

         if(
#ifdef __MQL4__ web_error==ERR_FUNCTION_NOT_CONFIRMED #endif
#ifdef __MQL5__ web_error==ERR_FUNCTION_NOT_ALLOWED #endif
         )
         {
            time_check=0;

            CustomInfo info= {0};
            GetCustomInfo(info,web_error,InpLanguage);
            comment.SetText(1,info.text1,LOSS_COLOR);
            comment.SetText(2,info.text2,LOSS_COLOR);
         }
         else
            comment.SetText(1,GetErrorDescription(web_error,InpLanguage),LOSS_COLOR);

         comment.Show();
         return;
      }
   }

//---
   bot.GetUpdates();

//---
   if(run_mode==RUN_LIVE)
   {
      comment.Clear();
      comment.SetText(0,StringFormat("%s v.%s",EXPERT_NAME,EXPERT_VERSION),CAPTION_COLOR);
      comment.SetText(1,StringFormat("%s: %s",(InpLanguage==LANGUAGE_EN)?"Bot Name":"Имя Бота",bot.Name()),CAPTION_COLOR);
      comment.SetText(2,StringFormat("%s: %d",(InpLanguage==LANGUAGE_EN)?"Chats":"Чаты",bot.ChatsTotal()),CAPTION_COLOR);
      comment.Show();
   }

//---
   bot.ProcessMessages();
}
//+------------------------------------------------------------------+
//|   GetCustomInfo                                                  |
//+------------------------------------------------------------------+
void GetCustomInfo(CustomInfo &info,
                   const int _error_code,
                   const ENUM_LANGUAGES _lang)
{
   switch(_error_code)
   {
#ifdef __MQL5__
   case ERR_FUNCTION_NOT_ALLOWED:
      info.text1 = (_lang==LANGUAGE_EN)?"The URL does not allowed for WebRequest":"Этого URL нет в списке для WebRequest.";
      info.text2 = TELEGRAM_BASE_URL;
      break;
#endif
#ifdef __MQL4__
   case ERR_FUNCTION_NOT_CONFIRMED:
      info.text1 = (_lang==LANGUAGE_EN)?"The URL does not allowed for WebRequest":"Этого URL нет в списке для WebRequest.";
      info.text2 = TELEGRAM_BASE_URL;
      break;
#endif

   case ERR_TOKEN_ISEMPTY:
      info.text1 = (_lang==LANGUAGE_EN)?"The 'Token' parameter is empty.":"Параметр 'Token' пуст.";
      info.text2 = (_lang==LANGUAGE_EN)?"Please fill this parameter.":"Пожалуйста задайте значение для этого параметра.";
      break;
   }

}
//+------------------------------------------------------------------+
