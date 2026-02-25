#!/bin/bash
#SBATCH --job-name=09_len_derep098
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G

set -eo pipefail
echo "START: $(date)"

# ===============================
# User setting (EDIT THIS ONLY)
# ===============================
COHORT="REPLACE_ME"

# ===============================
# Environment
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-moshpit-2025.7

# ===============================
# Paths
# ===============================
BASE="/home/jtay0094/MAGs/${COHORT}"
MAGS_SD="$BASE/binning/derep_thr098/mags_derep_sampledata.qza"

OUTDIR="$BASE/binning/abundance_derep098"
mkdir -p "$OUTDIR"

LENGTHS_QZA="$OUTDIR/mags_derep098_lengths.qza"

# ===============================
# Checks
# ===============================
[[ -f "$MAGS_SD" ]] || { echo "ERROR: Missing $MAGS_SD" >&2; exit 1; }

# ===============================
# Run
# ===============================
if [[ -f "$LENGTHS_QZA" ]]; then
  echo "Lengths already exist — skipping: $LENGTHS_QZA"
  echo "END: $(date)"
  exit 0
fi

mosh annotate get-feature-lengths \
  --i-features "$MAGS_SD" \
  --o-lengths "$LENGTHS_QZA" \
  --verbose

echo "END: $(date)"
echo "Lengths: $LENGTHS_QZA"
