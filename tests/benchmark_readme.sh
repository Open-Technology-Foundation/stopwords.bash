#!/bin/bash
# Performance benchmark using README.md as real-world input
set -euo pipefail
shopt -s inherit_errexit shift_verbose extglob nullglob

# Script metadata
SCRIPT_PATH=$(readlink -en -- "${BASH_SOURCE[0]}")
SCRIPT_NAME=${SCRIPT_PATH##*/}
SCRIPT_DIR=${SCRIPT_PATH%/*}
LIB_DIR=${SCRIPT_DIR%/*}

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Source the bash stopwords function
# shellcheck source=/dev/null
source "$LIB_DIR/stopwords.sh"

# Error message to stderr
error() {
  local -- msg
  for msg in "$@"; do
    >&2 printf '%s: %s\n' "$SCRIPT_NAME" "$msg"
  done
}

# Print colored output
print_header() {
  printf "${BLUE}%s${NC}\n" "$1"
}

print_result() {
  printf "${GREEN}%s${NC}\n" "$1"
}

# Benchmark bash implementation
benchmark_bash() {
  local -- test_file=$1
  local -i iterations=$2

  local -i start end elapsed
  start=$(date +%s%N)

  local -i i
  for ((i=0; i<iterations; i+=1)); do
    stopwords < "$test_file" > /dev/null
  done

  end=$(date +%s%N)
  elapsed=$((end - start))

  # Convert to milliseconds
  printf '%d' $((elapsed / 1000000))
}

# Benchmark python implementation
benchmark_python() {
  local -- test_file=$1
  local -i iterations=$2

  local -i start end elapsed
  start=$(date +%s%N)

  local -i i
  for ((i=0; i<iterations; i+=1)); do
    python3 "$SCRIPT_DIR/stopwords_python.py" < "$test_file" > /dev/null
  done

  end=$(date +%s%N)
  elapsed=$((end - start))

  # Convert to milliseconds
  printf '%d' $((elapsed / 1000000))
}

# Main benchmark
main() {
  local -- readme_file="$LIB_DIR/README.md"

  if [[ ! -f "$readme_file" ]]; then
    error "README.md not found at $readme_file"
    return 1
  fi

  print_header "Stopwords Performance Benchmark: README.md"
  echo ""

  # File info
  local -i word_count line_count
  word_count=$(wc -w < "$readme_file")
  line_count=$(wc -l < "$readme_file")

  printf "Input file: %s\n" "$readme_file"
  printf "File size: %s bytes\n" "$(wc -c < "$readme_file")"
  printf "Word count: %d words\n" "$word_count"
  printf "Line count: %d lines\n" "$line_count"
  echo ""

  # Test parameters
  local -i iterations=50

  printf "%-20s %-15s %-15s %-15s %-10s\n" \
    "Test" "Bash (ms)" "Python (ms)" "Difference" "Winner"
  printf "%s\n" "--------------------------------------------------------------------------------"

  local -i bash_time python_time diff
  local -- winner diff_str

  # Run benchmarks
  bash_time=$(benchmark_bash "$readme_file" "$iterations")
  python_time=$(benchmark_python "$readme_file" "$iterations")

  # Calculate difference
  diff=$((bash_time - python_time))

  if ((bash_time < python_time)); then
    winner="Bash"
    diff_str="${GREEN}-${diff#-} ms${NC}"
  elif ((python_time < bash_time)); then
    winner="Python"
    diff_str="${RED}+${diff#-} ms${NC}"
  else
    winner="Tie"
    diff_str="${YELLOW}0 ms${NC}"
  fi

  printf "%-20s %-15s %-15s %-15b %-10s\n" \
    "README.md" \
    "$bash_time" \
    "$python_time" \
    "$diff_str" \
    "$winner"

  # Calculate per-iteration time
  local -i bash_per_iter python_per_iter
  bash_per_iter=$((bash_time / iterations))
  python_per_iter=$((python_time / iterations))

  echo ""
  print_header "Per-Iteration Performance:"
  printf "  Bash: %d ms/iteration\n" "$bash_per_iter"
  printf "  Python: %d ms/iteration\n" "$python_per_iter"

  echo ""
  print_header "Test Configuration:"
  printf "  Iterations: %d\n" "$iterations"
  printf "  Python version: %s\n" "$(python3 --version 2>&1 | cut -d' ' -f2)"
  printf "  Bash version: %s\n" "$BASH_VERSION"
  echo ""
  print_result "Benchmark complete!"
}

main "$@"

#fin
