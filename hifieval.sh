#!/usr/bin/env bash
set -euo pipefail

now() { date +"%Y-%m-%d %H:%M:%S"; }

# Usage: hifieval.sh <prefix> <reads1.fq> <reads2.fq> <orig.fa> [reference.fa]
PREFIX="${1:-}"
READ1="${2:-}"
READ2="${3:-}"
ORIG_FA="${4:-}"
REF="${5:-}"

if [ -z "$PREFIX" ] || [ -z "$READ1" ] || [ -z "$READ2" ] || [ -z "$ORIG_FA" ]; then
  echo "Usage: $0 <prefix> <reads1.fq> <reads2.fq> <orig.fa> [reference.fa]" >&2
  exit 1
fi

if [ -z "$REF" ]; then
  echo "Error: reference FASTA not provided. Pass as arg5." >&2
  exit 1
fi

# Build hifiasm if HIFIASM_SRC is set; otherwise assume hifiasm in PATH
if [ -n "${HIFIASM_SRC:-}" ]; then
  make -C "$HIFIASM_SRC" clean && make -C "$HIFIASM_SRC"
fi

notify.sh "hifiasm $PREFIX started with $READ1 and $READ2 @ $(now)"

hifiasm --ont -t 48 -j --hg-size 3g --write-paf --write-ec -o "$PREFIX" "$READ1" "$READ2" 1>out.log 2>err.log

notify.sh "hifiasm $PREFIX completed @ $(now)"

# Convert GFA to FASTA and merge haplotypes
gfa2fa.sh "$PREFIX.bp.hap2.p_ctg.gfa" > "$PREFIX.bp.hap2.p_ctg.fa"
gfa2fa.sh "$PREFIX.bp.hap1.p_ctg.gfa" > "$PREFIX.bp.hap1.p_ctg.fa"
cat "$PREFIX.bp.hap1.p_ctg.fa" "$PREFIX.bp.hap2.p_ctg.fa" > "$PREFIX.bp.hap1+hap2.p_ctg.fa"

# get timings (parse_log is an alias to: python3 bioinformatics_scripts/parse_err_log.py)
parse_log err.log
notify.sh "quast $PREFIX hap1+2 vs $ORIG_FA started @ $(now)"

# Run QUAST comparing provided original FASTA to derived assembly FASTA
quast.py -r "$REF" -t 48 "$ORIG_FA" "./$PREFIX.bp.hap1+hap2.p_ctg.fa"

notify.sh "quast $PREFIX hap1+2 vs $ORIG_FA done @ $(now)"

which telostats.sh || true

telostats.sh "./$PREFIX.bp.hap1+hap2.p_ctg.fa"

