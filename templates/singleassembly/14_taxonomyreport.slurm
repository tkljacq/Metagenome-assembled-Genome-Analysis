#!/bin/bash
#SBATCH --job-name=14_kraken2_to_tax
#SBATCH --partition=cpu1
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G

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
# Inputs / Outputs
# ===============================
BASE="/home/jtay0094/MAGs/${COHORT}/taxonomy/kraken2_pluspf_derep098"

REPORTS="${BASE}/kraken2-reports-mags.qza"
OUTPUTS="${BASE}/kraken2-hits-mags.qza"
TAX_OUT="${BASE}/mags-taxonomy.qza"

# ===============================
# Checks
# ===============================
[[ -f "$REPORTS" ]] || { echo "ERROR: Missing $REPORTS" >&2; exit 1; }
[[ -f "$OUTPUTS" ]] || { echo "ERROR: Missing $OUTPUTS" >&2; exit 1; }

# ===============================
# Run (skip if exists)
# ===============================
if [[ -f "$TAX_OUT" ]]; then
  echo "Taxonomy artifact already exists — skipping: $TAX_OUT"
else
  mosh annotate kraken2-to-mag-features \
    --i-reports "$REPORTS" \
    --i-outputs "$OUTPUTS" \
    --o-taxonomy "$TAX_OUT" \
    --verbose
fi

echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
echo "OUTPUT: $TAX_OUT"
echo "================================================="
