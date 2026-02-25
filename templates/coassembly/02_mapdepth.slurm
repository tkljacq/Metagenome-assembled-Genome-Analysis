#!/bin/bash
#SBATCH --job-name=02_mapdepth_xx
#SBATCH --partition=highprio
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=2-00:00:00
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

# Co-assembly contigs
CONTIGS="/home/jtay0094/coassembly/${COHORT}/assembly/megahit_out/final.contigs.fa"

# LIST files: one FASTQ path per line (must be same order)
R1_LIST="/home/jtay0094/coassembly/txt_files/coass_${COHORT}_R1"
R2_LIST="/home/jtay0094/coassembly/txt_files/coass_${COHORT}_R2"

# Output base
OUT_BASE="/home/jtay0094/coassembly/${COHORT}/binning"

# ===============================
# Derived paths
# ===============================
INDEX_DIR="${OUT_BASE}/index"
MAP_DIR="${OUT_BASE}/mapping"
DEPTH_DIR="${OUT_BASE}/depth"
mkdir -p "${INDEX_DIR}" "${MAP_DIR}" "${DEPTH_DIR}"

INDEX_PREFIX="${INDEX_DIR}/contigs"
DEPTH_TXT="${DEPTH_DIR}/depth.txt"
THREADS="${SLURM_CPUS_PER_TASK}"

# ===============================
# ENVIRONMENT
# ===============================
source ~/.bashrc
conda activate coass-binning

for cmd in bowtie2 bowtie2-build samtools jgi_summarize_bam_contig_depths; do
  command -v "${cmd}" >/dev/null 2>&1 || { echo "[ERROR] Missing '${cmd}' in coass-binning env." >&2; exit 1; }
done

# ===============================
# RUN
# ===============================
echo "COHORT:  ${COHORT}"
echo "Contigs: ${CONTIGS}"
echo "R1 list: ${R1_LIST}"
echo "R2 list: ${R2_LIST}"
echo "OUT:     ${OUT_BASE}"
echo "CPUs:    ${THREADS}"
echo "-------------------------------------------------"

[[ -s "${CONTIGS}" ]] || { echo "[ERROR] Missing contigs: ${CONTIGS}" >&2; exit 1; }
[[ -s "${R1_LIST}" ]] || { echo "[ERROR] Missing/empty R1 list: ${R1_LIST}" >&2; exit 1; }
[[ -s "${R2_LIST}" ]] || { echo "[ERROR] Missing/empty R2 list: ${R2_LIST}" >&2; exit 1; }

N1=$(wc -l < "${R1_LIST}")
N2=$(wc -l < "${R2_LIST}")
[[ "${N1}" -eq "${N2}" && "${N1}" -gt 0 ]] || { echo "[ERROR] R1/R2 list mismatch." >&2; exit 1; }

# Copy contigs into index dir for reproducibility
CONTIGS_COPY="${INDEX_DIR}/contigs.fa"
cp -f "${CONTIGS}" "${CONTIGS_COPY}"

echo "Building bowtie2 index: $(date '+%Y-%m-%d %H:%M:%S')"
bowtie2-build "${CONTIGS_COPY}" "${INDEX_PREFIX}"

BAM_LIST=()

echo "Mapping reads: $(date '+%Y-%m-%d %H:%M:%S')"
while IFS=$'\t' read -r R1 R2; do
  R1="${R1%$'\r'}"; R2="${R2%$'\r'}"
  [[ -n "${R1// }" && -n "${R2// }" ]] || continue

  [[ -s "${R1}" ]] || { echo "[ERROR] Missing/empty R1: ${R1}" >&2; exit 1; }
  [[ -s "${R2}" ]] || { echo "[ERROR] Missing/empty R2: ${R2}" >&2; exit 1; }

  sample="$(basename "${R1}")"
  sample="${sample%_paired_1.fastq}"
  sample="${sample%_1.fastq}"

  echo "---------------------------------------------"
  echo "Sample: ${sample}"
  echo "TIME:   $(date '+%Y-%m-%d %H:%M:%S')"
  echo "---------------------------------------------"

  bam="${MAP_DIR}/${sample}.sorted.bam"

  bowtie2 \
    -x "${INDEX_PREFIX}" \
    -1 "${R1}" -2 "${R2}" \
    -p "${THREADS}" \
  | samtools view -@ "${THREADS}" -b - \
  | samtools sort -@ "${THREADS}" -o "${bam}" -

  samtools index "${bam}"
  BAM_LIST+=("${bam}")

done < <(paste "${R1_LIST}" "${R2_LIST}")

echo "Generating depth matrix: $(date '+%Y-%m-%d %H:%M:%S')"
jgi_summarize_bam_contig_depths \
  --outputDepth "${DEPTH_TXT}" \
  "${BAM_LIST[@]}"

echo "Depth file: ${DEPTH_TXT}"
echo "BAMs in:   ${MAP_DIR}"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
printf "ELAPSED: %02dh %02dm %02ds\n" $((ELAPSED/3600)) $(((ELAPSED%3600)/60)) $((ELAPSED%60))
echo "================================================="
