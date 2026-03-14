#!/bin/bash
#SBATCH --job-name=06_busco_xx
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=1-12:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

set -eEo pipefail
export LC_ALL=C
export LANG=C

START_TIME=$(date +%s)

echo "================================================="
echo "START: $(date '+%Y-%m-%d %H:%M:%S')"
echo "JOB: ${SLURM_JOB_NAME}  ID: ${SLURM_JOB_ID}"
echo "NODE: $(hostname)"
echo "================================================="

# ===============================
# USER SETTINGS (EDIT THIS ONLY)
# ===============================
COHORT="ibsd1"
LINEAGE="bacteria_odb12"

# Shared BUSCO DB (download once, reuse for all cohorts)
BUSCO_DB_QZA="/home/jtay0094/databases/busco/bacteria_odb12.qza"

# ===============================
# ENVIRONMENT
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-moshpit-2025.7

# Force QIIME2 temp to project tmp (avoid /tmp full)
export TMPDIR="/home/jtay0094/MAGs/${COHORT}/assembly/tmp_q2"
mkdir -p "$TMPDIR"

CPU="${SLURM_CPUS_PER_TASK}"

# ===============================
# INPUTS
# ===============================
BIN_DIR="/home/jtay0094/MAGs/${COHORT}/binning/metabat"
MAGS_QZA="${BIN_DIR}/mags.qza"

# ===============================
# OUTPUTS
# ===============================
OUT_DIR="/home/jtay0094/MAGs/${COHORT}/binning/busco"
mkdir -p "$OUT_DIR"

BUSCO_RESULTS_QZA="${OUT_DIR}/busco_results.qza"
BUSCO_VIZ_QZV="${OUT_DIR}/mags_busco.qzv"

# ===============================
# CHECKS
# ===============================
[[ -f "$MAGS_QZA" ]]     || { echo "ERROR: Missing MAGs artifact: $MAGS_QZA" >&2; exit 1; }
[[ -f "$BUSCO_DB_QZA" ]] || { echo "ERROR: Missing shared BUSCO DB: $BUSCO_DB_QZA" >&2; exit 1; }

# ===============================
# RUN BUSCO
# ===============================
if [[ ! -f "$BUSCO_RESULTS_QZA" || ! -f "$BUSCO_VIZ_QZV" ]]; then
  echo "Starting BUSCO evaluation: $(date '+%Y-%m-%d %H:%M:%S')"

  mosh annotate evaluate-busco \
    --i-mags "$MAGS_QZA" \
    --i-db "$BUSCO_DB_QZA" \
    --p-lineage-dataset "$LINEAGE" \
    --p-cpu "$CPU" \
    --o-visualization "$BUSCO_VIZ_QZV" \
    --o-results "$BUSCO_RESULTS_QZA" \
    --verbose

  echo "Finished BUSCO evaluation: $(date '+%Y-%m-%d %H:%M:%S')"
else
  echo "BUSCO outputs already exist — skipping"
fi

# ===============================
# FINISH
# ===============================
END_TIME=$(date +%s)
RUNTIME=$((END_TIME - START_TIME))

echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Total runtime: ${RUNTIME} seconds"
echo "Results: $BUSCO_RESULTS_QZA"
echo "Viz:     $BUSCO_VIZ_QZV"
echo "================================================="
