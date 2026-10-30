# Building the Power BI dashboard (about 30 minutes)

Everything the dashboard needs is already prepared. Run `python run_pipeline.py` first so
`data/model/` holds fresh CSVs.

## 1. Load the data (3 min)

1. Open Power BI Desktop → **Get data → Text/CSV**.
2. Load `data/model/customers.csv`, then `data/model/accounts.csv`, then `data/model/data_quality_log.csv`.
3. **Model view:** check there is a relationship `customers[customer_id]` 1 → 1 `accounts[customer_id]`.
   If Power BI made it "both directions", that is fine for a 1-to-1 relationship.
4. In **Table view**, set `customer_id` to *Whole number*, `balance` and `estimated_salary` to *Decimal number*,
   and `Churn Rate %` / `Share of Balance Lost %` (after step 2) to *Percentage* with 1 decimal.

## 2. Add the measures (5 min)

Open `powerbi/measures.dax`. For each block: select the **accounts** table → **New measure** → paste → Enter.

## 3. Page 1 — "Churn overview" (15 min)

| Position | Visual | Fields |
|---|---|---|
| Top row | 4 × **Card** | `Customers`, `Churn Rate %`, `Balance Lost`, `Retention Targets` |
| Middle left | **Clustered bar chart** | Y-axis `customers[country]`, X-axis `Churn Rate %`, data labels on |
| Middle right | **Clustered column chart** | X-axis `accounts[num_products]`, Y-axis `Churn Rate %`, data labels on |
| Bottom left | **Clustered column chart** | X-axis `customers[age_band]`, Y-axis `Churn Rate %`, Legend `accounts[is_active]` |
| Bottom right | **Matrix** | Rows `customers[country]`, Columns `accounts[balance_band]`, Values `Churn Rate %`; conditional formatting → Background colour on `Churn Rate %` |
| Left side | 2 × **Slicer** | `customers[gender]`, `customers[credit_band]` |

Title text box: **"Why customers leave: 20.4% churn, 185.6M in balances lost"**.
Put the one-line finding under each chart as a text box (see the README findings).

## 4. Page 2 — "Data quality" (3 min)

One **Table** visual with all three columns of `data_quality_log`. Interviewers like seeing that cleaning was
recorded, not hidden.

## 5. Save and export (2 min)

- Save as `powerbi/bank_churn_dashboard.pbix`.
- **File → Export → Export to PDF** → `powerbi/bank_churn_dashboard.pdf`.
- Screenshot page 1 → `images/dashboard_powerbi.png`, and point the README image at it.

## Check before you call it done

- Card `Customers` shows **10,000** and `Churn Rate %` shows **20.4%**. If not, the relationship or a filter is wrong.
- Germany bar = **32.4%**, 3 products = **82.7%**, 4 products = **100%**.
- Matrix: Germany × 100K-150K = **39.1%**.
