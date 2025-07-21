#!/bin/bash

#USE: ./extract_chains.sh path/to/input.txt path/to/raw_pdb_dir path/to/output_dir

# === ARGUMENTS ===
INPUT_FILE="$1"
INPUT_DIR="$2"
OUTPUT_DIR="$3"

# === VALIDATION ===
if [[ ! -f "$INPUT_FILE" ]]; then
    echo " Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

if [[ ! -d "$INPUT_DIR" ]]; then
    echo " Error: Raw PDB directory '$INPUT_DIR' not found."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# === EXTRACT CHAINS ===
while IFS=: read -r pdbid chain; do
    full_pdb="${INPUT_DIR}/${pdbid}.pdb"
    output_pdb="${OUTPUT_DIR}/${pdbid}_${chain}.pdb"

    if [[ -f "$full_pdb" ]]; then
        echo " Extracting chain $chain from $pdbid"
        pdb_selchain -${chain} "$full_pdb" | pdb_tidy > "$output_pdb"
    else
        echo "⚠ Missing file: $full_pdb"
    fi
done < "$INPUT_FILE"
