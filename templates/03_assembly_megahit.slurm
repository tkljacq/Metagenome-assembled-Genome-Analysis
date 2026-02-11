#!/bin/bash
#SBATCH --job-name=megahit
#SBATCH --partition=cpu1.largem
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G

set -eo pipefail

# ===============================
# User setting (EDIT THIS ONLY)
# ===============================
COHORT="healthy1"

# ===============================
# Environment
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-moshpit-2025.7

# ===============================
# Directories
# ===============================
IN_DIR="/home/jtay0094/MAGs/${COHORT}/kneaddata"
OUT_BASE="/home/jtay0094/MAGs/${COHORT}/assembly"

mkdir -p "$OUT_BASE"
shopt -s nullglob

# Expect KneadData paired outputs:
#   <sample>_paired_1.fastq
#   <sample>_paired_2.fastq
P1_FILES=("$IN_DIR"/*_paired_1.fastq)

if [[ ${#P1_FILES[@]} -eq 0 ]]; then
  echo "ERROR: No '*_paired_1.fastq' files found in $IN_DIR" >&2
  exit 1
fi

for P1 in "${P1_FILES[@]}"; do
  base=$(basename "$P1")
  sample="${base%%_paired_1.fastq}"
  P2="$IN_DIR/${sample}_paired_2.fastq"

  if [[ ! -f "$P2" ]]; then
    echo "WARNING: Missing paired_2 for sample '$sample' — skipping"
    continue
  fi

  SAMPLE_DIR="$OUT_BASE/$sample"
  MEGAHIT_DIR="$SAMPLE_DIR/megahit"
  CONTIGS="$MEGAHIT_DIR/final.contigs.fa"
  QUAST_DIR="$SAMPLE_DIR/quast"

  mkdir -p "$SAMPLE_DIR"

  echo "==============================================="
  echo "Cohort: $COHORT"
  echo "Sample: $sample"
  echo "==============================================="

  # ----- MEGAHIT -----
  if [[ -f "$CONTIGS" ]]; then
    echo "MEGAHIT contigs already exist — skipping assembly"
  else
    if [[ -d "$MEGAHIT_DIR" ]]; then
      rm -rf "$MEGAHIT_DIR"
    fi

    megahit \
      -1 "$P1" \
      -2 "$P2" \
      -o "$MEGAHIT_DIR" \
      -t "$SLURM_CPUS_PER_TASK" \
      --presets meta-sensitive \
      --min-contig-len 500
  fi

  # ----- QUAST -----
  if [[ -f "$CONTIGS" ]]; then
    if [[ -f "$QUAST_DIR/report.html" || -f "$QUAST_DIR/report.tsv" || -f "$QUAST_DIR/report.txt" ]]; then
      echo "QUAST already exists — skipping"
    else
      mkdir -p "$QUAST_DIR"
      quast.py "$CONTIGS" \
        -o "$QUAST_DIR" \
        -t "$SLURM_CPUS_PER_TASK" \
        --min-contig 500
    fi
  fi

  echo "Done $sample"
  echo
done

echo "All assemblies completed."

