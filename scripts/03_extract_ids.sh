#!/bin/bash

# Extracts representative PDB IDs from clustered FASTA in PDB:CHAIN format
# Example: >1ABC_A → 1ABC:A

if [ $# -ne 2 ]; then
  echo "Usage: $0 <clustered_rep_seq.fasta> <output_ids.txt>"
  exit 1
fi

INPUT="$1"
OUTPUT="$2"

grep ">" "$INPUT" | tr -d ">" | tr "_" ":" > "$OUTPUT"

echo "PDB:CHAIN ID list written to $OUTPUT"
