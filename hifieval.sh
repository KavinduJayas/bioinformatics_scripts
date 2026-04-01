#!/usr/bin/env bash
set -euo pipefail

now() { date +"%Y-%m-%d %H:%M:%S"; }

usage() {
  echo "Usage: $0 [--threads=<n>] [--hg-size=<size>] [--preset=<preset>] <prefix> <reads1.fq> <reads2.fq> <orig.fa> <reference.fa>" >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  --threads=<n>       Number of threads for hifiasm and quast (default: 48)" >&2
  echo "  --hg-size=<size>    Estimated genome size passed to hifiasm (default: 3g)" >&2
  echo "  --preset=<preset>   hifiasm sequencing preset: ont, hifi, etc. (default: ont)" >&2
  exit 1
}

THREADS=48
HG_SIZE=3g
PRESET=ont

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --threads=*) THREADS="${1#*=}" ;;
    --hg-size=*) HG_SIZE="${1#*=}" ;;
    --preset=*)  PRESET="${1#*=}" ;;
    -h|--help)   usage ;;
    *) break ;;
  esac
  shift
done

PREFIX="${1:-}"
READ1="${2:-}"
READ2="${3:-}"
ORIG_FA="${4:-}"
REF="${5:-}"

if [ -z "$PREFIX" ] || [ -z "$READ1" ] || [ -z "$READ2" ] || [ -z "$ORIG_FA" ] || [ -z "$REF" ]; then
  usage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build hifiasm if HIFIASM_SRC is set; otherwise assume hifiasm in PATH
if [ -n "${HIFIASM_SRC:-}" ]; then
  make -C "$HIFIASM_SRC" clean && make -C "$HIFIASM_SRC"
fi

notify.sh "hifiasm $PREFIX started with $READ1 and $READ2 @ $(now)"

hifiasm "--${PRESET}" -t "$THREADS" -j --hg-size "$HG_SIZE" --write-paf --write-ec -o "$PREFIX" "$READ1" "$READ2" 1>out.log 2>err.log

notify.sh "hifiasm $PREFIX completed @ $(now)"

# Convert GFA to FASTA and merge haplotypes
gfa2fa.sh "$PREFIX.bp.hap2.p_ctg.gfa" > "$PREFIX.bp.hap2.p_ctg.fa"
gfa2fa.sh "$PREFIX.bp.hap1.p_ctg.gfa" > "$PREFIX.bp.hap1.p_ctg.fa"
cat "$PREFIX.bp.hap1.p_ctg.fa" "$PREFIX.bp.hap2.p_ctg.fa" > "$PREFIX.bp.hap1+hap2.p_ctg.fa"

# Extract per-function timings from hifiasm error log
python3 "$SCRIPT_DIR/parse_err_log.py" err.log timings.csv

notify.sh "quast $PREFIX hap1+2 vs $ORIG_FA started @ $(now)"

# Run QUAST comparing provided original FASTA to derived assembly FASTA
quast.py -r "$REF" -t "$THREADS" "$ORIG_FA" "./$PREFIX.bp.hap1+hap2.p_ctg.fa"

notify.sh "quast $PREFIX hap1+2 vs $ORIG_FA done @ $(now)"

if command -v telostats.sh &>/dev/null; then
  telostats.sh "./$PREFIX.bp.hap1+hap2.p_ctg.fa"
fi
