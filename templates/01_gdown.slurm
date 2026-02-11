#!/bin/bash
#SBATCH --job-name=gdown
#SBATCH --partition=cpu1
#SBATCH --output=/home/jtay0094/%x_%j.out
#SBATCH --error=/home/jtay0094/%x_%j.err
#SBATCH --time=2-00:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1

set -eo pipefail

# ===============================
# User setting (EDIT THIS ONLY)
# ===============================
COHORT="healthy1"

# ===============================
# Paths
# ===============================
GDOWN_BIN="$HOME/.conda/envs/metaprep/bin/gdown"

TARGET_DIR="/home/jtay0094/MAGs/rawreads/${COHORT}"
FILE_ID_LIST="/home/jtay0094/${COHORT}_ids"

FAILED_IDS_LOG="${TARGET_DIR}/gdown_failed_ids_${COHORT}.log"

mkdir -p "$TARGET_DIR"
: > "$FAILED_IDS_LOG"

echo "======================================="
echo "Cohort: $COHORT"
echo "Target: $TARGET_DIR"
echo "ID list: $FILE_ID_LIST"
echo "======================================="

cd "$TARGET_DIR"

while read -r FILE_ID; do
    [[ -z "$FILE_ID" ]] && continue

    echo "---------------------------------------"
    echo "Downloading file ID: $FILE_ID"
    echo "---------------------------------------"

    attempts=0
    max_attempts=3
    success=0

    while [[ $attempts -lt $max_attempts ]]; do
        attempts=$((attempts + 1))
        echo "  Attempt $attempts of $max_attempts"

        "$GDOWN_BIN" "https://drive.google.com/uc?id=${FILE_ID}" \
            --continue --fuzzy

        rc=$?
        if [[ $rc -eq 0 ]]; then
            echo "  Success: $FILE_ID"
            success=1
            break
        else
            echo "  gdown failed (exit code $rc)"
            if [[ $attempts -lt $max_attempts ]]; then
                echo "  Retrying in 60 seconds..."
                sleep 60
            fi
        fi
    done

    if [[ $success -eq 0 ]]; then
        echo "FAILED: $FILE_ID" | tee -a "$FAILED_IDS_LOG"
    fi

    echo
done < "$FILE_ID_LIST"

echo "All downloads attempted."
echo "Failure log (if any): $FAILED_IDS_LOG"

