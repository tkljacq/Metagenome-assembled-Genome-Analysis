#!/bin/bash
#SBATCH --job-name=05_concoct_xx
#SBATCH --partition=cpu.largem
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=3-00:00:00
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
MAP_DIR="/home/jtay0094/coassembly/${COHORT}/binning/mapping"   # expects *.sorted.bam

OUT_DIR="/home/jtay0094/coassembly/${COHORT}/binning/concoct"
WORK_DIR="${OUT_DIR}/work"
BINS_DIR="${OUT_DIR}/bins"

# ===============================
# ENVIRONMENT
# ===============================
source ~/.bashrc
conda activate coass-binning

for cmd in concoct cut_up_fasta.py concoct_coverage_table.py merge_cutup_clustering.py extract_fasta_bins.py; do
  command -v "${cmd}" >/dev/null 2>&1 || { echo "[ERROR] Missing '${cmd}' in coass-binning env." >&2; exit 1; }
done

# ===============================
# RUN
# ===============================
mkdir -p "${WORK_DIR}" "${BINS_DIR}"

echo "COHORT:  ${COHORT}"
echo "Contigs: ${CONTIGS}"
echo "MAP_DIR: ${MAP_DIR}"
echo "Out:     ${OUT_DIR}"
echo "CPUs:    ${SLURM_CPUS_PER_TASK}"
echo "-------------------------------------------------"

[[ -s "${CONTIGS}" ]] || { echo "[ERROR] Missing contigs: ${CONTIGS}" >&2; exit 1; }
if ! ls "${MAP_DIR}"/*.sorted.bam 1>/dev/null 2>&1; then
  echo "[ERROR] No BAMs found in ${MAP_DIR} (*.sorted.bam). Run mapdepth first." >&2
  exit 1
fi

CUT_FA="${WORK_DIR}/contigs_10K.fa"
CUT_BED="${WORK_DIR}/contigs_10K.bed"
COV_TSV="${WORK_DIR}/coverage_table.tsv"
CONCOCT_OUT="${WORK_DIR}/concoct_out"
CLUST_CSV="${CONCOCT_OUT}/clustering_gt1000.csv"
MERGED_CSV="${WORK_DIR}/clustering_merged.csv"

echo "Cutting contigs into 10kb fragments: $(date '+%Y-%m-%d %H:%M:%S')"
cut_up_fasta.py "${CONTIGS}" -c 10000 -o 0 --merge_last -b "${CUT_BED}" > "${CUT_FA}"

echo "Building coverage table: $(date '+%Y-%m-%d %H:%M:%S')"
concoct_coverage_table.py "${CUT_BED}" "${MAP_DIR}"/*.sorted.bam > "${COV_TSV}"

mkdir -p "${CONCOCT_OUT}"

echo "Running CONCOCT: $(date '+%Y-%m-%d %H:%M:%S')"
concoct \
  --composition_file "${CUT_FA}" \
  --coverage_file "${COV_TSV}" \
  -b "${CONCOCT_OUT}/" \
  -c "${SLURM_CPUS_PER_TASK}"

[[ -s "${CLUST_CSV}" ]] || { echo "[ERROR] Missing clustering file: ${CLUST_CSV}" >&2; exit 1; }

echo "Merging cut-up clustering: $(date '+%Y-%m-%d %H:%M:%S')"
merge_cutup_clustering.py "${CLUST_CSV}" > "${MERGED_CSV}"

echo "Extracting bins: $(date '+%Y-%m-%d %H:%M:%S')"
extract_fasta_bins.py "${CONTIGS}" "${MERGED_CSV}" --output_path "${BINS_DIR}"

echo "Bins folder: ${BINS_DIR}"
echo "Bin count: $(ls -1 ${BINS_DIR}/*.fa 2>/dev/null | wc -l)"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
printf "ELAPSED: %02dh %02dm %02ds\n" $((ELAPSED/3600)) $(((ELAPSED%3600)/60)) $((ELAPSED%60))
echo "================================================="
