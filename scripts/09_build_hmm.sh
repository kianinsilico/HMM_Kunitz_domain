#!/bin/bash

# 09_build_hmm.sh
# Usage: ./09_build_hmm.sh -i input.ali -o output.hmm

while getopts i:o: flag; do
    case "${flag}" in
        i) ali_file=${OPTARG};;
        o) hmm_file=${OPTARG};;
    esac
done

if [[ -z "$ali_file" || -z "$hmm_file" ]]; then
    echo "Usage: $0 -i input_alignment.ali -o output_model.hmm"
    exit 1
fi

# Convert .ali to aligned FASTA
aligned_fasta="${hmm_file%.hmm}.fasta"
awk '{if (substr($1,1,1)==">") {print "\n"toupper($1)} else {printf "%s",toupper($1)}}' "$ali_file" | \
    sed 's/PDB://g' | tail -n +2 > "$aligned_fasta"

# Build the HMM
hmmbuild "$hmm_file" "$aligned_fasta"
