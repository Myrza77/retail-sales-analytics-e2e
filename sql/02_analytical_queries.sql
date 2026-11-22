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
having count(*) >= 100 and sum(profit) < 0
order by total_profit asc;

-- Query 6: Discount Tier Impact

select case 
when discount = 0 then 'No Discount'
when discount <= 0.20 then 'Low (1-20%)'
when discount <= 0.40 then 'Medium (21-40%)'
else 'High (>40%)'
end as discount_tier,
count(*) as line_items,
round(sum(sales), 2) as total_sales,
round(sum(profit), 2) as total_profit,
round(sum(profit) / sum(sales) * 100, 2) 
as profit_margin_pct
from fact_orders
group by discount_tier
order by profit_margin_pct desc;

-- Query 7: Yearly & Quarterly Performance Trend

select d.year, d.quarter,
count(distinct order_id) as unique_orders,
round(sum(sales), 2) as total_sales,
round(sum(profit), 2) as total_profit,
round(sum(profit) / sum(sales) * 100, 2) 
as profit_margin_pct
from fact_orders f
join dim_date d
on f.order_date = d.date_key
group by d.year, d.quarter
order by d.year, d.quarter;

-- Query 8: Shipping Speed & Profit

select ship_mode, count(distinct order_id) as unique_orders,
round(avg(ship_date - order_date), 2) as avg_shipping_days,
round(sum(sales), 2) as total_sales,
round(sum(profit), 2) as total_profit
from fact_orders
group by ship_mode
order by avg_shipping_days;

-- Query 9: Weekend vs. Weekday Sales

select d.is_weekend, 
count(distinct order_id) as unique_orders,
round(sum(sales), 2) as total_sales,
round(sum(profit), 2) as total_profit,
round(sum(sales) / count(distinct order_id), 2) 
as avg_order_value
from fact_orders f
join dim_date d
on d.date_key = f.order_date
group by d.is_weekend
order by total_sales desc;

-- Query 10: Above-Average Products

with product_sales as (
select p.product_id, p.product_name, p.category,
round(sum(f.sales), 2) as total_sales,
round(sum(f.profit), 2) as total_profit
from fact_orders f
join dim_products p
on f.product_id = p.product_id
group by p.product_id, p.product_name, p.category
)
select product_name, category, total_sales, total_profit 
from product_sales
where total_sales > (select avg(total_sales) from product_sales)
order by total_sales desc;

-- Query 11: Top 3 Products by Sales in Each Category

with product_sales as (
select category, p.product_id, p.product_name,
round(sum(f.sales), 2) as total_sales
from dim_products p
join fact_orders f
on f.product_id = p.product_id
group by category, p.product_id, p.product_name
),
ranked_products as ( 
select *,
dense_rank() over (partition by category order by total_sales desc)
as sales_rank from product_sales 
)
select category, product_id, product_name, sales_rank
from ranked_products
where sales_rank <=3
order by category, sales_rank;

-- Query 12: Month-over-Month (MoM) Sales Growth

with monthly_revenue as (
select d.year, d.month,
round(sum(sales), 2) as monthly_sales
from fact_orders f
join dim_date d
on f.order_date = d.date_key
group by d.year, d.month
),
prev_month as (
select *, 
lag(monthly_sales) over (order by year, month) 
as prev_month_sales
from monthly_revenue
)
select year, month, monthly_sales,
coalesce(prev_month_sales, 0) as prev_month_sales, 
coalesce(round((monthly_sales - prev_month_sales) / 
nullif(prev_month_sales, 0) * 100, 2), 0) 
as mom_growth_pct
from prev_month
order by year, month;















































































