#!/bin/bash
#SBATCH --job-name=08_gunc_xx
#SBATCH --partition=highprio
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=2-00:00:00
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err

set -eo pipefail
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
COHORT="hfemales1"

# Input bins (usually DAS Tool output)
BINS_DIR="/home/jtay0094/coassembly/${COHORT}/binning/dastool/dastool_DASTool_bins"

# GUNC database (progenomes DB you downloaded)
DB_FILE="/home/jtay0094/databases/gunc/gunc_db_progenomes2.1.dmnd"

# Output
OUT_DIR="/home/jtay0094/coassembly/${COHORT}/binning/gunc"
TMP_DIR="${OUT_DIR}/tmp"

THREADS="${SLURM_CPUS_PER_TASK}"

# ===============================
# ENVIRONMENT
# ===============================
source ~/.bashrc
conda activate coass-binning

for cmd in gunc diamond; do
  command -v "${cmd}" >/dev/null 2>&1 || { echo "[ERROR] Missing '${cmd}' in coass-binning env." >&2; exit 1; }
done

# ===============================
# RUN
# ===============================
mkdir -p "${OUT_DIR}" "${TMP_DIR}"

echo "COHORT: ${COHORT}"
echo "Bins:   ${BINS_DIR}"
echo "DB:     ${DB_FILE}"
echo "Out:    ${OUT_DIR}"
echo "CPUs:   ${THREADS}"
echo "-------------------------------------------------"

if ! ls "${BINS_DIR}"/*.fa 1>/dev/null 2>&1; then
  echo "[ERROR] No .fa bins found in ${BINS_DIR}" >&2
  exit 1
fi

[[ -s "${DB_FILE}" ]] || { echo "[ERROR] Missing GUNC DB: ${DB_FILE}" >&2; exit 1; }

# Point GUNC to DB
export GUNC_DB="${DB_FILE}"

echo "Running GUNC: $(date '+%Y-%m-%d %H:%M:%S')"
gunc run \
  --input_dir "${BINS_DIR}" \
  --file_suffix .fa \
  --out_dir "${OUT_DIR}" \
  --threads "${THREADS}" \
  --temp_dir "${TMP_DIR}"

echo "Finished GUNC: $(date '+%Y-%m-%d %H:%M:%S')"
echo "GUNC output dir: ${OUT_DIR}"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
printf "ELAPSED: %02dh %02dm %02ds\n" $((ELAPSED/3600)) $(((ELAPSED%3600)/60)) $((ELAPSED%60))
echo "================================================="
