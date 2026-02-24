#!/bin/bash
#SBATCH --job-name=indexmap
#SBATCH --partition=cpu1.largem
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=2-00:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G

set -eo pipefail

echo "==============================================="
echo "Job started at: $(date)"
echo "==============================================="

# ===============================
# User setting (EDIT THIS ONLY)
# ===============================
COHORT="healthy1"

# ===============================
# Environment
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-moshpit-2025.7

THREADS="${SLURM_CPUS_PER_TASK}"
SEED="100"

# ===============================
# Inputs
# ===============================
CONTIG_DIR="/home/jtay0094/MAGs/${COHORT}/assembly/contigs"
READS_DIR="/home/jtay0094/MAGs/${COHORT}/kneaddata"

# ===============================
# Outputs
# ===============================
OUT_BASE="/home/jtay0094/MAGs/${COHORT}/assembly/indexmap"
mkdir -p "$OUT_BASE"

CONTIG_QZA="$OUT_BASE/contigs.qza"
INDEX_QZA="$OUT_BASE/contigs-index.qza"
READS_QZA="$OUT_BASE/reads.qza"
ALN_QZA="$OUT_BASE/reads-to-contigs-aln.qza"

# Uses node-local tmp if available, otherwise falls back to OUT_BASE
CASAVA_DIR="${SLURM_TMPDIR:-$OUT_BASE}/casava_reads"

# ===============================
# Helpers
# ===============================
gzip_cmd() {
  if command -v pigz >/dev/null 2>&1; then
    pigz -p "$THREADS" -c "$1" > "$2"
  else
    gzip -c "$1" > "$2"
  fi
}

# ===============================
# Checks
# ===============================
[[ -d "$CONTIG_DIR" ]] || { echo "ERROR: Missing contigs dir: $CONTIG_DIR" >&2; exit 1; }
[[ -d "$READS_DIR" ]]  || { echo "ERROR: Missing reads dir:   $READS_DIR"  >&2; exit 1; }

# ===============================
# Run
# ===============================

# 1) Import contigs
if [[ ! -f "$CONTIG_QZA" ]]; then
  echo "Importing contigs at: $(date)"
  qiime tools import \
    --type 'SampleData[Contigs]' \
    --input-path "$CONTIG_DIR" \
    --output-path "$CONTIG_QZA"
  echo "Finished importing contigs at: $(date)"
fi

# 2) Index contigs
if [[ ! -f "$INDEX_QZA" ]]; then
  echo "Indexing contigs at: $(date)"
  mosh assembly index-contigs \
    --i-contigs "$CONTIG_QZA" \
    --p-threads "$THREADS" \
    --p-seed "$SEED" \
    --o-index "$INDEX_QZA" \
    --verbose
  echo "Finished indexing contigs at: $(date)"
fi

# 3) Prepare Casava-formatted paired reads and import reads
if [[ ! -f "$READS_QZA" ]]; then
  echo "Preparing Casava reads at: $(date)"
  rm -rf "$CASAVA_DIR"
  mkdir -p "$CASAVA_DIR"

  shopt -s nullglob
  P1_FILES=("$READS_DIR"/*_paired_1.fastq)

  if [[ ${#P1_FILES[@]} -eq 0 ]]; then
    echo "ERROR: No paired reads found in $READS_DIR (*_paired_1.fastq)" >&2
    exit 1
  fi

  for P1 in "${P1_FILES[@]}"; do
    base=$(basename "$P1")
    sample="${base%%_paired_1.fastq}"
    P2="$READS_DIR/${sample}_paired_2.fastq"

    if [[ ! -f "$P2" ]]; then
      echo "WARNING: Missing paired_2 for $sample — skipping"
      continue
    fi

    outR1="$CASAVA_DIR/${sample}_S1_L001_R1_001.fastq.gz"
    outR2="$CASAVA_DIR/${sample}_S1_L001_R2_001.fastq.gz"

    gzip_cmd "$P1" "$outR1"
    gzip_cmd "$P2" "$outR2"
  done

  echo "Importing reads at: $(date)"
  qiime tools import \
    --type 'SampleData[PairedEndSequencesWithQuality]' \
    --input-path "$CASAVA_DIR" \
    --input-format CasavaOneEightSingleLanePerSampleDirFmt \
    --output-path "$READS_QZA"
  echo "Finished importing reads at: $(date)"
fi

# 4) Map reads to contigs
if [[ ! -f "$ALN_QZA" ]]; then
  echo "Mapping reads to contigs at: $(date)"
  mosh assembly map-reads \
    --i-index "$INDEX_QZA" \
    --i-reads "$READS_QZA" \
    --p-threads "$THREADS" \
    --p-seed "$SEED" \
    --o-alignment-maps "$ALN_QZA" \
    --verbose
  echo "Finished mapping at: $(date)"
fi

echo "==============================================="
echo "Indexing and mapping completed at: $(date)"
echo "Outputs:"
echo "  $CONTIG_QZA"
echo "  $INDEX_QZA"
echo "  $READS_QZA"
echo "  $ALN_QZA"
echo "==============================================="
echo "Job finished at: $(date)"
echo "==============================================="
