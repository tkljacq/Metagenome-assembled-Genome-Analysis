#!/bin/bash
#SBATCH --job-name=08_derep098
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G

set -eo pipefail
echo "START: $(date)"

# ===============================
# User setting (EDIT THIS ONLY)
# ===============================
COHORT="REPLACE_ME"
THRESHOLD="0.98"

# ===============================
# Environment
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-moshpit-2025.7

# ===============================
# Paths
# ===============================
BASE="/home/jtay0094/MAGs/${COHORT}"

IN_MAGS="$BASE/binning/filtering/mags_filtered.qza"
BUSCO_RESULTS="$BASE/binning/busco/busco_results.qza"

OUT_DIR="$BASE/binning/derep_thr098"
mkdir -p "$OUT_DIR"

MINHASH_QZA="$OUT_DIR/min-hash.qza"
COMPARE_QZA="$OUT_DIR/min-hash-compare.qza"
DEREP_MAGS_QZA="$OUT_DIR/mags_derep.qza"
DEREP_TABLE_QZA="$OUT_DIR/table.qza"

# ===============================
# Checks
# ===============================
[[ -f "$IN_MAGS" ]] || { echo "ERROR: Missing $IN_MAGS" >&2; exit 1; }
[[ -f "$BUSCO_RESULTS" ]] || { echo "ERROR: Missing $BUSCO_RESULTS" >&2; exit 1; }

# ===============================
# Derep
# ===============================
qiime sourmash compute \
  --i-sequence-file "$IN_MAGS" \
  --p-ksizes 105 \
  --p-scaled 100 \
  --o-min-hash-signature "$MINHASH_QZA" \
  --verbose

qiime sourmash compare \
  --i-min-hash-signature "$MINHASH_QZA" \
  --p-ksize 105 \
  --o-compare-output "$COMPARE_QZA" \
  --verbose

qiime annotate dereplicate-mags \
  --i-mags "$IN_MAGS" \
  --i-distance-matrix "$COMPARE_QZA" \
  --m-metadata-file "$BUSCO_RESULTS" \
  --p-metadata-column completeness \
  --p-threshold "$THRESHOLD" \
  --o-dereplicated-mags "$DEREP_MAGS_QZA" \
  --o-table "$DEREP_TABLE_QZA" \
  --verbose

echo "END: $(date)"
echo "Derep MAGs: $DEREP_MAGS_QZA"
echo "Table: $DEREP_TABLE_QZA"
