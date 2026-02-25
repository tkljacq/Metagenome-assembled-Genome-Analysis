#!/bin/bash
#SBATCH --job-name=01_coassembly_xx
#SBATCH --partition=highprio
#SBATCH --cpus-per-task=32
#SBATCH --mem=126G
#SBATCH --time=14-00:00:00
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err

# NOTE: avoid "set -u" on this cluster because /etc/bashrc can trigger unbound variables
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

# LIST files: one FASTQ path per line
R1_LIST="/home/jtay0094/coassembly/txt_files/coass_${COHORT}_R1"
R2_LIST="/home/jtay0094/coassembly/txt_files/coass_${COHORT}_R2"

OUTDIR="/home/jtay0094/coassembly/${COHORT}/assembly"
ASSEMBLY_DIR="${OUTDIR}/megahit_out"

# MEGAHIT settings
MIN_CONTIG_LEN="2000"
THREADS="${SLURM_CPUS_PER_TASK}"
MEM_FRACTION="0.85"
PRESET="meta-sensitive"   # note: "metasensitive" is invalid

# ===============================
# ENVIRONMENT
# ===============================
source ~/.bashrc
conda activate qiime2-moshpit-2025.7

command -v megahit >/dev/null 2>&1 || { echo "[ERROR] megahit not found in env" >&2; exit 1; }

# ===============================
# RUN
# ===============================
mkdir -p "${OUTDIR}"

echo "COHORT:  ${COHORT}"
echo "R1 list: ${R1_LIST}"
echo "R2 list: ${R2_LIST}"
echo "Out:     ${ASSEMBLY_DIR}"
echo "Threads: ${THREADS}"
echo "Contig cutoff: ${MIN_CONTIG_LEN}"
echo "MEGAHIT preset: ${PRESET}"
echo "-------------------------------------------------"

[[ -s "${R1_LIST}" ]] || { echo "[ERROR] Missing/empty R1 list: ${R1_LIST}" >&2; exit 1; }
[[ -s "${R2_LIST}" ]] || { echo "[ERROR] Missing/empty R2 list: ${R2_LIST}" >&2; exit 1; }

# IMPORTANT: MEGAHIT requires -o output directory NOT to exist
if [[ -e "${ASSEMBLY_DIR}" ]]; then
  echo "[ERROR] MEGAHIT output dir exists: ${ASSEMBLY_DIR}" >&2
  echo "        Delete/rename it before re-running:" >&2
  echo "        rm -rf ${ASSEMBLY_DIR}" >&2
  exit 1
fi

# Convert newline-separated lists into comma-separated inputs
R1="$(paste -sd, "${R1_LIST}")"
R2="$(paste -sd, "${R2_LIST}")"

# Validate input files exist and are non-empty
IFS=',' read -ra R1_ARR <<< "${R1}"
IFS=',' read -ra R2_ARR <<< "${R2}"

for f in "${R1_ARR[@]}"; do
  [[ -s "$f" ]] || { echo "[ERROR] Missing/empty R1 file: $f" >&2; exit 1; }
done
for f in "${R2_ARR[@]}"; do
  [[ -s "$f" ]] || { echo "[ERROR] Missing/empty R2 file: $f" >&2; exit 1; }
done

echo "Running MEGAHIT: $(date '+%Y-%m-%d %H:%M:%S')"
megahit \
  -1 "${R1}" \
  -2 "${R2}" \
  --presets "${PRESET}" \
  --min-contig-len "${MIN_CONTIG_LEN}" \
  -t "${THREADS}" \
  -m "${MEM_FRACTION}" \
  -o "${ASSEMBLY_DIR}"

echo "Co-assembly complete: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Final contigs: ${ASSEMBLY_DIR}/final.contigs.fa"
echo "Contig count: $(grep -c '^>' ${ASSEMBLY_DIR}/final.contigs.fa 2>/dev/null || true)"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
printf "ELAPSED: %02dh %02dm %02ds\n" $((ELAPSED/3600)) $(((ELAPSED%3600)/60)) $((ELAPSED%60))
echo "================================================="
