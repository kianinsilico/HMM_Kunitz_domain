#!/bin/bash

# Runs MMseqs2 easy-cluster on input FASTA
# Outputs:
#   <output_prefix>_rep_seq.fasta
#   <output_prefix>_all_seqs.fasta
#   <output_prefix>_cluster.tsv

if [ $# -ne 3 ]; then
  echo "Usage: $0 <input.fasta> <output_prefix> <tmp_dir>"
  exit 1
fi

INPUT="$1"
OUTPUT="$2"
TMP="$3"

mmseqs easy-cluster "$INPUT" "$OUTPUT" "$TMP" --min-seq-id 0.9 -c 0.8

echo "Clustering complete:"
echo "  - Representative sequences: ${OUTPUT}_rep_seq.fasta"
echo "  - Cluster mapping: ${OUTPUT}_cluster.tsv"
