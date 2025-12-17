#!/bin/bash

# Default values for command-line arguments
fastq_file_a=""
fastq_file_b=""
output_dir="."  # Default output directory is the current directory
num_lines=100000000  # Default number of lines to extract

show_help() {
  cat <<EOM
Usage: $0 [--output-dir=<output_directory>] [--lines=<num_lines>] <fastq_file_a> <fastq_file_b>

Options:
  --output-dir=<output_directory> Specify the output directory (default: current directory).
  --lines=<num_lines>            Specify the number of lines to extract (default: 100000000).
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
    --lines=*)
      num_lines="${1#*=}"
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      if [ -z "$fastq_file_a" ]; then
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

# Check if both fastq files are provided
if [ -z "$fastq_file_a" ] || [ -z "$fastq_file_b" ]; then
  echo "Error: Both fastq files are required."
  show_help
  exit 1
fi

# Check if the specified output directory exists and create it if not
if [ ! -d "$output_dir" ]; then
  mkdir -p "$output_dir" || die "Error: Unable to create the output directory '$output_dir'."
fi

samtools fqidx "$fastq_file_a"
samtools fqidx "$fastq_file_b"

cat "${fastq_file_a}.fai" | cut -f 1 > "${output_dir}/a_ridlist.txt"

while read -r rid;
do
    echo -n -e "$rid\t"
    samtools fqidx "$fastq_file_a" "$rid" -n "$num_lines" > "${output_dir}/a_tmp.fastq"
    samtools fqidx "$fastq_file_b" "$rid" -n "$num_lines" > "${output_dir}/b_tmp.fastq"
    minimap2 -cx map-ont --secondary=no "${output_dir}/a_tmp.fastq" "${output_dir}/b_tmp.fastq" -t1 | awk '{print $10/$11}' | head -1 | tr -d '\n'
    echo
done < "${output_dir}/a_ridlist.txt" > "${output_dir}/perreadidentity.txt"
