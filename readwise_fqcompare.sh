#!/bin/bash

# Default values for command-line arguments
index_file=""
fastq_file_a=""
fastq_file_b=""
num_threads=32  # Default number of threads for minimap2
output_dir="."  # Default output directory is the current directory

show_help() {
  cat <<EOM
Usage: $0 [--output-dir=<output_directory>] [--threads=<num_threads>] <index_file> <fastq_file_a> <fastq_file_b>

Options:
  --output-dir=<output_directory> Specify the output directory (default: current directory).
  --threads=<num_threads>        Specify the number of threads for minimap2 (default: 32).
  -h, --help                     Display this help message.
EOM
}

die() {
  echo "$1" >&2
  echo
  exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --output-dir=*)
      output_dir="${1#*=}"
      ;;
    --threads=*)
      num_threads="${1#*=}"
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
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

# Check if all required arguments are provided
if [ -z "$index_file" ] || [ -z "$fastq_file_a" ] || [ -z "$fastq_file_b" ]; then
  echo "Error: The index file and two fastq files are required."
  show_help
  exit 1
fi

# Check if the specified output directory exists and create it if not
if [ ! -d "$output_dir" ]; then
  mkdir -p "$output_dir" || die "Error: Unable to create the output directory '$output_dir'."
fi

# Run minimap2 with specified arguments for fastq_file_a
minimap2 -cx map-ont "$index_file" -t "$num_threads" --secondary=no "$fastq_file_a" | awk '{print $1"\t"$10/$11}' > "${output_dir}/perread_identity_orig.txt"

# Run minimap2 with specified arguments for fastq_file_b
minimap2 -cx map-ont "$index_file" -t "$num_threads" --secondary=no "$fastq_file_b" | awk '{print $1"\t"$10/$11}' > "${output_dir}/perread_identity_rounded.txt"

# Join the output files
join "${output_dir}/perread_identity_orig.txt" "${output_dir}/perread_identity_rounded.txt" > "${output_dir}/joined.txt"
