#!/bin/bash
# script/module stopwords

stopwords() {
  # Script metadata
  local -- VERSION='1.0.0'
  local -- SCRIPT_PATH=$(readlink -en -- "${BASH_SOURCE[0]}")
  local -- DATADIR="${SCRIPT_PATH%/*}"/data
  local -- SCRIPT_NAME=${FUNCNAME[0]}

  # variables
  local -- DEFAULT_LANGUAGE=english
  local -- LANGUAGE="$DEFAULT_LANGUAGE"
  local -i KEEP_PUNCTUATION=0
  local -i LIST_WORDS=0
  local -i COUNT_WORDS=0
  local -- INPUT_TEXT=''

  # Error message to stderr
  error() {
    local -- msg
    for msg in "$@"; do
      >&2 printf '%s: %s\n' "$SCRIPT_NAME" "$msg"
    done
  }

  # Parse command-line arguments
  while (($#)); do
    case "$1" in
      -l|--language)
        [[ -n ${2:-} ]] || { error "Missing argument for option '$1'"; return 2; }
        LANGUAGE="$2"
        shift
        ;;
      -p|--keep-punctuation)
        KEEP_PUNCTUATION=1 ;;
      -w|--list-words)
        LIST_WORDS=1 ;;
      -c|--count)
        COUNT_WORDS=1 ;;
      -V|--version)
        echo "$SCRIPT_NAME $VERSION"; return 0 ;;
      -h|--help)
        if declare -F usage >/dev/null; then
          usage
        else
          error "No help in sourced script"
        fi
        return 0
        ;;
      -[lpwcVh]*) #shellcheck disable=SC2046  # Intentional word splitting for flag expansion
        set -- '' $(printf -- "-%c " $(grep -o . <<<"${1:1}")) "${@:2}" ;;
      -*)
        error "Invalid option '$1'"; return 22 ;;
      *)
        INPUT_TEXT+="$1 " ;;
    esac
    shift
  done

  [[ -d $DATADIR ]] || { error "Stopwords data directory '$DATADIR' not found."; return 1; }

  # Validate language
  local -- stopwords_file="$DATADIR"/"$LANGUAGE".txt
  if [[ ! -f "$stopwords_file" ]]; then
    error "Language '$LANGUAGE' not supported."
    >&2 echo 'Available languages:'
    for f in "$DATADIR"/*.txt; do
      [[ -f "$f" ]] && >&2 basename "$f" .txt
    done | >&2 tr '\n' ',' | >&2 sed 's/,/, /g' | >&2 sed 's/, $//'
    >&2 echo ''
    error "Falling back to 'english'"
    LANGUAGE=english
    stopwords_file="$DATADIR"/"$LANGUAGE".txt
    [[ -f "$stopwords_file" ]] || { error "Stopwords data/$LANGUAGE.txt not found!"; return 1; }
  fi

  # Load stopwords into associative array
  local -A stopwords
  local -- word
  while IFS= read -r word; do
    # Store lowercase version for case-insensitive matching
    stopwords["${word,,}"]=1
  done < "$stopwords_file"

  # Get input text
  [[ -n "$INPUT_TEXT" ]] || INPUT_TEXT=$(</dev/stdin) # Read from stdin

  # Exit early if input is empty
  [[ -z "$INPUT_TEXT" ]] && return 0

  # Convert to lowercase for processing
  local -- lower_text="${INPUT_TEXT,,}"

  # Tokenize and filter
  local -a filtered_words=()
  local -A word_counts=()

  if ((KEEP_PUNCTUATION)); then
    # Keep punctuation: split on whitespace only
    # Replace multiple spaces/tabs/newlines with single space
    while [[ "$lower_text" =~ [[:space:]][[:space:]] ]]; do
      lower_text="${lower_text//[[:space:]][[:space:]]/ }"
    done

    # Split into words using explicit array parsing
    local -a words
    IFS=' ' read -ra words <<< "$lower_text"
    for word in "${words[@]}"; do
      # Check if word is not a stopword
      if [[ ! -v stopwords["$word"] ]]; then
        if ((COUNT_WORDS)); then
          ((word_counts["$word"]+=1))
        else
          filtered_words+=("$word")
        fi
      fi
    done
  else
    # Remove punctuation: replace punctuation with spaces, then split
    # First, handle possessive 's by removing it
    lower_text="${lower_text//\'s / }"

    # Replace punctuation and special characters with spaces (optimized single tr call)
    lower_text=$(tr '[:punct:]\n\t' ' ' <<< "$lower_text")

    # Collapse multiple spaces
    while [[ "$lower_text" =~ '  ' ]]; do
      lower_text="${lower_text//  / }"
    done

    # Split into words using explicit array parsing
    local -a words
    IFS=' ' read -ra words <<< "$lower_text"
    for word in "${words[@]}"; do
      # Skip empty words
      [[ -n "$word" ]] || continue

      # Additional cleaning for special characters that might remain (combined)
      word="${word//[\`\"_\'\']/}"

      # Skip if word is now empty after cleaning
      [[ -n "$word" ]] || continue

      # Check if word is not a stopword
      if [[ ! -v stopwords["$word"] ]]; then
        if ((COUNT_WORDS)); then
          ((word_counts["$word"]+=1))
        else
          filtered_words+=("$word")
        fi
      fi
    done
  fi

  # Output results
  if ((COUNT_WORDS)); then
    # Output word frequency counts
    for word in "${!word_counts[@]}"; do
      printf '%d %s\n' "${word_counts[$word]}" "$word"
    done | sort -k1,2 -n
  elif ((LIST_WORDS)); then
    # Output one word per line
    printf '%s\n' "${filtered_words[@]}"
  else
    # Output as a single line with spaces
    if ((${#filtered_words[@]})); then
      echo "${filtered_words[*]}"
    fi
  fi

  return 0
}
declare -fx stopwords

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # Remove stopwords from text
  set -euo pipefail
  shopt -s inherit_errexit shift_verbose extglob nullglob

  declare -g VERSION SCRIPT_PATH SCRIPT_NAME DATADIR

  # Show usage information
  usage() {
    cat <<EOT
$SCRIPT_NAME $VERSION - Remove stopwords from text

Filters stopwords from input text based on the selected language.

Usage: $SCRIPT_NAME [OPTIONS] [TEXT]

Arguments:
  TEXT                   The input text. If not provided, read from stdin.

Options:
  -l|--language LANG     The language of the stopwords (default: english)
  -p|--keep-punctuation  Keep punctuation marks (default: remove punctuation)
  -w|--list-words        Output the filtered words as a list (one per line)
  -c|--count             Output word frequency counts (sorted by frequency)
  -V|--version           Show version information
  -h|--help              Show this help message

Available languages:
  $(for f in "$DATADIR"/*.txt; do [[ -f "$f" ]] && basename "$f" .txt; done | tr '\n' ',' | sed 's/,/, /g' | sed 's/, $//')

Examples:
  # Filter stopwords from text
  $SCRIPT_NAME 'the quick brown fox jumps over the lazy dog'

  # Read from stdin
  echo 'the quick brown fox' | $SCRIPT_NAME

  # Use Spanish stopwords
  $SCRIPT_NAME -l spanish 'el rápido zorro marrón'

  # User Indonesian stopwords
  $SCRIPT_NAME -l indonesian 'Pohon mangga tumbuh di halaman rumah.'

  # Keep punctuation
  $SCRIPT_NAME -p 'Hello, world!'

  # Output as list
  $SCRIPT_NAME -w 'How vexingly quick daft zebras jump!'

  # Word frequency count from file
  $SCRIPT_NAME -c < README.md
EOT
  }

  stopwords "$@"
fi

#fin
