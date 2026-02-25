#!/bin/bash
#SBATCH --job-name=12_abundance_derep
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=2-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=96G

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

# ===============================
# Directories
# ===============================
BASE="/home/jtay0094/MAGs/${COHORT}"
OUTDIR="${BASE}/binning/abundance_derep098"

ALN_QZA="${OUTDIR}/reads_to_derep098_mags.qza"
LENGTHS_QZA="${OUTDIR}/mags_derep098_lengths.qza"
ABUND_QZA="${OUTDIR}/mags_derep098_abundance.qza"

# ===============================
# Checks
# ===============================
[[ -f "$ALN_QZA" ]]     || { echo "ERROR: Missing $ALN_QZA" >&2; exit 1; }
[[ -f "$LENGTHS_QZA" ]] || { echo "ERROR: Missing $LENGTHS_QZA" >&2; exit 1; }

# ===============================
# Run (skip if exists)
# ===============================
if [[ -f "$ABUND_QZA" ]]; then
  echo "Abundance file already exists — skipping: $ABUND_QZA"
else
  mosh annotate estimate-abundance \
    --i-alignment-maps "$ALN_QZA" \
    --i-feature-lengths "$LENGTHS_QZA" \
    --o-abundances "$ABUND_QZA" \
    --verbose
fi

echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
echo "OUTPUT: $ABUND_QZA"
echo "================================================="
