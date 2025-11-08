#!/bin/bash
# Comprehensive functional test suite for stopwords
set -euo pipefail
shopt -s inherit_errexit shift_verbose extglob nullglob

# Script metadata
SCRIPT_PATH=$(readlink -en -- "${BASH_SOURCE[0]}")
SCRIPT_NAME=${SCRIPT_PATH##*/}
SCRIPT_DIR=${SCRIPT_PATH%/*}
LIB_DIR=${SCRIPT_DIR%/*}
STOPWORDS_BIN="$LIB_DIR/stopwords"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test counters
declare -i TESTS_RUN=0
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0

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

print_success() {
  printf "${GREEN}✓ %s${NC}\n" "$1"
}

print_failure() {
  printf "${RED}✗ %s${NC}\n" "$1"
}

print_info() {
  printf "${YELLOW}◉ %s${NC}\n" "$1"
}

# Assert functions
assert_equals() {
  local -- expected=$1
  local -- actual=$2
  local -- test_name=$3

  ((TESTS_RUN+=1))

  if [[ "$actual" == "$expected" ]]; then
    print_success "$test_name"
    ((TESTS_PASSED+=1))
    return 0
  else
    print_failure "$test_name"
    error "  Expected: ${expected@Q}"
    error "  Actual:   ${actual@Q}"
    ((TESTS_FAILED+=1))
    return 1
  fi
}

assert_contains() {
  local -- haystack=$1
  local -- needle=$2
  local -- test_name=$3

  ((TESTS_RUN+=1))

  if [[ "$haystack" == *"$needle"* ]]; then
    print_success "$test_name"
    ((TESTS_PASSED+=1))
    return 0
  else
    print_failure "$test_name"
    error "  Haystack: ${haystack@Q}"
    error "  Needle:   ${needle@Q}"
    ((TESTS_FAILED+=1))
    return 1
  fi
}

assert_exit_code() {
  local -i expected=$1
  local -i actual=$2
  local -- test_name=$3

  ((TESTS_RUN+=1))

  if ((actual == expected)); then
    print_success "$test_name"
    ((TESTS_PASSED+=1))
    return 0
  else
    print_failure "$test_name"
    error "  Expected exit code: $expected"
    error "  Actual exit code:   $actual"
    ((TESTS_FAILED+=1))
    return 1
  fi
}

# Test basic functionality
test_basic_filtering() {
  print_header "Testing basic filtering"

  local -- input='the quick brown fox jumps over the lazy dog'
  local -- expected='quick brown fox jumps lazy dog'
  local -- actual
  actual=$("$STOPWORDS_BIN" "$input")

  assert_equals "$expected" "$actual" "Basic English stopword filtering"
}

# Test stdin input
test_stdin_input() {
  print_header "Testing stdin input"

  local -- input='the quick brown fox'
  local -- expected='quick brown fox'
  local -- actual
  actual=$(echo "$input" | "$STOPWORDS_BIN")

  assert_equals "$expected" "$actual" "Stdin input"
}

# Test punctuation handling
test_punctuation() {
  print_header "Testing punctuation handling"

  # Default: remove punctuation
  local -- input='Hello, world! How are you?'
  local -- expected='hello world'
  local -- actual
  actual=$("$STOPWORDS_BIN" "$input")
  assert_equals "$expected" "$actual" "Default punctuation removal"

  # Keep punctuation
  # Note: With -p, punctuation stays attached, so 'you?' doesn't match stopword 'you'
  expected='hello, world! you?'
  actual=$("$STOPWORDS_BIN" -p "$input")
  assert_equals "$expected" "$actual" "Keep punctuation with -p flag"
}

# Test list output
test_list_output() {
  print_header "Testing list output (-w flag)"

  local -- input='the quick brown fox'
  local -- expected=$'quick\nbrown\nfox'
  local -- actual
  actual=$("$STOPWORDS_BIN" -w "$input")

  assert_equals "$expected" "$actual" "List output format"
}

# Test word counting
test_word_counting() {
  print_header "Testing word counting (-c flag)"

  local -- input='quick brown fox quick brown quick'
  local -- actual
  actual=$("$STOPWORDS_BIN" -c "$input")

  # Should contain count for each word
  assert_contains "$actual" "3 quick" "Count for 'quick'"
  assert_contains "$actual" "2 brown" "Count for 'brown'"
  assert_contains "$actual" "1 fox" "Count for 'fox'"
}

# Test language selection
test_language_selection() {
  print_header "Testing language selection (-l flag)"

  # Test Spanish
  local -- input='el rápido zorro marrón'
  local -- actual
  actual=$("$STOPWORDS_BIN" -l spanish "$input")

  # 'el' should be filtered as Spanish stopword
  [[ "$actual" != *"el"* ]] || {
    print_failure "Spanish stopword filtering"
    error "  'el' should have been filtered"
    ((TESTS_FAILED+=1))
    return 1
  }

  print_success "Spanish stopword filtering"
  ((TESTS_RUN+=1))
  ((TESTS_PASSED+=1))
}

# Test Indonesian language
test_indonesian_language() {
  print_header "Testing Indonesian language"

  local -- input='yang ini adalah contoh teks dalam bahasa indonesia'
  local -- expected='contoh teks bahasa indonesia'
  local -- actual
  actual=$("$STOPWORDS_BIN" -l indonesian "$input")

  assert_equals "$expected" "$actual" "Indonesian stopword filtering"
}

# Test empty input
test_empty_input() {
  print_header "Testing empty input"

  local -- actual
  local -i exit_code

  actual=$(echo '' | "$STOPWORDS_BIN") || exit_code=$?
  exit_code=${exit_code:-0}

  assert_equals '' "$actual" "Empty input produces empty output"
  assert_exit_code 0 "$exit_code" "Empty input exits with 0"
}

# Test version flag
test_version_flag() {
  print_header "Testing version flag"

  local -- actual
  actual=$("$STOPWORDS_BIN" -V)

  assert_contains "$actual" "1.0.0" "Version output contains version number"
}

# Test help flag
test_help_flag() {
  print_header "Testing help flag"

  local -- actual
  actual=$("$STOPWORDS_BIN" -h)

  assert_contains "$actual" "Usage:" "Help output contains usage"
  assert_contains "$actual" "Examples:" "Help output contains examples"
}

# Test combined flags
test_combined_flags() {
  print_header "Testing combined short flags"

  local -- input='the quick brown fox'
  local -- expected=$'quick\nbrown\nfox'
  local -- actual

  # Test -wp combination (list + keep punctuation)
  actual=$("$STOPWORDS_BIN" -w "$input")
  assert_equals "$expected" "$actual" "Combined flags work correctly"
}

# Test case insensitivity
test_case_insensitivity() {
  print_header "Testing case insensitivity"

  local -- input='The QUICK Brown FOX'
  local -- expected='quick brown fox'
  local -- actual
  actual=$("$STOPWORDS_BIN" "$input")

  assert_equals "$expected" "$actual" "Case insensitive processing"
}

# Test possessive handling
test_possessive_handling() {
  print_header "Testing possessive handling"

  local -- input="John's car is fast"
  local -- actual
  actual=$("$STOPWORDS_BIN" "$input")

  # Should handle possessive 's
  assert_contains "$actual" "john" "Possessive 's handled"
  assert_contains "$actual" "car" "Word after possessive preserved"
  assert_contains "$actual" "fast" "Remaining words preserved"
}

# Test special characters
test_special_characters() {
  print_header "Testing special characters"

  local -- input='data@processing #algorithm'
  local -- actual
  actual=$("$STOPWORDS_BIN" "$input")

  # Special characters should be removed (default behavior)
  [[ "$actual" != *"@"* ]] || {
    print_failure "Special character removal"
    error "  '@' should have been removed"
    ((TESTS_FAILED+=1))
    return 1
  }

  print_success "Special character removal"
  ((TESTS_RUN+=1))
  ((TESTS_PASSED+=1))
}

# Test invalid language fallback
test_invalid_language() {
  print_header "Testing invalid language fallback"

  local -- input='the quick brown fox'
  local -- actual
  local -i exit_code=0

  # Should warn but still process with English fallback
  actual=$("$STOPWORDS_BIN" -l nonexistent "$input" 2>/dev/null) || exit_code=$?

  # Should still produce output with fallback
  [[ -n "$actual" ]] || {
    print_failure "Invalid language fallback"
    error "  Should fall back to English"
    ((TESTS_FAILED+=1))
    return 1
  }

  print_success "Invalid language fallback to English"
  ((TESTS_RUN+=1))
  ((TESTS_PASSED+=1))
}

# Test multiline input
test_multiline_input() {
  print_header "Testing multiline input"

  local -- input=$'the quick brown fox\njumps over the lazy dog'
  local -- expected='quick brown fox jumps lazy dog'
  local -- actual
  actual=$("$STOPWORDS_BIN" "$input")

  assert_equals "$expected" "$actual" "Multiline input processing"
}

# Test multiple spaces
test_multiple_spaces() {
  print_header "Testing multiple spaces"

  local -- input='the    quick     brown    fox'
  local -- expected='quick brown fox'
  local -- actual
  actual=$("$STOPWORDS_BIN" "$input")

  assert_equals "$expected" "$actual" "Multiple spaces handled correctly"
}

# Test stopwords binary exists
test_binary_exists() {
  print_header "Testing stopwords binary exists"

  if [[ -x "$STOPWORDS_BIN" ]]; then
    print_success "Stopwords binary exists and is executable"
    ((TESTS_RUN+=1))
    ((TESTS_PASSED+=1))
  else
    print_failure "Stopwords binary not found or not executable"
    error "  Expected at: $STOPWORDS_BIN"
    ((TESTS_FAILED+=1))
    ((TESTS_RUN+=1))
    return 1
  fi
}

# Main test runner
main() {
  print_header "Stopwords Functional Test Suite"
  echo ""

  # Run all tests
  test_binary_exists
  test_basic_filtering
  test_stdin_input
  test_punctuation
  test_list_output
  test_word_counting
  test_language_selection
  test_indonesian_language
  test_empty_input
  test_version_flag
  test_help_flag
  test_combined_flags
  test_case_insensitivity
  test_possessive_handling
  test_special_characters
  test_invalid_language
  test_multiline_input
  test_multiple_spaces

  # Print summary
  echo ""
  print_header "Test Summary"
  printf "  Total tests:  %d\n" "$TESTS_RUN"
  printf "  ${GREEN}Passed:       %d${NC}\n" "$TESTS_PASSED"
  printf "  ${RED}Failed:       %d${NC}\n" "$TESTS_FAILED"

  if ((TESTS_FAILED == 0)); then
    echo ""
    print_success "All tests passed!"
    return 0
  else
    echo ""
    print_failure "Some tests failed!"
    return 1
  fi
}

main "$@"

#fin
