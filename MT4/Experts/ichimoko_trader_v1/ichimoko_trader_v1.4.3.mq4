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
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Function to check if price has closed above the Ichimoku cloud    |
//+------------------------------------------------------------------+
bool HasPriceClosedAboveCloud()
{
    return (Close[0] > Leading_SpanA && Close[0] > Leading_SpanB);
}

//+------------------------------------------------------------------+
//| Function to modify stop price to breakeven if current profit > $10 |
//+------------------------------------------------------------------+
void ModifyStopToBreakEven()
{
    int total = OrdersTotal();
    for (int i = 0; i < total; i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if (OrderType() == OP_BUY && OrderProfit() > 10.0)
            {
                double breakEvenPrice = OrderOpenPrice();
                if (OrderStopLoss() < breakEvenPrice)
                {
                    OrderModify(OrderTicket(), OrderOpenPrice(), breakEvenPrice, OrderTakeProfit(), 0, Green);
                }
            }
        }
    }
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
    SL = NormalizeDouble(currentPrice - 1000 * Point, _Digits);
    TP = NormalizeDouble(currentPrice + 3000 * Point, _Digits);

    double lotSize = 0.01;

    // Check if price has closed above the cloud
    if (HasPriceClosedAboveCloud())
    {
        // Check for crossover condition and no open orders
        if (Base_Line > Conversion_Line && OrdersTotal() == 0)
        {
            // Kijun Sen has crossed over Tenkan Sen
            OrderSend(_Symbol, OP_BUY, lotSize, Ask, 3, SL, TP, "Buy Taken", 0, 0, Red);
        }
    }

    // Modify stop price to breakeven if current profit > $10
    ModifyStopToBreakEven();
}