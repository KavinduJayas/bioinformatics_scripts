# bioinformatics_scripts
Automations for common manipulations and testing

## Dependencies
- hifieval.sh: hifiasm (in PATH or build via HIFIASM_SRC), quast.py, awk, coreutils, telostats.sh (optional), seqtk, bash
- gfa2fa.sh: awk
- fqdiff.sh: seqtk, coreutils (paste, sort, cut), diff, bash
- notify.sh: curl (optional), bash; uses SLACK_WEBHOOK env or positional arg
- readwise_fqcompare.sh: minimap2, awk, join, bash
- read2read_idscore_compare.sh: samtools (fqidx), minimap2, awk, bash
- parse_err_log.py: Python 3 standard library

## Scripts
- fqdiff.sh: Compare two FASTQ files; optional subset by read list; outputs sorted views and a diff of selected columns.
- gfa2fa.sh: Convert GFA segments (S lines) to FASTA.
- hifieval.sh: Run hifiasm on two read sets, convert/merge haplotypes, run QUAST; requires reference FASTA as arg5; can build hifiasm via HIFIASM_SRC.
- notify.sh: Notify when a PID/process finishes via Slack webhook or prints to stderr if webhook not set.
- parse_err_log.py: Parse hifiasm err.log to produce timings.csv with step durations.
- read2read_idscore_compare.sh: Per-read identity comparison between two FASTQ files using samtools fqidx and minimap2.
- readwise_fqcompare.sh: Compute per-read identities against an index for two FASTQ files and join results.
