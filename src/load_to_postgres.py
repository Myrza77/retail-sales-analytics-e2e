import os
from pathlib import Path
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

user = os.getenv("DB_USER")
password = os.getenv("DB_PASSWORD")
host = os.getenv("DB_HOST")
port = os.getenv("DB_PORT")
db_name = os.getenv("DB_NAME")

url = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{db_name}"
engine = create_engine(url)

df = pd.read_csv("data/raw/superstore.csv", encoding = "latin1")
print("Loaded rows:", len(df))

with engine.connect() as conn:
    print("Connected to:", db_name)
new_cols = []

for col in df.columns:
    clean_col = col.strip().lower().replace(" ", "_").replace("-", "_")
    new_cols.append(clean_col)

df.columns = new_cols

df = df.dropna(subset=["row_id", "order_id", "customer_id", "product_id"])
print("Rows after dropping blanks:", len(df))

df["row_id"] = df["row_id"].astype(int)
df["quantity"] = df["quantity"].astype(int)

df["postal_code"] = df["postal_code"].fillna(5401)
df["postal_code"] = df["postal_code"].astype(str)
df["postal_code"] = df["postal_code"].str.replace(".0", "", regex=False)
df["postal_code"] = df["postal_code"].str.zfill(5)

df["order_date"] = pd.to_datetime(df["order_date"], format="mixed").dt.date
df["ship_date"] = pd.to_datetime(df["ship_date"], format="mixed").dt.date

df = df.drop_duplicates(subset=["row_id"])

dim_customers = df[['customer_id', 'customer_name', 'segment']]
dim_customers = dim_customers.drop_duplicates(subset=['customer_id'])

dim_products = df[['product_id', 'product_name', 'category', 'sub_category']]
dim_products = dim_products.drop_duplicates(subset=['product_id'])

loc_cols = ['country', 'region', 'state', 'city', 'postal_code']
dim_locations = df[loc_cols].drop_duplicates().copy()
dim_locations["location_id"] = range(1, len(dim_locations) + 1)

start_date = min(df["order_date"].min(), df["ship_date"].min())
end_date = max(df["order_date"].max(), df["ship_date"].max())

dates = pd.date_range(start=start_date, end=end_date, freq="D")

dim_date = pd.DataFrame()

dim_date["date_key"] = dates.date
dim_date["year"] = dates.year
dim_date["quarter"] = dates.quarter
dim_date["month"] = dates.month
dim_date["month_name"] = dates.strftime("%B")
dim_date["day_of_week"] = dates.strftime("%A")
dim_date["is_weekend"] = dates.day_of_week >= 5

merged_df = df.merge(dim_locations, on=loc_cols, how="left")
fact_orders = merged_df[["row_id", "order_id", "order_date", "ship_date", "ship_mode", "customer_id", "product_id", "location_id", "sales", "quantity", "discount", "profit"]]

sql_file = open("sql/01_schema_star.sql", "r")
sql_code = sql_file.read()
sql_file.close()

with engine.begin() as conn:
    conn.execute(text(sql_code))

dim_customers.to_sql("dim_customers", engine, if_exists="append", index=False)
dim_products.to_sql("dim_products", engine, if_exists="append", index=False)
dim_locations.to_sql("dim_locations", engine, if_exists="append", index=False)
dim_date.to_sql("dim_date", engine, if_exists="append", index=False)
fact_orders.to_sql("fact_orders", engine, if_exists="append", index=False)

print("All 5 tables uploaded")

check_df = pd.read_sql("SELECT COUNT(*) AS rows, SUM(sales) AS sales, SUM(profit) AS profit FROM fact_orders", engine)

print("CSV rows: ", len(df), "| Postgres rows: ", check_df["rows"][0] )
print("CSV sales: ", round(df["sales"].sum(), 2), "| Postgres sales: ", round(check_df["sales"][0], 2))
print("CSV profit: ", round(df["profit"].sum(), 2), "| Postgres profit: ", round(check_df["profit"][0], 2))
