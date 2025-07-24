#!/bin/bash

# Default threshold value
THRESHOLD="1e-5"
# Default Python scripts path (current directory)
PYTHON_SCRIPTS_PATH="."

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--threshold)
            THRESHOLD="$2"
            shift 2
            ;;
        -p|--python-path)
            PYTHON_SCRIPTS_PATH="$2"
            shift 2
            ;;
        -h|--help)
            echo "12_evaluate_model.sh - 2-Fold Cross-Validation HMM Model Evaluation"
            echo ""
            echo "DESCRIPTION:"
            echo "  This script performs comprehensive evaluation of Hidden Markov Model (HMM) performance"
            echo "  using 2-fold cross-validation. It combines input FASTA files, removes overlapping"
            echo "  sequences with training data, splits the dataset into positive and negative sets,"
            echo "  and evaluates model performance using hmmsearch with configurable E-value thresholds."
            echo ""
            echo "WORKFLOW:"
            echo "  1. Combines input FASTA files into a unified dataset"
            echo "  2. Builds BLAST database and removes training sequence overlaps"
            echo "  3. Prepares positive (Kunitz) and negative (SwissProt) sequence sets"
            echo "  4. Performs random 2-fold split for cross-validation"
            echo "  5. Runs hmmsearch against HMM model"
            echo "  6. Converts results to classification format"
            echo "  7. Evaluates performance metrics (MCC, TPR, PPV) at specified threshold"
            echo "  8. Performs threshold sweep analysis (1e-1 to 1e-10)"
            echo ""
            echo "USAGE:"
            echo "  $0 [OPTIONS] <input_file1.fasta> [input_file2.fasta] [input_file3.fasta] ..."
            echo ""
            echo "OPTIONS:"
            echo "  -t, --threshold THRESHOLD    Set E-value threshold for performance evaluation (default: 1e-5)"
            echo "  -p, --python-path PATH       Path to directory containing Python scripts (default: current directory)"
            echo "  -h, --help                   Show this help message"
            echo ""
            echo "EXAMPLES:"
            echo "  $0 human_kunitz.fasta nothuman_kunitz.fasta"
            echo "  $0 -t 1e-6 human_kunitz.fasta nothuman_kunitz.fasta"
            echo "  $0 --threshold 1e-4 *.fasta"
            echo "  $0 -p /path/to/scripts -t 1e-6 human_kunitz.fasta nothuman_kunitz.fasta"
            echo ""
            echo "REQUIREMENTS:"
            echo "  - BLAST+ tools (makeblastdb, blastp)"
            echo "  - HMMER (hmmsearch)"
            echo "  - Python 3 with get_seq.py and performance.py scripts"
            echo "  - Input files: pdb_kunitz_rp.fasta, kunitz_model.hmm, uniprot_sprot.fasta"
            echo ""
            echo "OUTPUT FILES:"
            echo "  - results_set_1.txt, results_set_2.txt: Performance metrics at specified threshold"
            echo "  - diff_threshold_set1.txt, diff_threshold_set2.txt: Threshold sweep results"
            echo "  - Various intermediate files (.ids, .fasta, .class, .out)"
            exit 0
            ;;
        -*)
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Check if at least one input file is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 [OPTIONS] <input_file1.fasta> [input_file2.fasta] [input_file3.fasta] ..."
    echo "Use -h or --help for more information"
    exit 1
fi

echo "[INFO] Starting 2-fold cross-validation HMM model testing..."
echo "[INFO] Input files: $@"
echo "[INFO] Using E-value threshold: $THRESHOLD"
echo "[INFO] Python scripts path: $PYTHON_SCRIPTS_PATH"

echo "[STEP 1] Create combined dataset from input files..."
cat "$@" > all_kunitz_uniprot.fasta
echo "[INFO] Combined $(echo "$@" | wc -w) input files into all_kunitz_uniprot.fasta"

echo "[STEP 2] Build BLAST database from combined dataset..."
makeblastdb -in all_kunitz_uniprot.fasta -dbtype prot -out all_kunitz_uniprot.fasta

echo "[STEP 3] Run BLAST of training sequences vs combined dataset..."
blastp -query pdb_kunitz_rp.fasta -db all_kunitz_uniprot.fasta -out pdb_kunitz.blast -outfmt 7

