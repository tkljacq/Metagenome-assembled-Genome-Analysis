#!/bin/bash
#SBATCH --job-name=04_indexmap_xx
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=2-00:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=90G

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
COHORT="healthy1"

# ===============================
# ENVIRONMENT
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-moshpit-2025.7

# Force QIIME2 temp to project tmp (avoid /tmp full)
export TMPDIR="/home/jtay0094/MAGs/${COHORT}/assembly/tmp_q2"
mkdir -p "$TMPDIR"

THREADS="${SLURM_CPUS_PER_TASK}"
SEED="100"

# ===============================
# INPUTS
# ===============================
CONTIG_DIR="/home/jtay0094/MAGs/${COHORT}/assembly/contigs"
READS_DIR="/home/jtay0094/MAGs/${COHORT}/kneaddata"

# ===============================
# OUTPUTS
# ===============================
OUT_BASE="/home/jtay0094/MAGs/${COHORT}/assembly/indexmap"
mkdir -p "$OUT_BASE"

CONTIG_QZA="$OUT_BASE/contigs.qza"
INDEX_QZA="$OUT_BASE/contigs-index.qza"
READS_QZA="$OUT_BASE/reads.qza"
ALN_QZA="$OUT_BASE/reads-to-contigs-aln.qza"

# Use node-local tmp if available
CASAVA_DIR="${SLURM_TMPDIR:-$OUT_BASE}/casava_reads"

# ===============================
# HELPERS
# ===============================
copy_or_gzip_cmd() {
  local IN="$1"
  local OUT="$2"

  case "$IN" in
    *.gz)
      cp -f "$IN" "$OUT"
      ;;
    *)
      if command -v pigz >/dev/null 2>&1; then
        pigz -p "$THREADS" -c "$IN" > "$OUT"
      else
        gzip -c "$IN" > "$OUT"
      fi
      ;;
  esac
}

# ===============================
# CHECKS
# ===============================
[[ -d "$CONTIG_DIR" ]] || { echo "ERROR: Missing contigs dir: $CONTIG_DIR" >&2; exit 1; }
[[ -d "$READS_DIR"  ]] || { echo "ERROR: Missing reads dir:   $READS_DIR"  >&2; exit 1; }

# ===============================
# RUN
# ===============================

# 1) Import contigs
if [[ ! -f "$CONTIG_QZA" ]]; then
  echo "Importing contigs: $(date '+%Y-%m-%d %H:%M:%S')"
  qiime tools import \
    --type 'SampleData[Contigs]' \
    --input-path "$CONTIG_DIR" \
    --output-path "$CONTIG_QZA"
  echo "Finished importing contigs: $(date '+%Y-%m-%d %H:%M:%S')"
else
  echo "Contigs artifact exists — skipping import"
fi

# 2) Index contigs
if [[ ! -f "$INDEX_QZA" ]]; then
  echo "Indexing contigs: $(date '+%Y-%m-%d %H:%M:%S')"
  mosh assembly index-contigs \
    --i-contigs "$CONTIG_QZA" \
    --p-threads "$THREADS" \
    --p-seed "$SEED" \
    --o-index "$INDEX_QZA" \
    --verbose
  echo "Finished indexing contigs: $(date '+%Y-%m-%d %H:%M:%S')"
else
  echo "Contig index exists — skipping"
fi

# 3) Prepare Casava reads and import
if [[ ! -f "$READS_QZA" ]]; then
  echo "Preparing Casava reads: $(date '+%Y-%m-%d %H:%M:%S')"

  rm -rf "$CASAVA_DIR"
  mkdir -p "$CASAVA_DIR"

  shopt -s nullglob
  P1_FILES=("$READS_DIR"/*_paired_1.fastq.gz)

  if [[ ${#P1_FILES[@]} -eq 0 ]]; then
    echo "ERROR: No paired reads found in $READS_DIR (*_paired_1.fastq.gz)" >&2
    exit 1
  fi

  for P1 in "${P1_FILES[@]}"; do
    BASE=$(basename "$P1")
    SAMPLE="${BASE%%_paired_1.fastq.gz}"
    P2="$READS_DIR/${SAMPLE}_paired_2.fastq.gz"

    if [[ ! -f "$P2" ]]; then
      echo "WARNING: Missing paired read for sample '$SAMPLE' — skipping"
      continue
    fi

    OUT_R1="$CASAVA_DIR/${SAMPLE}_S1_L001_R1_001.fastq.gz"
    OUT_R2="$CASAVA_DIR/${SAMPLE}_S1_L001_R2_001.fastq.gz"

    copy_or_gzip_cmd "$P1" "$OUT_R1"
    copy_or_gzip_cmd "$P2" "$OUT_R2"
  done

  echo "Importing reads: $(date '+%Y-%m-%d %H:%M:%S')"
  qiime tools import \
    --type 'SampleData[PairedEndSequencesWithQuality]' \
    --input-path "$CASAVA_DIR" \
    --input-format CasavaOneEightSingleLanePerSampleDirFmt \
    --output-path "$READS_QZA"
  echo "Finished importing reads: $(date '+%Y-%m-%d %H:%M:%S')"
else
  echo "Reads artifact exists — skipping import"
fi

# 4) Map reads to contigs
if [[ ! -f "$ALN_QZA" ]]; then
  echo "Mapping reads to contigs: $(date '+%Y-%m-%d %H:%M:%S')"
  mosh assembly map-reads \
    --i-index "$INDEX_QZA" \
    --i-reads "$READS_QZA" \
    --p-threads "$THREADS" \
    --p-seed "$SEED" \
    --o-alignment-maps "$ALN_QZA" \
    --verbose
  echo "Finished mapping: $(date '+%Y-%m-%d %H:%M:%S')"
else
  echo "Alignment artifact exists — skipping mapping"
fi

# ===============================
# FINISH
# ===============================
END_TIME=$(date +%s)
RUNTIME=$((END_TIME - START_TIME))

echo "================================================="
echo "END: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Total runtime: ${RUNTIME} seconds"
echo "Outputs:"
echo "  $CONTIG_QZA"
echo "  $INDEX_QZA"
echo "  $READS_QZA"
echo "  $ALN_QZA"
echo "================================================="
