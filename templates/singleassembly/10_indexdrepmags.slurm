#!/bin/bash
#SBATCH --job-name=10_index_derep
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=2-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G

set -eo pipefail

echo "================================================="
echo "START: $(date '+%Y-%m-%d %H:%M:%S')"
echo "JOB: ${SLURM_JOB_NAME}  ID: ${SLURM_JOB_ID}"
echo "NODE: $(hostname)"
echo "================================================="

# ===============================
# User setting (EDIT THIS ONLY)
# ===============================
COHORT="healthy1"

# ===============================
# Environment
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-moshpit-2025.7

THREADS="${SLURM_CPUS_PER_TASK}"
SEED="100"

# ===============================
# Directories
# ===============================
BASE="/home/jtay0094/MAGs/${COHORT}"

MAGS="${BASE}/binning/derep_thr098/mags_derep.qza"
OUTDIR="${BASE}/binning/abundance_derep098"
mkdir -p "$OUTDIR"

INDEX_QZA="${OUTDIR}/mags_derep098_index.qza"

# ===============================
# Checks
# ===============================
[[ -f "$MAGS" ]] || { echo "ERROR: Missing $MAGS" >&2; exit 1; }

# ===============================
# Run (skip if exists)
# ===============================
if [[ -f "$INDEX_QZA" ]]; then
  echo "Index already exists — skipping: $INDEX_QZA"
else
  mosh assembly index-derep-mags \
    --i-mags "$MAGS" \
    --p-threads "$THREADS" \
    --p-seed "$SEED" \
    --o-index "$INDEX_QZA" \
    --verbose
fi

echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
echo "OUTPUT: $INDEX_QZA"
echo "================================================="
