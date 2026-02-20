#!/bin/bash
#SBATCH --job-name=metabat
#SBATCH --partition=cpu1.largem
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=2-00:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G

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

THREADS="${SLURM_CPUS_PER_TASK}"
SEED="100"

# ===============================
# Inputs (from 04_indexmapping.slurm)
# ===============================
IN_BASE="/home/jtay0094/MAGs/${COHORT}/assembly/indexmapping"
CONTIGS_QZA="${IN_BASE}/contigs.qza"
ALN_QZA="${IN_BASE}/reads-to-contigs-aln.qza"

# ===============================
# Outputs (new structure)
# ===============================
OUT_BASE="/home/jtay0094/MAGs/${COHORT}/binning/metabat"
mkdir -p "$OUT_BASE"

MAGS_QZA="${OUT_BASE}/mags.qza"
CONTIG_MAP_QZA="${OUT_BASE}/contig-map.qza"
UNBINNED_QZA="${OUT_BASE}/unbinned-contigs.qza"

# ===============================
# Sanity checks
# ===============================
[[ -f "$CONTIGS_QZA" ]] || { echo "Missing: $CONTIGS_QZA" >&2; exit 1; }
[[ -f "$ALN_QZA" ]]     || { echo "Missing: $ALN_QZA" >&2; exit 1; }

# ===============================
# Run MetaBAT2 binning (mosh)
# ===============================
mosh annotate bin-contigs-metabat \
  --i-contigs "$CONTIGS_QZA" \
  --i-alignment-maps "$ALN_QZA" \
  --p-num-threads "$THREADS" \
  --p-seed "$SEED" \
  --p-verbose \
  --o-mags "$MAGS_QZA" \
  --o-contig-map "$CONTIG_MAP_QZA" \
  --o-unbinned-contigs "$UNBINNED_QZA" \
  --verbose

echo "Done. Outputs:"
echo "  $MAGS_QZA"
echo "  $CONTIG_MAP_QZA"
echo "  $UNBINNED_QZA"

