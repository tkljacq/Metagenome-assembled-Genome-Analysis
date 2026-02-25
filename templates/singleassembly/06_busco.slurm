#!/bin/bash
#SBATCH --job-name=06_busco
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=1-12:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

set -eo pipefail

echo "==============================================="
echo "Job started at: $(date)"
echo "==============================================="

# ===============================
# User setting (EDIT THIS ONLY)
# ===============================
COHORT="healthy1"

# ===============================
# Environment
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-moshpit-2025.7

# Force QIIME2 temp to project tmp (avoid /tmp full)
export TMPDIR="/home/jtay0094/MAGs/${COHORT}/assembly/tmp_q2"
mkdir -p "$TMPDIR"

CPU="${SLURM_CPUS_PER_TASK}"
LINEAGE="bacteria_odb12"

# ===============================
# Inputs (from 05_binning_metabat)
# ===============================
BIN_DIR="/home/jtay0094/MAGs/${COHORT}/binning/metabat"
MAGS_QZA="${BIN_DIR}/mags.qza"

# ===============================
# Outputs
# ===============================
OUT_DIR="/home/jtay0094/MAGs/${COHORT}/binning/busco"
mkdir -p "$OUT_DIR"

BUSCO_DB_QZA="${OUT_DIR}/busco_db.qza"
BUSCO_RESULTS_QZA="${OUT_DIR}/busco_results.qza"
BUSCO_VIZ_QZV="${OUT_DIR}/mags_busco.qzv"

# ===============================
# Checks
# ===============================
[[ -f "$MAGS_QZA" ]] || { echo "ERROR: Missing MAGs artifact: $MAGS_QZA" >&2; exit 1; }

# ===============================
# 1) Fetch BUSCO DB (run once)
# ===============================
if [[ ! -f "$BUSCO_DB_QZA" ]]; then
  echo "Fetching BUSCO DB at: $(date)"
  mosh annotate fetch-busco-db \
    --p-lineages "$LINEAGE" \
    --o-db "$BUSCO_DB_QZA" \
    --verbose
  echo "Finished fetching BUSCO DB at: $(date)"
fi

# ===============================
# 2) Evaluate MAGs with BUSCO
# ===============================
if [[ ! -f "$BUSCO_RESULTS_QZA" || ! -f "$BUSCO_VIZ_QZV" ]]; then
  echo "Starting BUSCO evaluation at: $(date)"
  mosh annotate evaluate-busco \
    --i-mags "$MAGS_QZA" \
    --i-db "$BUSCO_DB_QZA" \
    --p-lineage-dataset "$LINEAGE" \
    --p-cpu "$CPU" \
    --o-visualization "$BUSCO_VIZ_QZV" \
    --o-results "$BUSCO_RESULTS_QZA" \
    --verbose
  echo "Finished BUSCO evaluation at: $(date)"
else
  echo "BUSCO outputs already exist — skipping."
fi

echo "==============================================="
echo "BUSCO evaluation completed at: $(date)"
echo "Results: $BUSCO_RESULTS_QZA"
echo "Viz:     $BUSCO_VIZ_QZV"
echo "==============================================="
echo "Job finished at: $(date)"
echo "==============================================="
