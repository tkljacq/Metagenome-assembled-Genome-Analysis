#!/bin/bash
#SBATCH --job-name=derep
#SBATCH --partition=cpu1.largem
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G

set -eo pipefail

# ===============================
# User setting (EDIT THIS ONLY)
# ===============================
COHORT="healthy1"

# ===============================
# Environment
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-moshpit-2025.7

BASE="/home/jtay0094/MAGs/${COHORT}"

# ===============================
# Inputs
# ===============================
IN_MAGS="${BASE}/binning/filtering/mags_filtered.qza"
BUSCO_RESULTS="${BASE}/binning/busco/busco_results.qza"

# ===============================
# Outputs
# ===============================
OUT_DIR="${BASE}/binning/derep"
mkdir -p "$OUT_DIR"

MINHASH_QZA="${OUT_DIR}/min-hash.qza"
COMPARE_QZA="${OUT_DIR}/min-hash-compare.qza"
DEREP_MAGS_QZA="${OUT_DIR}/mags_derep.qza"
DEREP_TABLE_QZA="${OUT_DIR}/table.qza"

# ===============================
# Checks
# ===============================
[[ -f "$IN_MAGS" ]] || { echo "ERROR: Missing $IN_MAGS" >&2; exit 1; }
[[ -f "$BUSCO_RESULTS" ]] || { echo "ERROR: Missing $BUSCO_RESULTS" >&2; exit 1; }

# ===============================
# 1) Compute MinHash
# ===============================
qiime sourmash compute \
  --i-sequence-file "$IN_MAGS" \
  --p-ksizes 105 \
  --p-scaled 100 \
  --o-min-hash-signature "$MINHASH_QZA" \
  --verbose

# ===============================
# 2) Compare
# ===============================
qiime sourmash compare \
  --i-min-hash-signature "$MINHASH_QZA" \
  --p-ksize 105 \
  --o-compare-output "$COMPARE_QZA" \
  --verbose

# ===============================
# 3) Dereplicate (keep best by completeness)
# ===============================
qiime annotate dereplicate-mags \
  --i-mags "$IN_MAGS" \
  --i-distance-matrix "$COMPARE_QZA" \
  --m-metadata-file "$BUSCO_RESULTS" \
  --p-metadata-column completeness \
  --p-threshold 0.9 \
  --o-dereplicated-mags "$DEREP_MAGS_QZA" \
  --o-table "$DEREP_TABLE_QZA" \
  --verbose

echo "Done."
echo "Dereplicated MAGs: $DEREP_MAGS_QZA"
echo "Derep table:       $DEREP_TABLE_QZA"

