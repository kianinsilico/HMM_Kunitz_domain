# Hidden Markov Model for the Kunitz‑type Protease Inhibitor Domain

This project aims to build a Hidden Markov Model (HMM) for the Kunitz-type (PF00014) protease inhibitor domain using structural data from the Protein Data Bank (PDB). The resulting model will be used to annotate homologous domains in external databases such as SwissProt.

---

## Data Preprocessing Pipeline

### PDB Query Details

The structural data was retrieved from the RCSB PDB using the following query constraints:

- **Annotation Identifier**: PF00014 (Kunitz domain)
- **Annotation Type**: Pfam
- **Experimental Method**: All
- **Resolution**: ≤ 3.0 Å
- **Polymer Entity Sequence Length**: Between 45 and 80 residues

A custom report was downloaded from the RCSB website including the following fields:
- Entry ID
- Polymer Entity ID
- Sequence
- Annotation Identifier
- Chain ID


This section documents the process used to retrieve, filter, and cluster structural domain sequences prior to model training.

### 1. Convert PDB Custom Report to FASTA

Extract Kunitz-domain sequences from the custom report downloaded from the RCSB PDB.

```bash
./scripts/01_csv_to_fasta.sh \
  data/raw_data/rcsb_pdb_custom_report_20250518061229.csv \
  data/raw_data/pdb_kunitz.fasta
```

- Filters for entries with Pfam ID `PF00014`
- Produces FASTA entries with format: `>PDBID_CHAIN`

---

### 2. Remove Redundancy with MMseqs2

Clusters the sequences to remove redundancy using a 90% identity threshold and 80% coverage.

```bash
./scripts/02_mmseqs_cluster.sh \
  data/raw_data/pdb_kunitz.fasta \
  data/raw_data/clusterRes \
  data/raw_data/tmp
```

- Outputs:
  - `clusterRes_rep_seq.fasta`: representative sequences
  - `clusterRes_cluster.tsv`: cluster mapping
  - `clusterRes_all_seqs.fasta`: all clustered sequences

---

### 3. Extract PDB IDs for PDBeFold

Formats representative PDB IDs to the `PDBID:CHAIN` format.

```bash
./scripts/03_extract_ids.sh \
  data/raw_data/clusterRes_rep_seq.fasta \
  data/raw_data/pdb_kunitz_rep_ids.txt
```

- Output example: `1ABC:A`, `2XYZ:B`

---

## File Overview

| File                                      | Description                                |
|-------------------------------------------|--------------------------------------------|
| `rcsb_pdb_custom_report_20250518061229.csv` | Raw CSV from RCSB with PF00014 structures |
| `pdb_kunitz.fasta`                        | Filtered FASTA containing all sequences    |
| `clusterRes_rep_seq.fasta`                | Clustered representative sequences         |
| `clusterRes_cluster.tsv`                  | Cluster info from MMseqs2                  |
| `pdb_kunitz_rep_ids.txt`                  | List of rep IDs in `PDBID:CHAIN` format    |

---

ℹ️ *Next step: Build and train the HMM model using the representative sequences.*