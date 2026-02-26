#!/bin/bash
#SBATCH --job-name=05_metabat
#SBATCH --partition=highprio
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=2-00:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G

set -eEo pipefail

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

# Force QIIME2 temp to project tmp (avoid /tmp full)
export TMPDIR="/home/jtay0094/MAGs/${COHORT}/assembly/tmp_q2"
mkdir -p "$TMPDIR"

THREADS="${SLURM_CPUS_PER_TASK}"
SEED="100"

# ===============================
# Inputs (from 04_indexmap.slurm)
# ===============================
IN_BASE="/home/jtay0094/MAGs/${COHORT}/assembly/indexmap"
CONTIGS_QZA="${IN_BASE}/contigs.qza"
ALN_QZA="${IN_BASE}/reads-to-contigs-aln.qza"

# ===============================
# Outputs
# ===============================
OUT_BASE="/home/jtay0094/MAGs/${COHORT}/binning/metabat"
mkdir -p "$OUT_BASE"

MAGS_QZA="${OUT_BASE}/mags.qza"
CONTIG_MAP_QZA="${OUT_BASE}/contig-map.qza"
UNBINNED_QZA="${OUT_BASE}/unbinned-contigs.qza"

# ===============================
# Checks
# ===============================
[[ -f "$CONTIGS_QZA" ]] || { echo "ERROR: Missing: $CONTIGS_QZA" >&2; exit 1; }
[[ -f "$ALN_QZA" ]]     || { echo "ERROR: Missing: $ALN_QZA" >&2; exit 1; }

# ===============================
# Run MetaBAT2 binning (mosh)
# ===============================
if [[ ! -f "$MAGS_QZA" || ! -f "$CONTIG_MAP_QZA" || ! -f "$UNBINNED_QZA" ]]; then
  echo "Starting MetaBAT2 binning at: $(date)"
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
  echo "Finished MetaBAT2 binning at: $(date)"
else
  echo "Outputs already exist — skipping binning."
fi

echo "==============================================="
echo "Done at: $(date)"
echo "Outputs:"
echo "  $MAGS_QZA"
echo "  $CONTIG_MAP_QZA"
echo "  $UNBINNED_QZA"
echo "==============================================="
echo "Job finished at: $(date)"
echo "==============================================="
