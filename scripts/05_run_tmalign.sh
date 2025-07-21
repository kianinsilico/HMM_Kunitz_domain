#!/bin/bash

#USE: ./run_tmalign.sh path/to/pdbs

# === ARGUMENTS ===
PDB_DIR="$1"
RESULT_DIR="tmalign_results"

# === VALIDATION ===
if [[ ! -d "$PDB_DIR" ]]; then
    echo " Error: Directory '$PDB_DIR' not found."
    exit 1
fi

mkdir -p "$RESULT_DIR"
files=(${PDB_DIR}/*.pdb)

# === TM ALIGNMENT ===
for f1 in "${files[@]}"; do
    base1=$(basename "$f1" .pdb)
    for f2 in "${files[@]}"; do
        base2=$(basename "$f2" .pdb)
        if [[ "$base1" != "$base2" ]]; then
            out="${RESULT_DIR}/${base1}_vs_${base2}.txt"
            echo " Aligning $base1 vs $base2"
            TMalign "$f1" "$f2" > "$out"
        fi
    done
done
