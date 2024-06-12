/*MACD RSI STOCH TRADING SYSTEM*/
/*
MACD STRATEGY - MACD Line Crossover
   Conditions:
     - MACD main line > signal line = Bull
     - MACD main line < signal line = Bear

    Check MACD lines at every tick
     - if mainline breaks above signal --> BULL comment
     - if mainline breaks below signal --> BEAR comment

    Conditions:
     - MACD main line > signal line = Bull
     - MACD main line < signal line = Bear

STOCH STRATEGY 
   Conditions:
     - %K, %D < 50 --> %K > %D = BUY
     - %K, %D > 50 --> %K < %D  = SELL
     - MACD main line < signal line = SIDEWAYS

RSI STRATEGY
   Conditions:
     - RSI < 50 = BUY
     - RSI > 70 = TP
     - RSI > 50 = SELL
     - RSI < 30 = TP      
*/

void OnTick()
{

   // define global variables
   string STOCH_signals = "";
   string currentSymbol = Symbol();
   //int MACD = iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE);
   //int Stoch = iStochastic(NULL, 0, 15, 3, 3, MODE_SMA, STO_LOWHIGH);
   //int RSI = iRSI(NULL, 0, 14, PRICE_CLOSE);
   
   double MACD = iMACD(currentSymbol,0,12,26,9,PRICE_CLOSE,0,0);
   int Stoch = iStochastic(currentSymbol,0,15,3,3,MODE_SMA,STO_LOWHIGH,0,0);
   int RSI = iRSI(currentSymbol, 0, 14, PRICE_CLOSE,0);

   //create arr to main & signal line
   double MACDMainLine[];
   double MACDSignalLine[];

   //create arr for %K & %D line
   double Stoch_Karray[];
   double Stoch_Darray[];

   //create arr for prices
   double RSI_Array[];
   
   // Set the size of the arrays
ArrayResize(MACDMainLine, 100); // Change 100 to the size you need
ArrayResize(MACDSignalLine, 100);
ArrayResize(Stoch_Karray, 100);
ArrayResize(Stoch_Darray, 100);
ArrayResize(RSI_Array, 100);


   // Sort price array from curr data for macd, rsi, stoch
   ArraySetAsSeries(MACDMainLine, true);
   ArraySetAsSeries(MACDSignalLine, true);
   ArraySetAsSeries(Stoch_Karray, true);
   ArraySetAsSeries(Stoch_Darray, true);
   ArraySetAsSeries(RSI_Array, true);

   //Copy values from indicator after defining the MA, line, & current data for mainline + signal
    MACDMainLine = iCustom(currentSymbol,0,"MACD",12,26,9,0,0);
    MACDSignalLine = iCustom(currentSymbol,0,"MACD",12,26,9,0,1);
  
   
   //Copy Values from Stoch indicator
   CopyBuffer(Stoch, 0, 0, 3, Stoch_Karray);
   CopyBuffer(Stoch, 1, 0, 3, Stoch_Darray);
   //Copy Values from Stoch indicator
   CopyBuffer(RSI, 0, 0, 1, RSI_Array);

   //Get values of curr data
   double MACDMainLine_Value = MACDMainLine[0];
   double MACDSignalLine_Value = MACDSignalLine[0];

   //create (2) variables for %K & %D values(0,1)
    // Used for curr data & data before curr
    double Stoch_Kvalue_0 = (Stoch_Karray[0]);
    double Stoch_Dvalue_0 = (Stoch_Darray[0]);
    double Stoch_Kvalue_1 = (Stoch_Karray[1]);
    double Stoch_Dvalue_1 = (Stoch_Darray[1]);

    double RSI_Value = NormalizeDouble(RSI_Array[0], 2);


    /*MACD, STOCH, RSI Strategy - Default Logic*/

if((iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0) > iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0)) &&
   (iRSI(_Symbol, _Period, 14, PRICE_CLOSE, 0) > 50) &&
   (iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 0) < 50 && iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 0) < 50) &&
   (iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 0) < iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 0)) &&
   (iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 1) > iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 1)))
{
   Comment("Buy Signal: MACD bullish cross, RSI < 50, and Stochastic Uptrend");
}
      
if((iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0) > iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0)) &&
   (iRSI(_Symbol, _Period, 14, PRICE_CLOSE, 0) < 50) &&
   (iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 0) > 50 && iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 0) > 50) &&
   (iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 0) < iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 0)) &&
   (iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 1) > iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 1)))
{
   Comment("Bearish Signal: MACD Bearish cross, RSI > 50, and Stochastic Downtrend");
}
      
else
{
   // define status var
   string r_status = "";
   string m_status = "";
   string s_status = "";
       // update macd status
    if(MACDMainLine_Value > MACDSignalLine_Value)
    {
        m_status += "BULLISH";
    }
    else if(MACDSignalLine_Value > MACDMainLine_Value)
    {
        m_status += "BEARISH";
    }
    // update stoch status
    if(Stoch_Kvalue_0 > 50 && Stoch_Dvalue_0 > 50)
    {
        s_status += "BEARISH";
    }
    if(Stoch_Kvalue_0 < 50 && Stoch_Dvalue_0 <50)
    {
        s_status += "BULLISH";
    }
    // update rsi status
    if(RSI_Value < 50)
    {
        r_status += "BULLISH";
    }
    if(RSI_Value > 50)
    {
        r_status += "BEARISH";
    }
    Comment("...Waiting 4 Opportunity...", "\n",
    "Indicator Status: ", "\n",
    "MACD: ",m_status,"\n",
    "STOCH: ",s_status,"\n",
    "RSI: ",r_status,"\n");
}}
   
   
    
    