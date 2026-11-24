import os
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
import matplotlib.pyplot as plt
import seaborn as sns

sns.set_theme(style="whitegrid")
os.makedirs("assets", exist_ok=True)

load_dotenv()

user = os.getenv("DB_USER")
password = os.getenv("DB_PASSWORD")
host = os.getenv("DB_HOST")
port = os.getenv("DB_PORT")
db_name = os.getenv("DB_NAME")

url = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{db_name}"
engine = create_engine(url)

query = """
select 
    f.order_id, f.order_date, f.ship_date, f.ship_mode, 
    f.sales, f.quantity, f.discount, f.profit,
    c.customer_name, c.segment, p.product_name, p.category, 
    p.sub_category, l.region, l.state, l.city, d.year, 
    d.quarter, d.month, d.month_name, d.is_weekend
    from fact_orders f
    join dim_products p
    on f.product_id = p.product_id
    join dim_customers  c
    on c.customer_id = f.customer_id
    join dim_locations l
    on l.location_id = f.location_id
    join dim_date d
    on d.date_key = f.order_date
    """
df = pd.read_sql(query, engine)

print("Shape:", df.shape)

loss_orders = df[df["profit"] < 0 ]
pct = len(loss_orders) / len(df) * 100
total_loss = loss_orders["profit"].sum()

print(f"Unprofitable orders: {pct:.2f}% | Total loss: ${total_loss:,.2f}")

df["profit_margin"] = df["profit"] / df["sales"]

df.to_csv("data/processed/superstore_clean.csv", index=False)

correl = df[["discount", "profit", "profit_margin"]].corr()

print("\nCorrelation Matrix:\n", correl.round(2))

worst_subcats = (df.groupby(["sub_category"], as_index=False).agg
(
    total_sales=("sales", "sum"),
    total_profit=("profit", "sum"),
    mean_discount=("discount", "mean")
)
.sort_values(by="total_profit", ascending=True)
.head(5)
.round(2)
)
print("\nWorst 5 Sub-Categories:\n", worst_subcats)

monthly_sales = (
    df.groupby(["year", "month"], as_index=False)
    .agg(sales = ("sales", "sum")
    )
)
monthly_sales["date"] = pd.to_datetime(monthly_sales[["year", "month"]].assign(day=1))


plt.figure(figsize=(10, 5))
sns.lineplot(data=monthly_sales, x="date", y="sales", marker="o")
plt.title("Monthly Sales Trend", fontsize=13, fontweight="bold")
plt.xlabel("Month")
plt.ylabel("Total Revenue ($)")
plt.savefig("assets/01_monthly_sales_trend.png", dpi=300, bbox_inches="tight")
plt.close()

subcat_profit = (
    df.groupby(["sub_category"], as_index=False)
    .agg(profit=("profit", "sum")
    )
    .sort_values(by="profit", ascending=False)
)
colors = ["#d9534f" if p < 0 else "#2b7bba" for p in subcat_profit["profit"]]

plt.figure(figsize=(10, 6))
sns.barplot(data=subcat_profit, x="profit", y="sub_category", palette=colors, hue="sub_category", legend=False)
plt.axvline(0, color="black", linewidth=0.8)
plt.title("Total Profit by Sub-Category")
plt.xlabel("Total Profit ($)")
plt.ylabel("Sub-Category")
plt.savefig("assets/02_subcategory_profit.png", dpi=300, bbox_inches="tight")
plt.close()

discount_df = (df.groupby("discount", as_index=False)
              .agg(avg_margin=("profit_margin", "mean"))
              .sort_values(by="discount", ascending=True)
)
discount_df["discount_pct"] = (discount_df["discount"] * 100).round(0).astype(int)
discount_df["avg_margin_pct"] = discount_df["avg_margin"] * 100

colors = ["#d9534f" if p < 0 else "#2b7bba" for p in discount_df["avg_margin_pct"]]

plt.figure(figsize=(10, 5))
sns.barplot(data=discount_df, x="discount_pct", y="avg_margin_pct", palette=colors, hue="discount_pct", legend=False)
plt.axhline(0, color="black", linewidth=0.8)
plt.title("Average Profit Margin (%) by Discount Tier")
plt.xlabel("Discount (%)")
plt.ylabel("Average Profit Margin (%)")
plt.savefig("assets/03_discount_vs_profit.png", dpi=300, bbox_inches="tight")
plt.close()

region_perf = (df.groupby("region", as_index=False)
               .agg(Sales = ("sales", "sum"),
                    Profit = ("profit", "sum"))
               .sort_values(by="Sales", ascending=False)
)

region_melted = region_perf.melt(
    id_vars="region",
    value_vars=["Sales", "Profit"],
    var_name="Metric",
    value_name="Amount",
)

plt.figure(figsize=(8, 5))
sns.barplot(data=region_melted, x="region", y="Amount", hue="Metric")
plt.title("Total Sales vs. Profit by Region")
plt.xlabel("Region")
plt.ylabel("Amount ($)")
plt.savefig("assets/04_regional_performance.png", dpi=300, bbox_inches="tight")
plt.close()

