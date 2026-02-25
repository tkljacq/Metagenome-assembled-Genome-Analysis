#!/bin/bash
#SBATCH --job-name=07_checkm_xx
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

# Output
OUT_DIR="/home/jtay0094/coassembly/${COHORT}/binning/checkm"

# CheckM DB (confirmed on your system)
CHECKM_DB="/home/jtay0094/databases/checkm/checkm_data"

THREADS="${SLURM_CPUS_PER_TASK}"

# ===============================
# ENVIRONMENT
# ===============================
source ~/.bashrc
conda activate coass-binning

command -v checkm >/dev/null 2>&1 || { echo "[ERROR] checkm not found in env" >&2; exit 1; }

# ===============================
# RUN
# ===============================
mkdir -p "${OUT_DIR}"

echo "COHORT: ${COHORT}"
echo "Bins:   ${BINS_DIR}"
echo "Out:    ${OUT_DIR}"
echo "DB:     ${CHECKM_DB}"
echo "CPUs:   ${THREADS}"
echo "-------------------------------------------------"

if ! ls "${BINS_DIR}"/*.fa 1>/dev/null 2>&1; then
  echo "[ERROR] No .fa bins found in ${BINS_DIR}" >&2
  exit 1
fi

[[ -s "${CHECKM_DB}/hmms/phylo.hmm" ]] || { echo "[ERROR] Missing ${CHECKM_DB}/hmms/phylo.hmm" >&2; exit 1; }

echo "Setting CheckM DB root: $(date '+%Y-%m-%d %H:%M:%S')"
checkm data setRoot "${CHECKM_DB}"

echo "Running CheckM lineage_wf: $(date '+%Y-%m-%d %H:%M:%S')"
checkm lineage_wf \
  -t "${THREADS}" \
  -x fa \
  "${BINS_DIR}" \
  "${OUT_DIR}"

# Create a user-friendly QA table
echo "Writing CheckM QA table: $(date '+%Y-%m-%d %H:%M:%S')"
checkm qa -o 2 \
  -f "${OUT_DIR}/checkm_qa.tsv" \
  "${OUT_DIR}/lineage.ms" \
  "${OUT_DIR}"

echo "Finished CheckM: $(date '+%Y-%m-%d %H:%M:%S')"
echo "QA table: ${OUT_DIR}/checkm_qa.tsv"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
printf "ELAPSED: %02dh %02dm %02ds\n" $((ELAPSED/3600)) $(((ELAPSED%3600)/60)) $((ELAPSED%60))
echo "================================================="
