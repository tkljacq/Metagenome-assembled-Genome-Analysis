#!/bin/bash
#SBATCH --job-name=07_filterbusco_h1
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G

set -eo pipefail
echo "START: $(date)"

# ===============================
# User setting (EDIT THIS ONLY)
# ===============================
COHORT="REPLACE_ME"
MIN_COMPLETENESS=50
MAX_CONTAMINATION=10

# ===============================
# Environment
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-moshpit-2025.7

# ===============================
# Paths
# ===============================
BASE="/home/jtay0094/MAGs/${COHORT}"

MAGS_QZA="$BASE/binning/metabat/mags.qza"
BUSCO_RESULTS_QZA="$BASE/binning/busco/busco_results.qza"

OUT_DIR="$BASE/binning/filtering"
FILTERED_MAGS_QZA="$OUT_DIR/mags_filtered.qza"
CHECK_DIR="$OUT_DIR/filtered_export_check"

BUSCO_EXPORT_DIR="$OUT_DIR/busco_export_for_filter"
BUSCO_TSV="$BUSCO_EXPORT_DIR/busco_results.tsv"

WHERE_CLAUSE="completeness>=${MIN_COMPLETENESS} AND contamination<=${MAX_CONTAMINATION}"

# ===============================
# Checks
# ===============================
[[ -f "$MAGS_QZA" ]] || { echo "ERROR: Missing $MAGS_QZA" >&2; exit 1; }
[[ -f "$BUSCO_RESULTS_QZA" ]] || { echo "ERROR: Missing $BUSCO_RESULTS_QZA" >&2; exit 1; }

mkdir -p "$OUT_DIR"

# Remove stale outputs
rm -f "$FILTERED_MAGS_QZA"
rm -rf "$CHECK_DIR" "$BUSCO_EXPORT_DIR"

# ===============================
# Export BUSCO metadata
# ===============================
qiime tools export \
  --input-path "$BUSCO_RESULTS_QZA" \
  --output-path "$BUSCO_EXPORT_DIR"

[[ -f "$BUSCO_TSV" ]] || { echo "ERROR: Missing exported BUSCO TSV: $BUSCO_TSV" >&2; exit 1; }

# Rename first metadata column to a QIIME-recognized ID header
sed -i '1 s/^mag_id\t/id\t/' "$BUSCO_TSV"

# ===============================
# Filter
# ===============================
qiime annotate filter-mags \
  --i-mags "$MAGS_QZA" \
  --m-metadata-file "$BUSCO_TSV" \
  --p-where "$WHERE_CLAUSE" \
  --p-no-exclude-ids \
  --p-on mag \
  --o-filtered-mags "$FILTERED_MAGS_QZA" \
  --verbose

# ===============================
# Sanity check: count FASTAs
# ===============================
qiime tools export \
  --input-path "$FILTERED_MAGS_QZA" \
  --output-path "$CHECK_DIR"

echo -n "Filtered FASTA count: "
find "$CHECK_DIR" -type f -name "*.fasta" | wc -l

echo "END: $(date)"
echo "Filtered MAGs: $FILTERED_MAGS_QZA"
