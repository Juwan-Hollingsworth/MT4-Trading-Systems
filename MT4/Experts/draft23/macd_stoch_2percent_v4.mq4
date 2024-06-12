/*Notes:
Settings 3:1
Profitable:
NAS 5min 
NAS 1Min

*/

 

int StartHour = 12; // Start operation hour
int  LastHour = 20; // Last operation hour

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

 


void OnTick()
  {
//---


  /* AutoTrade settings*/
 double lotSize = 0.01; // define lot size
 double open_price=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
 double close_price=SymbolInfoDouble(_Symbol,SYMBOL_BID);
 //double stopLoss_ATR= open_price-2*atr*_Point;
 //double takeprofit_ATR = open_price +4*atr*_Point;
 double SL = Bid-750*Point; //Define stop loss
 double TP = Ask+2250*Point;  // define TP
 double SL_sell = Ask+750*SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
 double TP_sell = Bid-2250*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
 



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
  
if(signal == "buy" && OrdersTotal()==0 && CheckActiveHours() == true)
  {
  OrderSend(_Symbol,OP_BUY,lotSize,Ask,3,SL,TP,"Buy Taken",0,0,Red);
   
   
  }
  
if(signal == "sell" && OrdersTotal()==0 && CheckActiveHours() == true)
  {
   OrderSend(_Symbol,OP_SELL,lotSize,Bid,3,SL_sell,TP_sell,"Sell Taken",0,0,Red);
   //OrderSend(_Symbol,OP_SELL,0.01,Bid,3,stoploss,Bid-500*_Point,"Sell Taken",0,0,Red);
   
   
  } else
      {
       Comment ("sleeping");
      }
  


//Comment ("The current signal is:", signal);
}
//
   

//+------------------------------------------------------------------+