echo "[STEP 4] Remove overlapping sequences from test pool..."
grep -v "^#" pdb_kunitz.blast | awk '{if ($3 >= 95 && $4 >= 50) print $2}' | sort -u | cut -d "|" -f 2 > to_remove.ids
grep ">" all_kunitz_uniprot.fasta | cut -d "|" -f 2 > all_kunitz.id
comm -23 <(sort all_kunitz.id) <(sort to_remove.ids) > to_keep.ids

echo "[STEP 5] Prepare sequences using get_seq.py..."
python3 "$PYTHON_SCRIPTS_PATH/get_seq.py" to_keep.ids all_kunitz_uniprot.fasta ok_kunitz.fasta
grep ">" uniprot_sprot.fasta | cut -d "|" -f 2 > sp.id
comm -23 <(sort sp.id) <(sort all_kunitz.id) > sp_negs.ids
python3 "$PYTHON_SCRIPTS_PATH/get_seq.py" sp_negs.ids uniprot_sprot.fasta sp_negs.fasta

echo "[STEP 6] Random split into 2 folds..."
sort -R sp_negs.ids > random_sp_negs.ids
sort -R to_keep.ids > random_ok_kunitz.ids

head -n 184 random_ok_kunitz.ids > pos_1.ids
tail -n 184 random_ok_kunitz.ids > pos_2.ids
head -n 286417 random_sp_negs.ids > neg_1.ids
tail -n 286417 random_sp_negs.ids > neg_2.ids

python3 "$PYTHON_SCRIPTS_PATH/get_seq.py" pos_1.ids uniprot_sprot.fasta pos_1.fasta
python3 "$PYTHON_SCRIPTS_PATH/get_seq.py" pos_2.ids uniprot_sprot.fasta pos_2.fasta
python3 "$PYTHON_SCRIPTS_PATH/get_seq.py" neg_1.ids uniprot_sprot.fasta neg_1.fasta
python3 "$PYTHON_SCRIPTS_PATH/get_seq.py" neg_2.ids uniprot_sprot.fasta neg_2.fasta

echo "[STEP 7] Run hmmsearch against HMM..."
hmmsearch -Z 1000 --max --tblout pos_1.out kunitz_model.hmm pos_1.fasta
hmmsearch -Z 1000 --max --tblout pos_2.out kunitz_model.hmm pos_2.fasta
hmmsearch -Z 1000 --max --tblout neg_1.out kunitz_model.hmm neg_1.fasta
hmmsearch -Z 1000 --max --tblout neg_2.out kunitz_model.hmm neg_2.fasta

echo "[STEP 8] Convert to .class format..."
grep -v "^#" pos_1.out | awk '{split($1,a,"|"); print a[2]"\t1\t"$5"\t"$8}' > pos_1.class
grep -v "^#" pos_2.out | awk '{split($1,a,"|"); print a[2]"\t1\t"$5"\t"$8}' > pos_2.class
grep -v "^#" neg_1.out | awk '{split($1,a,"|"); print a[2]"\t0\t"$5"\t"$8}' > neg_1.class
grep -v "^#" neg_2.out | awk '{split($1,a,"|"); print a[2]"\t0\t"$5"\t"$8}' > neg_2.class

comm -23 <(sort neg_1.ids) <(cut -f1 neg_1.class | sort) | awk '{print $1"\t0\t10.0\t10.0"}' >> neg_1.class
comm -23 <(sort neg_2.ids) <(cut -f1 neg_2.class | sort) | awk '{print $1"\t0\t10.0\t10.0"}' >> neg_2.class

cat pos_1.class neg_1.class > set_1.class
cat pos_2.class neg_2.class > set_2.class

echo "[STEP 9] Run performance.py with threshold = $THRESHOLD..."
python3 "$PYTHON_SCRIPTS_PATH/performance.py" set_1.class $THRESHOLD > results_set_1.txt
python3 "$PYTHON_SCRIPTS_PATH/performance.py" set_2.class $THRESHOLD > results_set_2.txt

echo "[STEP 10] Sweep multiple thresholds..."
for i in $(seq 1 10); do
  python3 "$PYTHON_SCRIPTS_PATH/performance.py" set_1.class 1e-$i
done > diff_threshold_set1.txt
for i in $(seq 1 10); do
  python3 "$PYTHON_SCRIPTS_PATH/performance.py" set_2.class 1e-$i
done > diff_threshold_set2.txt
