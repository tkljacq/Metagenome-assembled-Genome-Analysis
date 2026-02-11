#!/bin/bash
#SBATCH --job-name=kneaddata
#SBATCH --partition=cpu1
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G

set -eo pipefail

# ===============================
# User setting (EDIT THIS ONLY)
# ===============================
COHORT="healthy1"

# ===============================
# Environment
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate metaprep

# ===============================
# Directories (new structure)
# ===============================
RAW_DIR="/home/jtay0094/MAGs/rawreads/${COHORT}"
OUT_BASE="/home/jtay0094/MAGs/${COHORT}/kneaddata"

DB_BOWTIE2="/home/jtay0094/databases/bowtie2"
TRIM_ADAPTERS="$CONDA_PREFIX/share/trimmomatic/adapters/NexteraPE-PE.fa"

mkdir -p "$OUT_BASE"

shopt -s nullglob

R1_FILES=(
  "$RAW_DIR"/*_R1_001.fastq.gz
  "$RAW_DIR"/*_R1.fastq.gz
)

if [[ ${#R1_FILES[@]} -eq 0 ]]; then
  echo "ERROR: No R1 FASTQ.GZ files found in $RAW_DIR" >&2
  exit 1
fi

for R1 in "${R1_FILES[@]}"; do
  f=$(basename "$R1")

  sample=""
  R2=""

  if [[ "$f" =~ ^(.+)_R1_001\.fastq\.gz$ ]]; then
    sample="${BASH_REMATCH[1]}"
    R2="$RAW_DIR/${sample}_R2_001.fastq.gz"
  elif [[ "$f" =~ ^(.+)_R1\.fastq\.gz$ ]]; then
    sample="${BASH_REMATCH[1]}"
    R2="$RAW_DIR/${sample}_R2.fastq.gz"
  else
    echo "Skipping unrecognized R1 name: $f"
    continue
  fi

  if [[ ! -f "$R2" ]]; then
    echo "WARNING: Missing R2 for sample '$sample' — skipping"
    continue
  fi

  echo "==============================================="
  echo "Cohort:  $COHORT"
  echo "Sample:  $sample"
  echo "R1:      $R1"
  echo "R2:      $R2"
  echo "Out:     $OUT_BASE"
  echo "==============================================="

  kneaddata \
    -i1 "$R1" \
    -i2 "$R2" \
    -o "$OUT_BASE" \
    --output-prefix "$sample" \
    -db "$DB_BOWTIE2" \
    -t "$SLURM_CPUS_PER_TASK" \
    --run-trf \
    --run-fastqc-end \
    --trimmomatic-options "ILLUMINACLIP:${TRIM_ADAPTERS}:2:30:10:8:true LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:90"

  echo "Finished kneaddata for $sample"
  echo "Cleaning up (keeping trimmed + final outputs)..."

  rm -f "$OUT_BASE/${sample}"*_hg39_bowtie2_*contam*.fastq
  rm -f "$OUT_BASE/${sample}.repeats.removed."*.fastq
  rm -f "$OUT_BASE/${sample}_kneaddata.repeats.removed."*.fastq

  echo "Done cleanup for $sample"
  echo
done

