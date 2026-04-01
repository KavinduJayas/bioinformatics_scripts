# bioinformatics_scripts

Utilities for long-read DNA assembly, evaluation, and read comparison.

---

## Assembly & Evaluation

### `hifieval.sh`
Full assembly evaluation pipeline. Runs hifiasm on two read sets, converts haplotype GFA outputs to FASTA, runs QUAST against a reference, and optionally runs telomere stats.

```bash
hifieval.sh [--threads=<n>] [--hg-size=<size>] [--preset=<preset>] [--ref=<reference.fa>] \
    <prefix> <reads1.fq> <reads2.fq> <orig.fa>
```

| Option | Default | Description |
|---|---|---|
| `--threads` | 48 | Threads for hifiasm and QUAST |
| `--hg-size` | 3g | Estimated genome size |
| `--preset` | ont | hifiasm sequencing preset (`ont`, `hifi`, etc.) |
| `--ref` | *(required)* | Reference FASTA for QUAST |

Set `HIFIASM_SRC` to a hifiasm source directory to build it automatically before running.

**Dependencies:** `hifiasm`, `quast.py`, `seqtk`, `awk`, `bash`; `telostats.sh` (optional)

---

### `gfa2fa.sh`
Convert GFA segment lines to FASTA. Reads from a file argument or stdin, writes to stdout.

```bash
gfa2fa.sh input.gfa > output.fa
cat input.gfa | gfa2fa.sh > output.fa
```

**Dependencies:** `awk`

---

### `parse_err_log.py`
Parse a hifiasm error log and write per-function timing intervals to CSV. With no arguments, globs `err*.log` in the current directory.

```bash
python3 parse_err_log.py [<err.log>] [output.csv]
```

Output defaults to `<logname>.timings.csv` alongside the log file.

**Dependencies:** Python 3 standard library

---

## Read Comparison

### `fqdiff.sh`
Compare two FASTQ files. Sorts both by read ID and diffs selected columns. Optionally subsets reads using a list file.

```bash
fqdiff.sh <fq1> <fq2> [list] [cutcols]
```

`cutcols` selects tab-separated columns after collapsing each 4-line FASTQ record (default: `1,2` — read ID and sequence; use `1,2,4` to include quality).

**Dependencies:** `seqtk`, `paste`, `sort`, `cut`, `diff`, `bash`

---

### `read2read_idscore_compare.sh`
Per-read identity between two FASTQ files by direct pairwise alignment. Iterates over every read in file A and aligns it to the matching read in file B. Slow but requires no pre-built index.

```bash
read2read_idscore_compare.sh [--output-dir=<dir>] [--lines=<n>] [--preset=<preset>] <fastq_a> <fastq_b>
```

Output: `perreadidentity.txt`

**Dependencies:** `samtools` (fqidx), `minimap2`, `awk`, `bash`

---

### `readwise_fqcompare.sh`
Per-read identity for two FASTQ files mapped against a shared reference index. Faster than read-to-read alignment for large datasets.

```bash
readwise_fqcompare.sh [--output-dir=<dir>] [--threads=<n>] [--preset=<preset>] <index_file> <fastq_a> <fastq_b>
```

Output: `perread_identity_a.txt`, `perread_identity_b.txt`, `joined.txt`

**Dependencies:** `minimap2`, `awk`, `join`, `bash`

---

## Utilities

### `notify.sh`
Send a Slack notification when a process finishes. Polls the given PID (or the calling shell if omitted) and POSTs to a webhook on exit.

```bash
notify.sh [<pid>] <process_name> [<webhook_url>]
```

Webhook falls back to the `SLACK_WEBHOOK` environment variable. Silently no-ops if neither is set.

**Dependencies:** `curl` (optional), `bash`

---

### `copy_bins.sh`
Copy hifiasm intermediate binary checkpoints between directories. Prompts before overwriting existing files.

```bash
copy_bins.sh <src_prefix> <dst_prefix>
```

Copies: `.ec.fq`, `.ec.bin`, `.ovlp.source.bin`, `.ovlp.reverse.bin`

**Dependencies:** `bash`, `cp`

---

## Notes

- All alignment scripts default to `--preset=map-ont`. Use `--preset=map-hifi` for PacBio HiFi reads.
- All Bash scripts use `set -euo pipefail` and validate inputs before processing.
