#!/bin/bash
# install.sh - Installation script for stopwords.bash
set -euo pipefail
shopt -s inherit_errexit shift_verbose extglob nullglob

# Script metadata
readonly VERSION='1.0.0'
readonly SCRIPT_NAME='install.sh'
readonly PROJECT_NAME='stopwords'

# Get script directory
declare -- SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Installation configuration
declare -- PREFIX="${PREFIX:-/usr/local}"
declare -- BIN_DIR="$PREFIX/bin"
declare -- DOC_DIR="$PREFIX/share/doc/$PROJECT_NAME"
declare -- DATA_DIR="/usr/share/stopwords"

# Source files
readonly SOURCE_SCRIPT="$SCRIPT_DIR/stopwords"
readonly SOURCE_DATA="$SCRIPT_DIR/stopwords_data"
readonly SOURCE_README="$SCRIPT_DIR/README.md"
readonly SOURCE_LICENSE="$SCRIPT_DIR/LICENSE"

# Color output (if terminal supports it)
declare -i USE_COLOR=0
if [[ -t 1 ]]; then
  USE_COLOR=1
fi

# Output functions
msg() {
  printf '%s\n' "$*"
}

info() {
  if ((USE_COLOR)); then
    printf '\033[1;34m◉\033[0m %s\n' "$*"
  else
    printf '◉ %s\n' "$*"
  fi
}

success() {
  if ((USE_COLOR)); then
    printf '\033[1;32m✓\033[0m %s\n' "$*"
  else
    printf '✓ %s\n' "$*"
  fi
}

warning() {
  if ((USE_COLOR)); then
    >&2 printf '\033[1;33m▲\033[0m %s\n' "$*"
  else
    >&2 printf '▲ %s\n' "$*"
  fi
}

error() {
  if ((USE_COLOR)); then
    >&2 printf '\033[1;31m✗\033[0m %s\n' "$*"
  else
    >&2 printf '✗ %s\n' "$*"
  fi
}

# Check if we need sudo
needs_sudo() {
  local -- test_dir=$1
  [[ -w "$test_dir" ]] && return 1
  return 0
}

# Execute command with sudo if needed
run_install() {
  local -- target_dir=$1
  shift

  if needs_sudo "$target_dir" 2>/dev/null || ! [[ -w "$target_dir" ]]; then
    if [[ $EUID -ne 0 ]]; then
      info "Requesting sudo privileges for installation to $target_dir"
      sudo "$@"
    else
      "$@"
    fi
  else
    "$@"
  fi
}

# Detect if NLTK stopwords already installed
detect_nltk_stopwords() {
  local -a nltk_paths=(
    "${NLTK_DATA:-}/corpora/stopwords"
    "$HOME/nltk_data/corpora/stopwords"
    "/usr/share/nltk_data/corpora/stopwords"
    "/usr/local/share/nltk_data/corpora/stopwords"
  )

  local -- path
  for path in "${nltk_paths[@]}"; do
    [[ -z "$path" ]] && continue
    if [[ -d "$path" ]]; then
      local -i count
      count=$(find "$path" -type f ! -name README 2>/dev/null | wc -l)
      if ((count >= 30)); then
        echo "$path"
        return 0
      fi
    fi
  done
  return 1
}

# Show usage
usage() {
  cat <<EOT
$SCRIPT_NAME $VERSION - Installation script for $PROJECT_NAME

Usage: $SCRIPT_NAME [COMMAND] [OPTIONS]

Commands:
  install     Install $PROJECT_NAME (default command)
  uninstall   Remove $PROJECT_NAME installation
  check       Verify installation status

Environment Variables:
  PREFIX      Installation prefix (default: /usr/local)
              For user install: PREFIX=\$HOME/.local
  NLTK_DATA   If set, the script will check this location first for stopwords

Examples:
  # System-wide installation (requires sudo)
  sudo ./install.sh install

  # User-local installation (no sudo needed)
  PREFIX=\$HOME/.local ./install.sh install

  # Check installation status
  ./install.sh check

  # Uninstall
  sudo ./install.sh uninstall

Note:
  - If Python NLTK with stopwords is installed, data installation will be skipped
  - The script automatically detects and uses existing NLTK installations

Current Configuration:
  PREFIX:     $PREFIX
  BIN_DIR:    $BIN_DIR
  DOC_DIR:    $DOC_DIR
  DATA_DIR:   $DATA_DIR
EOT
}

# Verify source files exist
verify_sources() {
  local -i missing=0

  if [[ ! -f "$SOURCE_SCRIPT" ]]; then
    error "Source script not found: $SOURCE_SCRIPT"
    ((missing+=1))
  fi

  if [[ ! -d "$SOURCE_DATA" ]]; then
    error "Source data directory not found: $SOURCE_DATA"
    ((missing+=1))
  fi

  if [[ ! -f "$SOURCE_README" ]]; then
    warning "README.md not found (optional)"
  fi

  if [[ ! -f "$SOURCE_LICENSE" ]]; then
    warning "LICENSE not found (optional)"
  fi

  if ((missing)); then
    error "Missing required source files. Cannot proceed with installation."
    return 1
  fi

  return 0
}

