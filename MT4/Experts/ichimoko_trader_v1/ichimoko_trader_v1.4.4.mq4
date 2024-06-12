//+------------------------------------------------------------------+
//|                                        ichimoko_trader_v1.mq4    |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict

double Conversion_Line, Base_Line, Leading_SpanA, Leading_SpanB, Lagging_Span;
double currentPrice;
double SL, TP, SL_sell, TP_sell;

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Function to check if price has closed below the Ichimoku cloud    |
//+------------------------------------------------------------------+
bool HasPriceClosedBelowCloud()
{
    return (Close[0] < Leading_SpanA && Close[0] < Leading_SpanB);
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
    currentPrice = Bid;

    // Calculate dynamic stop loss and take profit levels
    SL = NormalizeDouble(currentPrice + 1000 * Point, _Digits);
    TP = NormalizeDouble(currentPrice - 3000 * Point, _Digits);

    double lotSize = 0.01;

    // Check if price has closed below the cloud
    if (HasPriceClosedBelowCloud())
    {
        // Check for touch condition and no open orders
        if (Bid <= Leading_SpanB && OrdersTotal() == 0)
        {
            // Price has touched span B
            OrderSend(_Symbol, OP_SELL, lotSize, Bid, 3, SL, TP, "Sell Taken", 0, 0, Red);
        }
    }
}
//+------------------------------------------------------------------+
