#!/bin/bash
#SBATCH --job-name=13_kraken2_derep
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=4-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G

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

# ===============================
# Inputs
# ===============================
BASE="/home/jtay0094/MAGs/${COHORT}"

MAGS="${BASE}/binning/derep_thr098/mags_derep.qza"
KRAKEN_DB="/home/jtay0094/databases/kraken2_pluspf/kraken2_pluspf_db.qza"

# ===============================
# Outputs
# ===============================
OUTDIR="${BASE}/taxonomy/kraken2_pluspf_derep098"
mkdir -p "$OUTDIR"

REPORTS="${OUTDIR}/kraken2-reports-mags.qza"
OUTPUTS="${OUTDIR}/kraken2-hits-mags.qza"

# ===============================
# Checks
# ===============================
[[ -f "$MAGS" ]]     || { echo "ERROR: Missing $MAGS" >&2; exit 1; }
[[ -f "$KRAKEN_DB" ]] || { echo "ERROR: Missing $KRAKEN_DB" >&2; exit 1; }

# ===============================
# Run (skip if exists)
# ===============================
if [[ -f "$REPORTS" && -f "$OUTPUTS" ]]; then
  echo "Kraken2 outputs already exist — skipping."
else
  mosh annotate classify-kraken2 \
    --i-seqs "$MAGS" \
    --i-db "$KRAKEN_DB" \
    --p-threads "$THREADS" \
    --p-memory-mapping \
    --o-reports "$REPORTS" \
    --o-outputs "$OUTPUTS" \
    --verbose
fi

echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
echo "REPORTS: $REPORTS"
echo "OUTPUTS: $OUTPUTS"
echo "================================================="
