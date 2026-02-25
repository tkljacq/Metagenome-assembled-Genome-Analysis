#!/bin/bash
#SBATCH --job-name=08_repackderep
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G

set -eo pipefail
echo "START: $(date)"

# ===============================
# User setting (EDIT THIS ONLY)
# ===============================
COHORT="REPLACE_ME"
TAG="DEREP098"   # sample-id label in MANIFEST

# ===============================
# Environment
# ===============================
source /home/jtay0094/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-moshpit-2025.7

# ===============================
# Paths
# ===============================
BASE="/home/jtay0094/MAGs/${COHORT}"

IN_DEREP="$BASE/binning/derep_thr098/mags_derep.qza"             # FeatureData[MAG]
OUT_QZA="$BASE/binning/derep_thr098/mags_derep_sampledata.qza"  # SampleData[MAGs]

WORK="$BASE/binning/derep_thr098/repack"
EXPORT_DIR="$WORK/export"
WRAP_DIR="$WORK/mags_derep_sampledata_dir"

# ===============================
# Checks
# ===============================
[[ -f "$IN_DEREP" ]] || { echo "ERROR: Missing $IN_DEREP" >&2; exit 1; }

# ===============================
# Repack
# ===============================
rm -rf "$WORK"
mkdir -p "$WORK"

qiime tools export \
  --input-path "$IN_DEREP" \
  --output-path "$EXPORT_DIR"

rm -rf "$WRAP_DIR"
mkdir -p "$WRAP_DIR/data"

cp "$EXPORT_DIR"/*.fasta "$WRAP_DIR/data/"

echo "sample-id,mag-id,filename" > "$WRAP_DIR/MANIFEST"
for f in "$WRAP_DIR"/data/*.fasta; do
  id="$(basename "$f" .fasta)"
  echo "${TAG},${id},data/${id}.fasta"
done >> "$WRAP_DIR/MANIFEST"

qiime tools import \
  --type 'SampleData[MAGs]' \
  --input-path "$WRAP_DIR" \
  --input-format MultiMAGSequencesDirFmt \
  --output-path "$OUT_QZA"

echo "END: $(date)"
echo "Repacked MAGs: $OUT_QZA"
