//+------------------------------------------------------------------+
//|                                        ichimoko_trader_v1.mq4    |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict

double Conversion_Line, Base_Line, Leading_SpanA, Leading_SpanB, Lagging_Span;
double currentPrice;
double SL, TP, SL_sell, TP_sell;
bool breakoutDetected = false;
double lotSize = 0.01;


//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Update Ichimoku values
    Conversion_Line = iIchimoku(_Symbol, _Period, 9, 26, 52, MODE_TENKANSEN, 0);
    Base_Line = iIchimoku(_Symbol, _Period, 9, 26, 52, MODE_KIJUNSEN, 0);
    Leading_SpanA = iIchimoku(_Symbol, _Period, 9, 26, 52, MODE_SENKOUSPANA, -26);
    Leading_SpanB = iIchimoku(_Symbol, _Period, 9, 26, 52, MODE_SENKOUSPANB, -26);
    Lagging_Span = iIchimoku(_Symbol, _Period, 9, 26, 52, MODE_CHIKOUSPAN, 26);
    currentPrice = Ask;

    // Calculate dynamic stop loss and take profit levels
    SL = NormalizeDouble(currentPrice - 750 * Point, _Digits);
    TP = NormalizeDouble(currentPrice + 2250 * Point, _Digits);
    
    int maxOrders = 1;  // Maximum number of allowed open orders
int totalOrders = 0;  // Counter for open orders

    // condition 1: If price is above the cloud
    if (currentPrice > Leading_SpanA && currentPrice > Leading_SpanB && !breakoutDetected)
    {
        // Bullish breakout detected
        breakoutDetected = true;
        Print("Bullish breakout detected");

        // condition 2: crossover
        if (Base_Line > Conversion_Line && totalOrders < maxOrders)
        {
            // Kijun Sen has crossed over Tenkan Sen
            OrderSend(_Symbol, OP_BUY, lotSize, Ask, 3, SL, TP, "Buy Taken", 0, 0, Red);
            totalOrders++;
        }
    }
}
//+------------------------------------------------------------------+