# Install command
cmd_install() {
  info "Installing $PROJECT_NAME $VERSION"
  info "Installation prefix: $PREFIX"
  info "Stopwords data directory: $DATA_DIR"
  msg ""

  # Verify sources
  verify_sources || return 1

  # Check for existing NLTK installation
  local -- existing_nltk
  if existing_nltk=$(detect_nltk_stopwords); then
    info "Found existing NLTK stopwords: $existing_nltk"
    success "Skipping data installation - will use existing NLTK data"
    msg ""

    # Install only script and docs, skip data
    info "Installing script only..."

    # Create bin directory if needed
    if [[ ! -d "$BIN_DIR" ]]; then
      run_install "$(dirname "$BIN_DIR")" mkdir -p "$BIN_DIR"
    fi

    run_install "$BIN_DIR" install -m 755 "$SOURCE_SCRIPT" "$BIN_DIR/$PROJECT_NAME"
    success "Script installed to $BIN_DIR/$PROJECT_NAME"

    # Install documentation
    if [[ -f "$SOURCE_README" ]]; then
      if [[ ! -d "$DOC_DIR" ]]; then
        run_install "$(dirname "$DOC_DIR")" mkdir -p "$DOC_DIR"
      fi
      run_install "$DOC_DIR" cp "$SOURCE_README" "$DOC_DIR/"
      [[ -f "$SOURCE_LICENSE" ]] && run_install "$DOC_DIR" cp "$SOURCE_LICENSE" "$DOC_DIR/"
      success "Documentation installed to $DOC_DIR"
    fi

    msg ""
    success "Installation complete (using existing NLTK data at $existing_nltk)"
    msg ""

    # Quick verification
    info "Verifying installation..."
    cmd_check
    return $?
  fi

  info "NLTK stopwords not found - installing bundled data"
  msg ""

  # Create directories
  info "Creating installation directories..."

  if [[ ! -d "$BIN_DIR" ]]; then
    run_install "$(dirname "$BIN_DIR")" mkdir -p "$BIN_DIR"
  fi

  if [[ ! -d "$DOC_DIR" ]]; then
    run_install "$(dirname "$DOC_DIR")" mkdir -p "$DOC_DIR"
  fi

  if [[ ! -d "$DATA_DIR" ]]; then
    run_install "$(dirname "$DATA_DIR")" mkdir -p "$DATA_DIR"
  fi

  # Install script
  info "Installing script to $BIN_DIR/$PROJECT_NAME..."
  run_install "$BIN_DIR" install -m 755 "$SOURCE_SCRIPT" "$BIN_DIR/$PROJECT_NAME"
  success "Script installed"

  # Install data files
  info "Installing stopwords data (33 languages, ~170KB)..."
  local -- file
  local -i count=0
  for file in "$SOURCE_DATA"/*; do
    [[ -f "$file" ]] || continue
    run_install "$DATA_DIR" cp "$file" "$DATA_DIR/"
    ((count+=1))
  done
  success "Installed $count data files to $DATA_DIR"

  # Install documentation
  if [[ -f "$SOURCE_README" ]]; then
    info "Installing documentation..."
    run_install "$DOC_DIR" cp "$SOURCE_README" "$DOC_DIR/"
    [[ -f "$SOURCE_LICENSE" ]] && run_install "$DOC_DIR" cp "$SOURCE_LICENSE" "$DOC_DIR/"
    success "Documentation installed to $DOC_DIR"
  fi

  msg ""
  success "Installation complete!"
  msg ""

  # Check if installed location is in PATH
  if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    warning "Note: $BIN_DIR is not in your PATH"
    msg "    Add this to your ~/.bashrc or ~/.profile:"
    msg "    export PATH=\"$BIN_DIR:\$PATH\""
    msg ""
  fi

  # Check NLTK_DATA environment
  if [[ "$DATA_DIR" != "/usr/share/stopwords" ]] || [[ -v NLTK_DATA ]]; then
    info "NLTK_DATA configuration:"
    if [[ -v NLTK_DATA ]]; then
      msg "  Current: \$NLTK_DATA=$NLTK_DATA"
    fi
    msg "  Installed to: $DATA_DIR"
    if [[ ! -v NLTK_DATA ]] && [[ "$DATA_DIR" != "/usr/share/stopwords" ]]; then
      warning "You may need to set NLTK_DATA environment variable:"
      msg "    export NLTK_DATA=$DATA_DIR"
    fi
    msg ""
  fi

  # Quick verification
  info "Verifying installation..."
  if cmd_check; then
    success "All checks passed!"
  else
    warning "Some verification checks failed. Please review the output above."
  fi

  return 0
}

# Uninstall command
cmd_uninstall() {
  info "Uninstalling $PROJECT_NAME"
  msg ""

  local -i removed=0

  # Remove script
  if [[ -f "$BIN_DIR/$PROJECT_NAME" ]]; then
    info "Removing script from $BIN_DIR..."
    run_install "$BIN_DIR" rm -f "$BIN_DIR/$PROJECT_NAME"
    success "Script removed"
    ((removed+=1))
  else
    info "Script not found at $BIN_DIR/$PROJECT_NAME (already removed)"
  fi

  # Remove documentation
  if [[ -d "$DOC_DIR" ]]; then
    info "Removing documentation from $DOC_DIR..."
    run_install "$(dirname "$DOC_DIR")" rm -rf "$DOC_DIR"
    success "Documentation removed"
    ((removed+=1))
  else
    info "Documentation not found (already removed)"
  fi

  # Ask about data removal
  if [[ -d "$DATA_DIR" ]]; then
    msg ""
    warning "Stopwords data found at: $DATA_DIR"
    msg "    Remove data directory? [y/N] "
    local -- response
    read -r response
    if [[ "$response" =~ ^[Yy] ]]; then
      info "Removing stopwords data..."
      run_install "$(dirname "$DATA_DIR")" rm -rf "$DATA_DIR"
      success "Data removed"
      ((removed+=1))
    else
      info "Data directory preserved"
    fi
  else
    info "Data directory not found (already removed)"
  fi

  msg ""
  if ((removed)); then
    success "Uninstallation complete"
  else
    info "Nothing to uninstall (already clean)"
  fi

  return 0
}

# Check command
cmd_check() {
  local -i errors=0

  info "Checking $PROJECT_NAME installation..."
  msg ""

  # Check script installation
  if [[ -x "$BIN_DIR/$PROJECT_NAME" ]]; then
    success "Script found: $BIN_DIR/$PROJECT_NAME"
  else
    error "Script not found or not executable: $BIN_DIR/$PROJECT_NAME"
    ((errors+=1))
  fi

  # Check if in PATH
  if command -v "$PROJECT_NAME" >/dev/null 2>&1; then
    local -- found_path
    found_path=$(command -v "$PROJECT_NAME")
    success "Script in PATH: $found_path"
  else
    warning "Script not found in PATH"
    if [[ -x "$BIN_DIR/$PROJECT_NAME" ]]; then
      msg "    Script exists but $BIN_DIR not in PATH"
    fi
  fi

  # Check data directory
  if [[ -d "$DATA_DIR" ]]; then
    local -i file_count
    file_count=$(find "$DATA_DIR" -type f ! -name README | wc -l)
    if ((file_count >= 33)); then
      success "Data directory found: $DATA_DIR ($file_count files)"
    else
      error "Data directory incomplete: $DATA_DIR (expected 33+ files, found $file_count)"
      ((errors+=1))
    fi
  else
    error "Data directory not found: $DATA_DIR"
    ((errors+=1))
  fi

  # Check NLTK_DATA environment
  if [[ -v NLTK_DATA ]]; then
    if [[ "$NLTK_DATA" == "$DATA_DIR" ]]; then
      success "NLTK_DATA correctly set: $NLTK_DATA"
    else
      warning "NLTK_DATA mismatch: \$NLTK_DATA=$NLTK_DATA but data at $DATA_DIR"
    fi
  else
    if [[ "$DATA_DIR" == "/usr/share/stopwords" ]]; then
      info "NLTK_DATA not set (using default: /usr/share/stopwords)"
    else
      warning "NLTK_DATA not set (data installed to: $DATA_DIR)"
      msg "    Consider: export NLTK_DATA=$DATA_DIR"
    fi
  fi

  # Test functionality
  if command -v "$PROJECT_NAME" >/dev/null 2>&1; then
    info "Testing basic functionality..."
    if "$PROJECT_NAME" 'the quick brown fox' >/dev/null 2>&1; then
      success "Basic test passed"
    else
      error "Basic test failed"
      ((errors+=1))
    fi
  fi

  # Check documentation
  if [[ -d "$DOC_DIR" ]]; then
    success "Documentation found: $DOC_DIR"
  else
    info "Documentation not installed"
  fi

  msg ""
  if ((errors)); then
    error "Found $errors error(s)"
    return 1
  else
    success "All checks passed"
    return 0
  fi
}

# Main
main() {
  local -- command="${1:-install}"

  case "$command" in
    install)
      cmd_install
      ;;
    uninstall|remove)
      cmd_uninstall
      ;;
    check|verify|test)
      cmd_check
      ;;
    -h|--help|help)
      usage
      return 0
      ;;
    -V|--version|version)
      echo "$SCRIPT_NAME $VERSION"
      return 0
      ;;
    *)
      error "Unknown command: $command"
      msg ""
      usage
      return 1
      ;;
  esac
}

main "$@"
#fin
