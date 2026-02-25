#!/bin/bash
#SBATCH --job-name=04_maxbin2_xx
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

R1_LIST="/home/jtay0094/coassembly/txt_files/coass_${COHORT}_R1"
R2_LIST="/home/jtay0094/coassembly/txt_files/coass_${COHORT}_R2"
CONTIGS="/home/jtay0094/coassembly/${COHORT}/assembly/final.contigs.fa"

OUT_DIR="/home/jtay0094/coassembly/${COHORT}/binning/maxbin2"
READS_DIR="${OUT_DIR}/reads_interleaved"

# ===============================
# ENVIRONMENT
# ===============================
source ~/.bashrc
conda activate coass-binning

command -v run_MaxBin.pl >/dev/null 2>&1 || { echo "[ERROR] run_MaxBin.pl not found in env" >&2; exit 1; }

# ===============================
# RUN
# ===============================
mkdir -p "${OUT_DIR}" "${READS_DIR}"

echo "COHORT:  ${COHORT}"
echo "Contigs: ${CONTIGS}"
echo "R1 list: ${R1_LIST}"
echo "R2 list: ${R2_LIST}"
echo "Out:     ${OUT_DIR}"
echo "CPUs:    ${SLURM_CPUS_PER_TASK}"
echo "-------------------------------------------------"

[[ -s "${CONTIGS}" ]] || { echo "[ERROR] Missing contigs: ${CONTIGS}" >&2; exit 1; }
[[ -s "${R1_LIST}" ]] || { echo "[ERROR] Missing/empty R1 list: ${R1_LIST}" >&2; exit 1; }
[[ -s "${R2_LIST}" ]] || { echo "[ERROR] Missing/empty R2 list: ${R2_LIST}" >&2; exit 1; }

N1=$(wc -l < "${R1_LIST}")
N2=$(wc -l < "${R2_LIST}")
[[ "${N1}" -eq "${N2}" && "${N1}" -gt 0 ]] || { echo "[ERROR] R1/R2 list mismatch." >&2; exit 1; }

echo "Preparing interleaved read files: $(date '+%Y-%m-%d %H:%M:%S')"

READ_FILES=()

while IFS=$'\t' read -r R1 R2; do
  R1="${R1%$'\r'}"
  R2="${R2%$'\r'}"
  [[ -n "${R1// }" && -n "${R2// }" ]] || continue

  [[ -s "${R1}" ]] || { echo "[ERROR] Missing/empty R1: ${R1}" >&2; exit 1; }
  [[ -s "${R2}" ]] || { echo "[ERROR] Missing/empty R2: ${R2}" >&2; exit 1; }

  sample="$(basename "${R1}")"
  sample="${sample%_paired_1.fastq}"
  sample="${sample%_1.fastq}"

  out="${READS_DIR}/${sample}.interleaved.fastq"

  echo "  Interleaving ${sample}  |  $(date '+%Y-%m-%d %H:%M:%S')"

  paste -d '\n' \
    <(paste - - - - < "${R1}") \
    <(paste - - - - < "${R2}") \
  | tr '\t' '\n' > "${out}"

  [[ -s "${out}" ]] || { echo "[ERROR] Failed to create interleaved file: ${out}" >&2; exit 1; }
  READ_FILES+=("${out}")

done < <(paste "${R1_LIST}" "${R2_LIST}")

echo "Interleaved files created: ${#READ_FILES[@]}"
[[ "${#READ_FILES[@]}" -gt 0 ]] || { echo "[ERROR] No interleaved files created." >&2; exit 1; }

ARGS=()
for i in "${!READ_FILES[@]}"; do
  idx=$((i+1))
  if [[ "${idx}" -eq 1 ]]; then
    ARGS+=("-reads" "${READ_FILES[$i]}")
  else
    ARGS+=("-reads${idx}" "${READ_FILES[$i]}")
  fi
done

echo "Running MaxBin2: $(date '+%Y-%m-%d %H:%M:%S')"
run_MaxBin.pl \
  -contig "${CONTIGS}" \
  -out "${OUT_DIR}/maxbin" \
  -thread "${SLURM_CPUS_PER_TASK}" \
  "${ARGS[@]}"

echo "Bin count: $(ls -1 ${OUT_DIR}/maxbin*.fasta 2>/dev/null | wc -l)"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
printf "ELAPSED: %02dh %02dm %02ds\n" $((ELAPSED/3600)) $(((ELAPSED%3600)/60)) $((ELAPSED%60))
echo "================================================="
