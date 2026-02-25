#!/bin/bash
#SBATCH --job-name=06_dastool_xx
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

CONTIGS="/home/jtay0094/coassembly/${COHORT}/assembly/final.contigs.fa"

# MetaBAT2 bins
METABAT_DIR="/home/jtay0094/coassembly/${COHORT}/binning/metabat2"
METABAT_GLOB="bin*.fa"
METABAT_LABEL="metabat2"

# MaxBin2 bins
MAXBIN_DIR="/home/jtay0094/coassembly/${COHORT}/binning/maxbin2"
MAXBIN_GLOB="maxbin*.fasta"
MAXBIN_LABEL="maxbin2"

# CONCOCT bins
CONCOCT_DIR="/home/jtay0094/coassembly/${COHORT}/binning/concoct/bins"
CONCOCT_GLOB="*.fa"
CONCOCT_LABEL="concoct"

# DAS Tool output
OUT_DIR="/home/jtay0094/coassembly/${COHORT}/binning/dastool"
OUT_BASE="${OUT_DIR}/dastool"   # will produce dastool_DASTool_bins etc.

THREADS="${SLURM_CPUS_PER_TASK}"

# ===============================
# ENVIRONMENT
# ===============================
source ~/.bashrc
conda activate coass-binning

for cmd in DAS_Tool Fasta_to_Contig2Bin.sh; do
  command -v "${cmd}" >/dev/null 2>&1 || { echo "[ERROR] Missing '${cmd}' in coass-binning env." >&2; exit 1; }
done

# Prefer diamond (used by DAS Tool by default)
command -v diamond >/dev/null 2>&1 || { echo "[ERROR] Missing 'diamond' in coass-binning env." >&2; exit 1; }

# ===============================
# RUN
# ===============================
mkdir -p "${OUT_DIR}"

echo "COHORT:  ${COHORT}"
echo "Contigs: ${CONTIGS}"
echo "Out:     ${OUT_DIR}"
echo "Threads: ${THREADS}"
echo "-------------------------------------------------"

[[ -s "${CONTIGS}" ]] || { echo "[ERROR] Missing contigs: ${CONTIGS}" >&2; exit 1; }

# Build contig2bin tables
C2B_DIR="${OUT_DIR}/contig2bin"
mkdir -p "${C2B_DIR}"

METABAT_C2B="${C2B_DIR}/${METABAT_LABEL}.tsv"
MAXBIN_C2B="${C2B_DIR}/${MAXBIN_LABEL}.tsv"
CONCOCT_C2B="${C2B_DIR}/${CONCOCT_LABEL}.tsv"

echo "Building contig2bin files: $(date '+%Y-%m-%d %H:%M:%S')"

# MetaBAT2
if ls "${METABAT_DIR}"/${METABAT_GLOB} 1>/dev/null 2>&1; then
  Fasta_to_Contig2Bin.sh -i "${METABAT_DIR}" -e fa > "${METABAT_C2B}"
  echo "MetaBAT2 contig2bin lines: $(wc -l < "${METABAT_C2B}")"
else
  echo "[ERROR] No MetaBAT2 bins found: ${METABAT_DIR}/${METABAT_GLOB}" >&2
  exit 1
fi

# MaxBin2
if ls "${MAXBIN_DIR}"/${MAXBIN_GLOB} 1>/dev/null 2>&1; then
  # MaxBin output ends with .fasta by default
  Fasta_to_Contig2Bin.sh -i "${MAXBIN_DIR}" -e fasta > "${MAXBIN_C2B}"
  echo "MaxBin2  contig2bin lines: $(wc -l < "${MAXBIN_C2B}")"
else
  echo "[ERROR] No MaxBin2 bins found: ${MAXBIN_DIR}/${MAXBIN_GLOB}" >&2
  exit 1
fi

# CONCOCT
if ls "${CONCOCT_DIR}"/${CONCOCT_GLOB} 1>/dev/null 2>&1; then
  Fasta_to_Contig2Bin.sh -i "${CONCOCT_DIR}" -e fa > "${CONCOCT_C2B}"
  echo "CONCOCT  contig2bin lines: $(wc -l < "${CONCOCT_C2B}")"
else
  echo "[ERROR] No CONCOCT bins found: ${CONCOCT_DIR}/${CONCOCT_GLOB}" >&2
  exit 1
fi

echo "Running DAS Tool: $(date '+%Y-%m-%d %H:%M:%S')"
DAS_Tool \
  -i "${METABAT_C2B},${MAXBIN_C2B},${CONCOCT_C2B}" \
  -l "${METABAT_LABEL},${MAXBIN_LABEL},${CONCOCT_LABEL}" \
  -c "${CONTIGS}" \
  -o "${OUT_BASE}" \
  --search_engine diamond \
  --write_bins \
  --threads "${THREADS}"

echo "Finished DAS Tool: $(date '+%Y-%m-%d %H:%M:%S')"
echo "DAS Tool bins dir: ${OUT_BASE}_DASTool_bins"
echo "Bin count: $(ls -1 ${OUT_BASE}_DASTool_bins/*.fa 2>/dev/null | wc -l)"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
printf "ELAPSED: %02dh %02dm %02ds\n" $((ELAPSED/3600)) $(((ELAPSED%3600)/60)) $((ELAPSED%60))
echo "================================================="
