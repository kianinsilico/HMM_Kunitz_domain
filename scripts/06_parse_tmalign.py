import os
import re
import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# === Parse Arguments ===
parser = argparse.ArgumentParser(description="Parse TM-align results and generate RMSD/TM-score matrices")
parser.add_argument("-i", "--input", required=True, help="Directory with TM-align result files (*.txt)")
parser.add_argument("-p", "--prefix", default="tmalign_qc", help="Prefix for output files")
args = parser.parse_args()

tm_dir = args.input
prefix = args.prefix

# === Utilities ===
def extract_pair(filename):
    return os.path.splitext(filename)[0].split("_vs_")

def extract_metrics(path):
    with open(path) as f:
        content = f.read()
        tm_match = re.search(r"TM-score=\s*([0-9.]+)\s+\(if normalized by length of Chain_1", content)
        rmsd_match = re.search(r"RMSD=\s*([0-9.]+)", content)
        tm = float(tm_match.group(1)) if tm_match else None
        rmsd = float(rmsd_match.group(1)) if rmsd_match else None
        return tm, rmsd

# === Collect structure names ===
files = [f for f in os.listdir(tm_dir) if f.endswith(".txt")]
structures = set()
for f in files:
    s1, s2 = extract_pair(f)
    structures.update([s1, s2])
structures = sorted(structures)

# === Initialize matrices ===
tm_df = pd.DataFrame(index=structures, columns=structures, dtype=float)
rmsd_df = pd.DataFrame(index=structures, columns=structures, dtype=float)

for f in files:
    s1, s2 = extract_pair(f)
    tm, rmsd = extract_metrics(os.path.join(tm_dir, f))
    if tm is not None:
        tm_df.loc[s1, s2] = tm
        tm_df.loc[s2, s1] = tm
    if rmsd is not None:
        rmsd_df.loc[s1, s2] = rmsd
        rmsd_df.loc[s2, s1] = rmsd

np.fill_diagonal(tm_df.values, 1.0)
np.fill_diagonal(rmsd_df.values, 0.0)

# === Ranking ===
tm_avg = tm_df.mean(axis=1).sort_values(ascending=False).reset_index()
tm_avg.columns = ["Structure", "Average TM-score"]
rmsd_avg = rmsd_df.mean(axis=1).sort_values().reset_index()
rmsd_avg.columns = ["Structure", "Average RMSD"]

# === Output files ===
tm_df.to_csv(f"{prefix}_tm_matrix.csv", float_format="%.4f")
rmsd_df.to_csv(f"{prefix}_rmsd_matrix.csv", float_format="%.4f")
tm_avg.to_csv(f"{prefix}_tm_ranking.csv", index=False)
rmsd_avg.to_csv(f"{prefix}_rmsd_ranking.csv", index=False)

# === Heatmaps ===
plt.figure(figsize=(12, 10))
sns.heatmap(tm_df, cmap="viridis", xticklabels=True, yticklabels=True)
plt.title("TM-score Matrix")
plt.tight_layout()
plt.savefig(f"{prefix}_tm_heatmap.png", dpi=300)
plt.close()

plt.figure(figsize=(12, 10))
sns.heatmap(rmsd_df, cmap="magma_r", xticklabels=True, yticklabels=True)
plt.title("RMSD Matrix")
plt.tight_layout()
plt.savefig(f"{prefix}_rmsd_heatmap.png", dpi=300)
plt.close()

print(" TM-align parsing complete.")
