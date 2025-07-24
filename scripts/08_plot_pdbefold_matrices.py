#!/usr/bin/env python3
import re
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import argparse
from pathlib import Path
from collections import OrderedDict

def parse_matrix_block(lines, start_idx):
    """
    Parses a multi-segment cross-structure statistics block (RMSD, Q-score, or Sequence Identity)
    from a PDBeFold metrics.txt file. Returns a square DataFrame indexed and columned by PDB IDs.
    """
    idx = start_idx + 1
    col_labels = []
    row_values = OrderedDict()
    first_segment = True

    while True:
        # Advance to 'Structure' header or next block
        while idx < len(lines) and not lines[idx].strip().startswith('Structure'):
            if lines[idx].strip().startswith('<<') and idx != start_idx+1:
                # End of block
                df = pd.DataFrame.from_dict(row_values, orient='index', columns=col_labels)
                pdb_ids = list(row_values.keys())
                mapping = {str(i+1): pdb_ids[i] for i in range(len(pdb_ids))}
                df = df.rename(columns=mapping, index=mapping)
                return df, idx
            idx += 1

        if idx >= len(lines) or lines[idx].strip().startswith('<<'):
            break

        # Read header labels
        header_line = lines[idx]
        labels = re.findall(r'\b\d+\b', header_line)
        col_labels.extend(labels)
        idx += 2  # skip header and dashed line

        # Read the segment's rows
        temp_ids = []
        temp_vals = []
        while idx < len(lines):
            line = lines[idx]
            if not line.strip() or line.strip().startswith('Structure') or line.strip().startswith('<<'):
                break
            m = re.match(r'\s*(\d+)\.\s+PDB\s+(\S+)', line)
            if m:
                row_num = int(m.group(1))
                pdbid = m.group(2)
                vals = re.findall(r'\d+\.\d+', line)
                # Pad missing diagonal entry as 0.0
                if len(vals) < len(labels):
                    try:
                        pad_pos = labels.index(str(row_num))
                    except ValueError:
                        pad_pos = 0
                    vals.insert(pad_pos, '0.0')
                temp_ids.append(pdbid)
                temp_vals.append([float(v) for v in vals])
            idx += 1

        # Integrate this segment
        if first_segment:
            for rid, vals in zip(temp_ids, temp_vals):
                row_values[rid] = vals.copy()
            first_segment = False
        else:
            for rid, vals in zip(temp_ids, temp_vals):
                row_values[rid].extend(vals)

    # Build final DataFrame if loop exits
    df = pd.DataFrame.from_dict(row_values, orient='index', columns=col_labels)
    pdb_ids = list(row_values.keys())
    mapping = {str(i+1): pdb_ids[i] for i in range(len(pdb_ids))}
    df = df.rename(columns=mapping, index=mapping)
    return df, idx

def parse_all_matrices(file_path):
    """
    Finds and parses RMSD, Q-score, and Sequence Identity blocks.
    Returns a dict of DataFrames.
    """
    lines = Path(file_path).read_text().splitlines()
    matrices = {}
    for block in ['<< RMSD >>', '<< Q-score >>', '<< Sequence Identity >>']:
        for i, L in enumerate(lines):
            if block in L:
                df, _ = parse_matrix_block(lines, i)
                key = block.strip('<> ').strip()
                matrices[key] = df
                break
    return matrices

def plot_heatmap(df, title, out_path, cmap):
    """
    Plots a square DataFrame as a heatmap with annotations.
    """
    plt.figure(figsize=(10, 8))
    sns.heatmap(
        df,
        annot=True,
        fmt=".3f",
        cmap=cmap,
        annot_kws={"size": 6},
        cbar_kws={"shrink": 0.6})    
    plt.title(title)
    plt.tight_layout()
    plt.savefig(out_path, dpi=300)
    plt.close()

def main():
    p = argparse.ArgumentParser(
        description="Extract & plot PDBeFold cross-structure matrices"
    )
    p.add_argument("-i", "--input", required=True,
                   help="Path to PDBeFold metrics.txt")
    p.add_argument("-o", "--outdir", required=True,
                   help="Directory to save CSVs and PNGs")
    args = p.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    matrices = parse_all_matrices(args.input)
    print("Found blocks:", list(matrices.keys()))
    for name, df in matrices.items():
        print(f"  → {name}: {df.shape}")
        # Save CSV
        csv_path = outdir / f"{name.replace(' ', '_')}.csv"
        df.to_csv(csv_path, float_format="%.4f")
        # Plot heatmap
        cmap = "Reds" if name=="RMSD" else "Blues" if name=="Q-score" else "Greens"
        png_path = outdir / f"{name.replace(' ', '_')}_matrix.png"
        plot_heatmap(df, f"{name} Matrix", png_path, cmap)

if __name__ == "__main__":
    main()
