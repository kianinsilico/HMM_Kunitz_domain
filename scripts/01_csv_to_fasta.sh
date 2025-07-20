#!/bin/bash

# Converts a RCSB custom report CSV file to FASTA format.
# Assumes columns: $1 = Entry ID, $2 = ??? (optional), $4 = Sequence, $6 = Chain, $7 = Annotation Identifier
# Filters only sequences annotated with PF00014

if [ $# -ne 2 ]; then
  echo "Usage: $0 <input.csv> <output.fasta>"
  exit 1
fi

INPUT="$1"
OUTPUT="$2"

cat "$INPUT" | tr -d '"' \
| awk -F ',' '{if (length($2)>0) {name=$2}; print name, $4, $6, $7}' \
| grep PF00014 \
| awk '{print ">" $1 "_" $3; print $2}' > "$OUTPUT"

echo "FASTA saved to $OUTPUT"
