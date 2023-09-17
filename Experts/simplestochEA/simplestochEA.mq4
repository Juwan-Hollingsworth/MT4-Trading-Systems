
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

//sell signal
if((K0 > 80)&&(D0 >80)) //if curr k value is above 80 (overbought)
if((D0>K0)&&(D1 < K1)) //check for cross
  {
   signal = "sell";
  }
  
//buy signal 
if((K0 < 20)&&(D0 < 20)) //if curr k value is below 20 (oversold)
if((D0<K0)&&(D1 > K1)) //check for cross
  {
   signal = "buy";
  }
  
if(signal == "buy" && OrdersTotal()==0)
  {
   OrderSend(_Symbol,OP_BUY,0.10,Bid,3,0,Bid+150*_Point,"Buy Taken",0,0,Red);
  }
  
if(signal == "sell" && OrdersTotal()==0)
  {
   OrderSend(_Symbol,OP_SELL,0.10,Bid,3,0,Bid-150*_Point,"Sell Taken",0,0,Red);
  }
  
Comment ("The current signal is:", signal);
//
   
  }
//+------------------------------------------------------------------+
