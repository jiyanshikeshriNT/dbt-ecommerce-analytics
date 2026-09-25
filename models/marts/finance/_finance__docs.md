{% docs fct_daily_revenue_grain %}

## fct_daily_revenue Grain

The grain of `fct_daily_revenue` is **one row per order**, identified by
`order_id`.

Each row contains the customer who placed the order, the order date and
status, and the total payment revenue associated with that order.

Payments may arrive after an order has already been processed. For this
reason, the model uses an incremental MERGE strategy with a three-day
lookback window so recent orders can be recalculated when late payments
arrive.

Revenue is stored in cents upstream and converted to US dollars using the
reusable `cents_to_dollars` macro.

{% enddocs %}