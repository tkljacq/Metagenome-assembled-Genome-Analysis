#!/bin/bash
#SBATCH --job-name=15_taxa_barplot
#SBATCH --partition=highprio
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
BASE="/home/jtay0094/MAGs/${COHORT}"

TABLE="${BASE}/binning/abundance_derep098/mags_derep098_abundance.qza"
TAX="${BASE}/taxonomy/kraken2_pluspf_derep098/mags-taxonomy.qza"

OUTDIR="${BASE}/taxonomy/kraken2_pluspf_derep098"
BARPLOT="${OUTDIR}/mags_taxa_barplot.qzv"

# ===============================
# Checks
# ===============================
[[ -f "$TABLE" ]] || { echo "ERROR: Missing $TABLE" >&2; exit 1; }
[[ -f "$TAX" ]]   || { echo "ERROR: Missing $TAX" >&2; exit 1; }

# ===============================
# Run (skip if exists)
# ===============================
if [[ -f "$BARPLOT" ]]; then
  echo "Barplot already exists — skipping: $BARPLOT"
else
  qiime taxa barplot \
    --i-table "$TABLE" \
    --i-taxonomy "$TAX" \
    --o-visualization "$BARPLOT"
fi

echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
echo "OUTPUT: $BARPLOT"
echo "================================================="
