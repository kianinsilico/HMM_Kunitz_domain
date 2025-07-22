#!/usr/bin/bash

cat rcsb_pdb_custom_report_20250518061229.csv | tr -d '"' \ 
#Take columns 4, 6, and 7 corresponding to sequence, chain, Annotation Identifier respectively from the custom report file.   
| awk -F ',' '{if (length($2)>0) {name=$2}; print name ,$4,$6,$7}'\
# Selecting lines that containing the desired identifier
|grep PF00014\
# creating the fasta format and saving the output in a file.
|awk '{print ">"$1"_"$3; print $2}' > pdb_kunitz.fasta
# MMseqs2 command that removes redundant entries and selects the best representative structures based on specified parameters
mmseqs easy-cluster pdb_kunitz.fasta output tmp --min-seq-id 0.9 -c 0.8

#creating a temporary list of ids to be used as input for MSA and MSS
grep ">" clusterRes_rep_seq.fasta |tr -d ">"|tr "_" ":" > ./tmp/pdb_kunitz_rep_ids.txt
