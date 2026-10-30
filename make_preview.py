"""Render a static preview of the dashboard from the SQLite model (run run_pipeline.py first)."""
import sqlite3
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).parent
con = sqlite3.connect(ROOT / "bank_churn.db")
q = lambda sql: pd.read_sql(sql, con)

kpi = q("""SELECT COUNT(*) n, 100.0*AVG(churned) rate,
           SUM(CASE WHEN churned=1 THEN balance END)/1e6 lost FROM churn_base""").iloc[0]
targets = q("""SELECT COUNT(*) n FROM churn_base WHERE churned=0 AND is_active=0
               AND age BETWEEN 40 AND 59 AND balance>0""").iloc[0]
country = q("SELECT country, 100.0*AVG(churned) rate FROM churn_base GROUP BY country ORDER BY rate")
products = q("SELECT num_products, 100.0*AVG(churned) rate FROM churn_base GROUP BY num_products")
age = q("""SELECT age_band, is_active, 100.0*AVG(churned) rate FROM churn_base
           WHERE age_band <> 'Unknown' GROUP BY age_band, is_active""")
matrix = q("SELECT country, balance_band, 100.0*AVG(churned) rate FROM churn_base GROUP BY country, balance_band")
con.close()

INK, MUTED, BLUE, RED = "#1F2937", "#6B7280", "#2563EB", "#DC2626"
plt.rcParams.update({"font.family": "Segoe UI", "font.size": 9, "axes.spines.top": False,
                     "axes.spines.right": False, "axes.edgecolor": "#D1D5DB"})
fig = plt.figure(figsize=(14, 8.2), facecolor="white")
fig.suptitle(f"Why customers leave: {kpi.rate:.1f}% churn, {kpi.lost:.1f}M in balances lost",
             x=0.04, ha="left", fontsize=16, fontweight="bold", color=INK)
gs = fig.add_gridspec(3, 4, height_ratios=[0.45, 1, 1], hspace=0.55, wspace=0.35,
                      left=0.065, right=0.98, top=0.89, bottom=0.07)

cards = [("Customers", f"{int(kpi.n):,}"), ("Churn rate", f"{kpi.rate:.1f}%"),
         ("Balance lost", f"{kpi.lost:.1f}M"), ("Retention targets", f"{int(targets.n):,}")]
for i, (label, value) in enumerate(cards):
    ax = fig.add_subplot(gs[0, i]); ax.axis("off")
    ax.add_patch(plt.Rectangle((0, 0), 1, 1, transform=ax.transAxes, color="#F3F4F6"))
    ax.text(0.06, 0.62, value, fontsize=20, fontweight="bold", color=INK, transform=ax.transAxes)
    ax.text(0.06, 0.2, label, fontsize=10, color=MUTED, transform=ax.transAxes)


def finish(ax, title, note):
    ax.set_title(title, loc="left", fontsize=11, fontweight="bold", color=INK)
    ax.text(0, -0.28, note, transform=ax.transAxes, fontsize=8.5, color=MUTED)


ax = fig.add_subplot(gs[1, :2])
bars = ax.barh(country.country, country.rate, color=[BLUE if c != "Germany" else RED for c in country.country])
ax.bar_label(bars, fmt="%.1f%%", padding=3); ax.set_xlabel("Churn rate %")
finish(ax, "Churn rate by country", "Germany churns at twice the rate of France and Spain.")

ax = fig.add_subplot(gs[1, 2:])
bars = ax.bar(products.num_products.astype(str), products.rate,
              color=[RED if n >= 3 else BLUE for n in products.num_products])
ax.bar_label(bars, fmt="%.1f%%", padding=2); ax.set_xlabel("Number of products held"); ax.set_ylim(0, 112)
finish(ax, "Churn rate by number of products", "2 products is the sweet spot; 3-4 products churn 83-100%.")

ax = fig.add_subplot(gs[2, :2])
p = age.pivot(index="age_band", columns="is_active", values="rate")
x = range(len(p)); w = 0.38
ax.bar([i - w / 2 for i in x], p[0], w, label="Inactive", color=RED)
ax.bar([i + w / 2 for i in x], p[1], w, label="Active", color=BLUE)
ax.set_xticks(list(x), p.index); ax.set_ylabel("Churn rate %"); ax.legend(frameon=False)
finish(ax, "Churn rate by age band and activity", "Inactive 50-59s churn 81%; staying active cuts it to 37%.")

ax = fig.add_subplot(gs[2, 2:])
m = matrix.pivot(index="country", columns="balance_band", values="rate")
im = ax.imshow(m.values, cmap="Reds", vmin=0, vmax=45, aspect="auto")
ax.set_xticks(range(m.shape[1]), [c[2:] for c in m.columns]); ax.set_yticks(range(m.shape[0]), m.index)
for (r, c), v in pd.DataFrame(m.values).stack().items():
    ax.text(c, r, f"{v:.1f}%", ha="center", va="center", color="white" if v > 30 else INK)
for (r, c) in [(r, c) for r in range(m.shape[0]) for c in range(m.shape[1]) if pd.isna(m.values[r, c])]:
    ax.text(c, r, "no customers", ha="center", va="center", color=MUTED, fontsize=8)
ax.spines[:].set_visible(False)
finish(ax, "Churn rate: country x balance", "Germany's gap sits in one band: 100K-150K balances churn 39%.")

out = ROOT / "images/dashboard_preview.png"
fig.savefig(out, dpi=130)
print("saved", out)
