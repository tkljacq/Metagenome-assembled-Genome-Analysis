#!/bin/bash
#SBATCH --job-name=filtermag
#SBATCH --partition=cpu1.largem
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G

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
MAGS_QZA="${BASE}/binning/metabat/mags.qza"
BUSCO_RESULTS_QZA="${BASE}/binning/busco/busco_results.qza"

# ===============================
# Output
# ===============================
OUT_DIR="${BASE}/binning/filtering"
mkdir -p "$OUT_DIR"

FILTERED_MAGS_QZA="${OUT_DIR}/mags_filtered.qza"

# Tutorial-style MQ filter:
# completeness >= 50 AND contamination <= 10
WHERE_CLAUSE="completeness>=50 AND contamination<=10"

# ===============================
# Checks
# ===============================
[[ -f "$MAGS_QZA" ]] || { echo "ERROR: Missing $MAGS_QZA" >&2; exit 1; }
[[ -f "$BUSCO_RESULTS_QZA" ]] || { echo "ERROR: Missing $BUSCO_RESULTS_QZA" >&2; exit 1; }

# ===============================
# Filter
# ===============================
qiime annotate filter-mags \
  --i-mags "$MAGS_QZA" \
  --m-metadata-file "$BUSCO_RESULTS_QZA" \
  --p-where "$WHERE_CLAUSE" \
  --p-no-exclude-ids \
  --p-on mag \
  --o-filtered-mags "$FILTERED_MAGS_QZA" \
  --verbose

echo "Done."
echo "Filtered MAGs: $FILTERED_MAGS_QZA"

