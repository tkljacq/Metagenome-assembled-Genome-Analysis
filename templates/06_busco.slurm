#!/bin/bash
#SBATCH --job-name=busco
#SBATCH --partition=cpu1.largem
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=2-00:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G

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
# Sanity check
# ===============================
[[ -f "$MAGS_QZA" ]] || { echo "ERROR: Missing MAGs artifact: $MAGS_QZA" >&2; exit 1; }

# ===============================
# 1) Fetch BUSCO DB (run once)
# ===============================
if [[ ! -f "$BUSCO_DB_QZA" ]]; then
  mosh annotate fetch-busco-db \
    --p-lineages "$LINEAGE" \
    --o-db "$BUSCO_DB_QZA" \
    --verbose
fi

# ===============================
# 2) Evaluate MAGs with BUSCO
# ===============================
if [[ ! -f "$BUSCO_RESULTS_QZA" || ! -f "$BUSCO_VIZ_QZV" ]]; then
  mosh annotate evaluate-busco \
    --i-mags "$MAGS_QZA" \
    --i-db "$BUSCO_DB_QZA" \
    --p-lineage-dataset "$LINEAGE" \
    --p-cpu "$CPU" \
    --o-visualization "$BUSCO_VIZ_QZV" \
    --o-results "$BUSCO_RESULTS_QZA" \
    --verbose
fi

echo "BUSCO evaluation completed."
echo "Results: $BUSCO_RESULTS_QZA"
echo "Viz:     $BUSCO_VIZ_QZV"

