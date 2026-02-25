#!/bin/bash
#SBATCH --job-name=11_mapreadsto_derepmags
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=8-00:00:00
#SBATCH --cpus-per-task=6
#SBATCH --mem=112G

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
# Inputs / Outputs
# ===============================
BASE="/home/jtay0094/MAGs/${COHORT}"

READS_QZA="${BASE}/assembly/indexmapping/reads.qza"

OUTDIR="${BASE}/binning/abundance_derep098"
INDEX_QZA="${OUTDIR}/mags_derep098_index.qza"
ALN_QZA="${OUTDIR}/reads_to_derep098_mags.qza"

# ===============================
# Checks
# ===============================
[[ -f "$INDEX_QZA" ]] || { echo "ERROR: Missing $INDEX_QZA (run index job first)" >&2; exit 1; }
[[ -f "$READS_QZA" ]] || { echo "ERROR: Missing $READS_QZA" >&2; exit 1; }

# ===============================
# Run (skip if exists)
# ===============================
if [[ -f "$ALN_QZA" ]]; then
  echo "Alignment already exists — skipping: $ALN_QZA"
else
  mosh assembly map-reads \
    --i-index "$INDEX_QZA" \
    --i-reads "$READS_QZA" \
    --p-threads "$THREADS" \
    --p-seed "$SEED" \
    --o-alignment-maps "$ALN_QZA" \
    --verbose
fi

echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
echo "OUTPUT: $ALN_QZA"
echo "================================================="
