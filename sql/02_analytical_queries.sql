-- Query 1: Overall Executive KPIs

select count(distinct order_id) as total_orders,
sum(quantity) as total_units,
round(sum(sales), 2) as total_sales,
round(sum(profit), 2) as total_profit,
round(sum(profit) / sum(sales) * 100, 2) as profit_margin_pct
from fact_orders;

-- Query 2: Category & Sub-Category Profitability

select p.category, p.sub_category, 
round(sum(sales), 2) as total_sales,
round(sum(profit), 2) as total_profit,
round(sum(profit) / sum(sales) * 100, 2) as profit_margin_pct
from fact_orders f
join dim_products p
on f.product_id = p.product_id
group by p.category, p.sub_category
order by total_profit;

-- Query 3: Regional Performance & Average Order Value (AOV)

select l.region, count(distinct customer_id) as unique_customers,
round(sum(sales), 2) as total_sales,
round(sum(profit), 2) as total_profit,
round(sum(sales) / count(distinct f.order_id), 2) 
as avg_order_value from fact_orders f
join dim_locations l
on f.location_id = l.location_id
group by l.region
order by total_sales desc;

-- Query 4: Top 10 Customers by Revenue

select c.customer_name, c.segment, 
round(sum(sales), 2) as total_sales,
round(sum(profit), 2) as total_profit,
count(distinct f.order_id) as total_orders
from fact_orders f
join dim_customers c
on f.customer_id = c.customer_id
group by c.customer_id, c.customer_name, c.segment
order by total_sales desc
limit 10;

-- Query 5: High-Volume, Money-Losing States

select l.state, count(*) as line_items,
round(sum(sales), 2) as total_sales,
round(sum(profit), 2) as total_profit
from fact_orders f
join dim_locations l
on f.location_id = l.location_id
group by l.state
having count(distinct row_id) >= 100 
and round(sum(profit), 2) < 0
order by total_profit asc;

















