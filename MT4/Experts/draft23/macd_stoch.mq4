
void OnTick()
  {
//---

//signal
string signal = "";

//define the EA
double K0 = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,0,MODE_MAIN,0);
double D0 = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);
double K1 = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,0,MODE_MAIN,1);
double D1 = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,0,MODE_SIGNAL,1);


//define MACD
double macd = iMACD(_Symbol,_Period,12,26,9,PRICE_CLOSE,MODE_MAIN,0);

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
  
//define stoploss + take profit
double stoploss = NormalizeDouble(Bid-250*_Point,_Digits);
if(signal == "buy" && OrdersTotal()==0)
  {
   OrderSend(_Symbol,OP_BUY,0.01,Bid,3,stoploss,Bid+500*_Point,"Buy Taken",0,0,Red);
  }
  
if(signal == "sell" && OrdersTotal()==0)
  {
   OrderSend(_Symbol,OP_SELL,0.01,Bid,3,stoploss,Bid-500*_Point,"Sell Taken",0,0,Red);
  }
  
Comment ("The current signal is:", signal);
//
   
  }
//+------------------------------------------------------------------+

