# 04_second_language.py -- Q5: band table and Q3 figure redone in Python.
# Run from the repository root:  python scripts/04_second_language.py
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")                     # draw to file, no window needed
import matplotlib.pyplot as plt
from matplotlib.ticker import FixedLocator, NullLocator

# ---- Data: same steps as scripts/00_setup.R ----
person = pd.read_csv("data/pslm_person_subset.csv")
hh = pd.read_csv("data/pslm_hh_subset.csv",
                 usecols=["hhid", "hhweight", "prov_code", "urban_rural"])
df = person.merge(hh, on="hhid")

# Variant 3 = Sindh (3) urban (2); earners aged 15-64 with earnings > 0
e = df[(df.prov_code == 3) & (df.urban_rural == 2)
       & (df.age >= 15) & (df.age <= 64) & (df.earn_annual > 0)].copy()

e["band_lo"] = 15 + 5 * ((e.age - 15) // 5)
e["band"] = e.band_lo.astype(str) + "-" + (e.band_lo + 4).astype(str)
e["band_mid"] = e.band_lo + 2
e["wx"] = e.hhweight * e.earn_annual

# Weighted mean per band = sum(w*x) / sum(w)
bands = (e.groupby(["band_lo", "band", "band_mid"])
          .agg(n_earners=("age", "size"), sw=("hhweight", "sum"), swx=("wx", "sum"))
          .reset_index())
bands["wmean"] = bands.swx / bands.sw
bands["thin"] = bands.n_earners < 30
bands["weighted_mean_earnings"] = bands.wmean.round().astype(int)

table = bands[["band", "n_earners", "weighted_mean_earnings"]]
print(table.to_string(index=False))
table.to_csv("figures/band_table_python.csv", index=False)

top = bands.loc[bands.wmean.idxmax()]
print("\n25-29 weighted mean (Rs):",
      int(bands.loc[bands.band == "25-29", "weighted_mean_earnings"].iloc[0]))

# ---- Figure ----
rng = np.random.default_rng(346)
jit = rng.uniform(-0.4, 0.4, len(e))      # horizontal jitter, at most 0.4 years

fig, ax = plt.subplots(figsize=(9, 6))
ax.scatter(e.age + jit, e.earn_annual, s=8, alpha=0.15, color="grey",
           edgecolors="none")
ax.plot(bands.band_mid, bands.wmean, color="#C0392B", lw=2, zorder=3)
ax.scatter(bands.band_mid, bands.wmean, s=90, zorder=4, linewidths=1.8,
           edgecolors="#C0392B",
           facecolors=["white" if t else "#C0392B" for t in bands.thin])
ax.annotate(f"Peak: ages {top.band}\nmean Rs {top.wmean:,.0f}",
            xy=(top.band_mid, top.wmean * 1.15),
            xytext=(top.band_mid, top.wmean * 2.2),
            ha="center", color="#C0392B", fontweight="bold",
            arrowprops=dict(arrowstyle="-", color="#C0392B"))

# matplotlib's default log axis prints 10^4 etc. -- set rupee labels instead
ax.set_yscale("log")
ax.set_ylim(1e4, 1e7)
ticks = [1e4, 1e5, 1e6, 1e7]
ax.yaxis.set_major_locator(FixedLocator(ticks))
ax.yaxis.set_minor_locator(NullLocator())
ax.set_yticklabels([f"Rs {t:,.0f}" for t in ticks])
ax.set_xlim(14.5, 64.5)
ax.set_xticks(range(15, 66, 5))
ax.grid(color="#EBEBEB")
ax.set_axisbelow(True)
for s in ax.spines.values():
    s.set_visible(False)

ax.set_title(f"Mean earnings in urban Sindh rise with age and peak at "
             f"{top.band} (Rs {top.wmean:,.0f})", loc="left", fontweight="bold")
ax.set_xlabel("Age (years)")
ax.set_ylabel("Annual earnings (log scale)")
fig.text(0.01, 0.01,
         f"Source: PSLM 2019-20 person and household files. Sample: urban Sindh, "
         f"ages 15-64, annual earnings > 0 (n = {len(e):,}).\n"
         "Red markers: weighted mean earnings of each five-year age band (hhweight), "
         "at the band midpoint.\nHollow markers = thin bands (< 30 earners; none here). "
         "Grey points: individual earners, jittered by up to 0.4 years.",
         fontsize=8, color="#4D4D4D", va="bottom")
fig.subplots_adjust(left=0.17, bottom=0.2)
fig.savefig("figures/relationship_python.svg")
