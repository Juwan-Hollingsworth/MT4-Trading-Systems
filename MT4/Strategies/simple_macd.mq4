//+------------------------------------------------------------------+
//|                                                  simple_macd.mq4 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Notes:                                                           |
    /*
     9/13/23 -Currently configured for 15 pip tp
     
    
    
    
    
    */
//+------------------------------------------------------------------+
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
// Define universal variables and parameters here


//+------------------------------------------------------------------+
void OnTick()
{
  /* Create a signal (str) to hold signal value */ 
  string signal = "";

 /* Define the EA */ 
//Other EA settings for testing - 24,52,9 - TF 30M
  double MACD = iMACD(_Symbol,_Period,12,26,9,PRICE_CLOSE, MODE_MAIN,0);

  /* Create signal conditions */  
    //--Buy signal
   if (MACD<0){
    signal = "buy";
  }
    //--Sell signal
  if (MACD>0){
    signal = "sell";
  }

  /* Order Execution: */ 
  
  if(signal == "buy" && OrdersTotal()==0){
    OrderSend(_Symbol, OP_BUY,0.10, Ask, 3, 0, Ask+1500*_Point,NULL,0,0,Green);
  }

  if(signal == "sell" && OrdersTotal()==0){
    OrderSend(_Symbol, OP_SELL,0.10, Bid, 3, 0, Bid-1500*_Point,NULL,0,0,Red);
  }

   /* Chart Output for signal */ 
   Comment ("The current signal is:", signal);

}
//+------------------------------------------------------------------+