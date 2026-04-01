#!/bin/bash

index_file=""
fastq_file_a=""
fastq_file_b=""
num_threads=32
output_dir="."
preset="map-ont"

show_help() {
  cat <<EOM
Usage: $0 [--output-dir=<output_directory>] [--threads=<num_threads>] [--preset=<minimap2_preset>] <index_file> <fastq_file_a> <fastq_file_b>

Options:
  --output-dir=<output_directory> Specify the output directory (default: current directory).
  --threads=<num_threads>        Specify the number of threads for minimap2 (default: 32).
  --preset=<minimap2_preset>     minimap2 -x preset (default: map-ont).
  -h, --help                     Display this help message.

Outputs:
  <output_dir>/perread_identity_a.txt   Per-read identity for fastq_file_a
  <output_dir>/perread_identity_b.txt   Per-read identity for fastq_file_b
  <output_dir>/joined.txt               Joined identities for reads present in both files
EOM
}

die() {
  echo "$1" >&2
  echo
  exit 1
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --output-dir=*) output_dir="${1#*=}" ;;
    --threads=*)    num_threads="${1#*=}" ;;
    --preset=*)     preset="${1#*=}" ;;
    -h|--help)      show_help; exit 0 ;;
    *)
      if [ -z "$index_file" ]; then
        index_file="$1"
      elif [ -z "$fastq_file_a" ]; then
        fastq_file_a="$1"
      elif [ -z "$fastq_file_b" ]; then
        fastq_file_b="$1"
      else
        echo "Invalid argument: $1"
        show_help
        exit 1
      fi
      ;;
  esac
  shift
done

if [ -z "$index_file" ] || [ -z "$fastq_file_a" ] || [ -z "$fastq_file_b" ]; then
  echo "Error: The index file and two fastq files are required."
  show_help
  exit 1
fi

if [ ! -d "$output_dir" ]; then
  mkdir -p "$output_dir" || die "Error: Unable to create the output directory '$output_dir'."
fi

minimap2 -cx "$preset" "$index_file" -t "$num_threads" --secondary=no "$fastq_file_a" | awk '{print $1"\t"$10/$11}' > "${output_dir}/perread_identity_a.txt"

minimap2 -cx "$preset" "$index_file" -t "$num_threads" --secondary=no "$fastq_file_b" | awk '{print $1"\t"$10/$11}' > "${output_dir}/perread_identity_b.txt"

join "${output_dir}/perread_identity_a.txt" "${output_dir}/perread_identity_b.txt" > "${output_dir}/joined.txt"
