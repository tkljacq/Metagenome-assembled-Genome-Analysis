#!/bin/bash
#SBATCH --job-name=03_megahit_xx
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G

set -eo pipefail

# ===============================
# USER SETTINGS (EDIT THIS ONLY)
# ===============================
COHORT="healthy1"

# ===============================
# ENVIRONMENT
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-moshpit-2025.7

# ===============================
# DIRECTORIES
# ===============================
IN_DIR="/home/jtay0094/MAGs/${COHORT}/kneaddata"
ASSEMBLY_BASE="/home/jtay0094/MAGs/${COHORT}/assembly"
OUT_BASE="${ASSEMBLY_BASE}/${COHORT}"
CONTIGS_DIR="${ASSEMBLY_BASE}/contigs"

mkdir -p "$OUT_BASE" "$CONTIGS_DIR"
shopt -s nullglob

# Expected KneadData paired outputs:
#   <sample>_paired_1.fastq.gz
#   <sample>_paired_2.fastq.gz
P1_FILES=("$IN_DIR"/*_paired_1.fastq.gz)

if [[ ${#P1_FILES[@]} -eq 0 ]]; then
  echo "ERROR: No '*_paired_1.fastq.gz' files found in $IN_DIR" >&2
  exit 1
fi

for P1 in "${P1_FILES[@]}"; do
  BASE=$(basename "$P1")
  SAMPLE="${BASE%%_paired_1.fastq.gz}"
  P2="$IN_DIR/${SAMPLE}_paired_2.fastq.gz"

  if [[ ! -f "$P2" ]]; then
    echo "WARNING: Missing paired read for sample '$SAMPLE' — skipping"
    continue
  fi

  SAMPLE_DIR="$OUT_BASE/$SAMPLE"
  MEGAHIT_DIR="$SAMPLE_DIR/megahit"
  CONTIGS="$MEGAHIT_DIR/final.contigs.fa"
  QUAST_DIR="$SAMPLE_DIR/quast"
  FINAL_CONTIGS="$CONTIGS_DIR/${SAMPLE}_contigs.fasta"

  mkdir -p "$SAMPLE_DIR"

  echo "==============================================="
  echo "COHORT : $COHORT"
  echo "SAMPLE : $SAMPLE"
  echo "STEP   : MEGAHIT assembly + QUAST"
  echo "PARAMS : --min-contig-len 1000"
  echo "==============================================="

  # ===============================
  # MEGAHIT
  # ===============================
  if [[ -f "$CONTIGS" ]]; then
    echo "MEGAHIT output exists — skipping assembly"
  else
    rm -rf "$MEGAHIT_DIR"

    megahit \
      -1 "$P1" \
      -2 "$P2" \
      -o "$MEGAHIT_DIR" \
      -t "$SLURM_CPUS_PER_TASK" \
      --presets meta-sensitive \
      --min-contig-len 1000
  fi

  # ===============================
  # EXPORT CONTIGS
  # ===============================
  if [[ -f "$CONTIGS" ]]; then
    cp -f "$CONTIGS" "$FINAL_CONTIGS"
    echo "Exported contigs: $FINAL_CONTIGS"
  else
    echo "WARNING: Contigs not found for sample '$SAMPLE'"
    continue
  fi

  # ===============================
  # QUAST
  # ===============================
  if [[ -f "$QUAST_DIR/report.html" || -f "$QUAST_DIR/report.tsv" || -f "$QUAST_DIR/report.txt" ]]; then
    echo "QUAST output exists — skipping"
  else
    mkdir -p "$QUAST_DIR"

    quast.py "$CONTIGS" \
      -o "$QUAST_DIR" \
      -t "$SLURM_CPUS_PER_TASK" \
      --min-contig 1000
  fi

  echo "Done: $SAMPLE"
  echo
done

echo "All assemblies completed."
