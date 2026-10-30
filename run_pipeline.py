"""Load raw CSVs into SQLite, run the cleaning SQL, print every analysis query,
and export the clean tables that the Power BI report reads.

Usage:  python run_pipeline.py
"""
import re
import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).parent
DB = ROOT / "bank_churn.db"


def main():
    DB.unlink(missing_ok=True)
    con = sqlite3.connect(DB)

    pd.read_csv(ROOT / "data/raw/customer_info.csv").to_sql("raw_customer_info", con, index=False)
    pd.read_csv(ROOT / "data/raw/account_info.csv").to_sql("raw_account_info", con, index=False)

    con.executescript((ROOT / "sql/01_clean_and_model.sql").read_text(encoding="utf-8"))

    print("## Data quality log\n")
    print(pd.read_sql("SELECT * FROM data_quality_log", con).to_markdown(index=False), "\n")

    analysis = (ROOT / "sql/02_analysis.sql").read_text(encoding="utf-8")
    for block in re.split(r"\n(?=-- Q\d)", analysis)[1:]:
        title = block.splitlines()[0].lstrip("- ").strip()
        print(f"## {title}\n")
        print(pd.read_sql(block, con).to_markdown(index=False), "\n")

    out = ROOT / "data/model"
    for table in ("customers", "accounts", "data_quality_log"):
        pd.read_sql(f"SELECT * FROM {table}", con).to_csv(out / f"{table}.csv", index=False)
    con.close()
    print(f"Exported model tables to {out}")


if __name__ == "__main__":
    main()
