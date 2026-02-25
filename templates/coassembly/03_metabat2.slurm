#!/bin/bash
#SBATCH --job-name=03_metabat2_xx
#SBATCH --partition=cpu.largem
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=1-00:00:00
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err

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
COHORT="hfemales1"

CONTIGS="/home/jtay0094/coassembly/${COHORT}/assembly/final.contigs.fa"
DEPTH="/home/jtay0094/coassembly/${COHORT}/binning/depth/depth.txt"

OUT_DIR="/home/jtay0094/coassembly/${COHORT}/binning/metabat2"
BIN_PREFIX="bin"

# ===============================
# ENVIRONMENT
# ===============================
source ~/.bashrc
conda activate coass-binning

command -v metabat2 >/dev/null 2>&1 || { echo "[ERROR] metabat2 not found in env" >&2; exit 1; }

# ===============================
# RUN
# ===============================
mkdir -p "${OUT_DIR}"

echo "COHORT:  ${COHORT}"
echo "Contigs: ${CONTIGS}"
echo "Depth:   ${DEPTH}"
echo "Out:     ${OUT_DIR}"
echo "CPUs:    ${SLURM_CPUS_PER_TASK}"
echo "-------------------------------------------------"

[[ -s "${CONTIGS}" ]] || { echo "[ERROR] Missing contigs: ${CONTIGS}" >&2; exit 1; }
[[ -s "${DEPTH}"   ]] || { echo "[ERROR] Missing depth: ${DEPTH}" >&2; exit 1; }

echo "Running MetaBAT2: $(date '+%Y-%m-%d %H:%M:%S')"
metabat2 \
  -i "${CONTIGS}" \
  -a "${DEPTH}" \
  -o "${OUT_DIR}/${BIN_PREFIX}" \
  -t "${SLURM_CPUS_PER_TASK}"

echo "Bin count: $(ls -1 ${OUT_DIR}/${BIN_PREFIX}*.fa 2>/dev/null | wc -l)"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
printf "ELAPSED: %02dh %02dm %02ds\n" $((ELAPSED/3600)) $(((ELAPSED%3600)/60)) $((ELAPSED%60))
echo "================================================="
