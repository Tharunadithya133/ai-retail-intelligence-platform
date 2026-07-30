import os
import pandas as pd
from sqlalchemy import create_engine

DB_USER = "postgres"
DB_PASSWORD = "Anush77."
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "retail_analytics"

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)


project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
data_folder = os.path.join(project_root, "data", "raw")

print("Project Root:", project_root)
print("Data Folder:", data_folder)
print("Files:", os.listdir(data_folder))

for file in os.listdir(data_folder):
    print(file)
    if file.endswith(".csv"):
        table_name = file.replace(".csv", "").lower()

        file_path = os.path.join(data_folder, file)
        df = pd.read_csv(file_path)

        df.to_sql(
            table_name,
            engine,
            if_exists="replace",
            index=False
        )

        print(f"Imported {file} → {table_name}")

print("All datasets imported successfully!")