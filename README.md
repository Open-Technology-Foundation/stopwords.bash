# Stopwords Filter

A fast, multilingual text processing utility that filters stopwords from input text. Supports 33 languages with efficient O(1) lookup using Bash associative arrays.

## Python Version Available

For performance-critical applications or processing large documents (> 2,000 words), consider the **[Python implementation](https://github.com/Open-Technology-Foundation/stopwords)** which offers superior performance on larger datasets. The Bash version is optimal for:
- Quick command-line filtering
- Shell script integration
- Processing smaller texts (< 2,000 words)
- Low startup overhead requirements

Both implementations use the same NLTK stopwords data and provide compatible interfaces.

## Features

- **Multilingual Support**: Filter stopwords in 33 different languages
- **Multiple Output Formats**: Single-line, list, or word frequency counts
- **Flexible Input**: Accept text via command-line arguments or stdin
- **Punctuation Control**: Optionally preserve or remove punctuation marks
- **Case-Insensitive**: Matches stopwords regardless of case
- **Fast Performance**: O(1) stopword lookup using associative arrays
- **Dual Usage**: Use as a standalone script or source as a Bash function

## Installation

### Prerequisites

- Bash 4.0+ (for associative array support)

### Quick Install (One-Liner)

```bash
curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/stopwords.bash/main/install.sh | sudo bash
```

This one-liner will download and execute the installation script, installing stopwords system-wide.

### Standard Install

**System-wide installation** (recommended, requires sudo):
```bash
git clone https://github.com/Open-Technology-Foundation/stopwords.bash
cd stopwords.bash
sudo make install
```

**User-local installation** (no sudo required):
```bash
git clone https://github.com/Open-Technology-Foundation/stopwords.bash
cd stopwords.bash
make PREFIX=$HOME/.local install
```

This installs:
- Script to `$PREFIX/bin/stopwords` (system: `/usr/local/bin/`, user: `~/.local/bin/`)
- Stopwords data to `/usr/share/stopwords/` (33 languages, ~170KB)
  - **Note:** If you have Python NLTK installed with stopwords, data installation is automatically skipped
- Documentation to `$PREFIX/share/doc/stopwords/`

### Manual Installation

If you prefer not to use Make:

```bash
# Using the install script directly
./install.sh install

# For user-local installation
PREFIX=$HOME/.local ./install.sh install

# Custom NLTK data location
NLTK_DATA=$HOME/nltk_data ./install.sh install
```

### Verifying Installation

Check that everything is installed correctly:

```bash
make check
# or
./install.sh check
```

This verifies:
- Script is executable and in PATH
- Stopwords data files are present (33 languages)
- Basic functionality works

### Uninstalling

```bash
# System installation
sudo make uninstall

# User installation
make PREFIX=$HOME/.local uninstall

# Or using install.sh
./install.sh uninstall
```

### Environment Configuration

The script uses the `NLTK_DATA` environment variable to locate stopwords data:
- **Default**: `/usr/share/nltk_data` (no configuration needed)
- **Custom location**: Set `NLTK_DATA` environment variable

```bash
# Add to ~/.bashrc or ~/.profile for custom location
export NLTK_DATA=/path/to/your/nltk_data
```

If installing to a user directory, ensure the bin directory is in your PATH:
```bash
# Add to ~/.bashrc or ~/.profile
export PATH="$HOME/.local/bin:$PATH"
```

### Advanced Installation Options

**Custom prefix**:
```bash
make PREFIX=/opt/local install
```

**Package staging** (for package maintainers):
```bash
make DESTDIR=/tmp/package PREFIX=/usr install
```

**Installation script help**:
```bash
./install.sh --help
```

## Usage

### Basic Usage

Filter stopwords from English text (default language):

```bash
./stopwords 'the quick brown fox jumps over the lazy dog'
# Output: quick brown fox jumps lazy dog
```

### Reading from stdin

```bash
echo 'the quick brown fox' | ./stopwords
# Output: quick brown fox

cat document.txt | ./stopwords
```

### Language Selection

Use the `-l` or `--language` option to specify a language:

```bash
# Spanish
./stopwords -l spanish 'el rápido zorro marrón salta sobre el perro perezoso'
# Output: rápido zorro marrón salta perro perezoso

# Indonesian
./stopwords -l indonesian 'Pohon mangga tumbuh di halaman rumah'
# Output: pohon mangga tumbuh halaman rumah

# French
./stopwords -l french 'le chat noir dort sur le canapé'
# Output: chat noir dort canapé
```

### Punctuation Preservation

By default, punctuation is removed. Use `-p` or `--keep-punctuation` to preserve it:

```bash
./stopwords 'Hello, world! How are you?'
# Output: hello world

./stopwords -p 'Hello, world! How are you?'
# Output: hello, world!
```

### List Output

Use `-w` or `--list-words` to output one word per line:

```bash
./stopwords -w 'the quick brown fox'
# Output:
# quick
# brown
# fox
```

### Word Frequency Counting

Use `-c` or `--count` to count word frequencies:

```bash
./stopwords -c 'the quick brown fox jumps over the lazy dog and the fox runs'
# Output:
# 1 brown
# 1 dog
# 1 jumps
# 1 lazy
# 1 quick
# 1 runs
# 2 fox

# From a file
./stopwords -c < document.txt
```

The output format is `count word`, sorted numerically by count (ascending).

### Combining Options

```bash
# Spanish text with punctuation preserved, output as list
./stopwords -l spanish -p -w 'Hola, ¿cómo estás? Muy bien, gracias.'

# Word frequency from German text
./stopwords -l german -c 'Der Hund läuft und der Hund spielt'
```

### Version and Help

```bash
# Show version
./stopwords -V
# Output: stopwords 1.0.0

# Show help message
./stopwords -h
```

## Supported Languages

The tool supports stopword filtering in 33 languages:

- albanian
- arabic
- azerbaijani
- basque
- belarusian
- bengali
- catalan
- chinese
- danish
- dutch
- english
- finnish
- french
- german
- greek
- hebrew
- hinglish
- hungarian
- indonesian
- italian
- kazakh
- nepali
- norwegian
- portuguese
- romanian
- russian
- slovene
- spanish
- swedish
- tajik
- tamil
- turkish

## Output Formats

### Single Line (Default)

Filtered words separated by spaces:
```
quick brown fox jumps lazy dog
```

### List Format (`-w` flag)

One word per line:
```
quick
brown
fox
jumps
lazy
dog
```

### Frequency Count (`-c` flag)

Word frequency as `count word` pairs, sorted by count (ascending):
```
1 brown
1 dog
1 fox
1 jumps
1 lazy
1 quick
```

## Data Files

### Structure

Stopword lists are located in one of these directories (checked in priority order):
1. `$NLTK_DATA/corpora/stopwords/` (if NLTK_DATA environment variable is set)
2. `/usr/share/nltk_data/corpora/stopwords/` (if Python NLTK is installed)
3. `/usr/share/stopwords/` (bundled installation fallback)

Each location contains:
- One file per language (e.g., `english`, `spanish`)
- One stopword per line
- Alphabetically sorted
- UTF-8 encoded

The script automatically detects and uses existing NLTK installations, avoiding data duplication.

## Using as a Sourced Function

The stopwords filter can also be sourced and used as a Bash function:

```bash
# Source the script
source stopwords

# Use the function
stopwords 'the quick brown fox'
# Output: quick brown fox

stopwords -l spanish 'el rápido zorro'
# Output: rápido zorro
```

## Practical Examples

### Text Analysis Pipeline

```bash
# Extract keywords from a document
cat article.txt | ./stopwords -w | sort | uniq

# Find most common words in a document
./stopwords -c < article.txt | tail -20
```

### Search Query Processing

```bash
# Clean up search queries
echo "how to install python on ubuntu" | ./stopwords
# Output: install python ubuntu
```

### Multi-Language Content Analysis

```bash
# Analyze Spanish content
curl -s https://example.com/es/article | ./stopwords -l spanish -c
```

### Preprocessing for NLP

```bash
# Remove stopwords before feeding to ML model
for file in corpus/*.txt; do
  ./stopwords < "$file" > "processed/$(basename "$file")"
done
```

## Command-Line Options

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-l LANG` | `--language LANG` | Set the language for stopwords (default: english) |
| `-p` | `--keep-punctuation` | Keep punctuation marks (default: remove) |
| `-w` | `--list-words` | Output filtered words as a list (one per line) |
| `-c` | `--count` | Output word frequency counts (sorted by count) |
| `-V` | `--version` | Show version information |
| `-h` | `--help` | Show help message |

Short options can be combined: `-lw`, `-pc`, etc.

## Exit Codes

- `0`: Success
- `1`: Data directory or stopwords file not found
- `2`: Missing argument for option
- `22`: Invalid option

## Technical Details

### Algorithm

1. **Load Stopwords**: Reads stopwords from `$NLTK_DATA/corpora/stopwords/{language}` into a Bash associative array for O(1) lookup
2. **Normalize Text**: Converts input to lowercase for case-insensitive matching
3. **Tokenize**: Splits text on whitespace (optionally removes punctuation first)
4. **Filter**: Checks each word against stopwords dictionary
5. **Output**: Formats results based on selected output mode

### Performance

- O(1) stopword lookup using Bash associative arrays
- Efficient for processing moderate-sized texts (< 1MB)
- **Recommendation**: For documents > 2,000 words, Python is the better choice for performance-critical applications
- Bash excels at small inputs (< 2,000 words) due to lower startup overhead

For small texts Bash is typically faster due to Python's startup overhead. The crossover point starts at around 2,000 words, where Python's superior string processing begins to dominate.

## Troubleshooting

### Stopwords data not found

If you get an error about missing stopwords data, try:

1. **Install this package:**
   ```bash
   sudo make install
   ```

2. **OR use Python NLTK:**
   ```bash
   pip install nltk
   python -m nltk.downloader stopwords
   ```

3. **OR set NLTK_DATA manually:**
   ```bash
   export NLTK_DATA=/path/to/your/nltk_data
   ```

### Using existing NLTK installation

If you have Python NLTK installed with stopwords, the script will automatically detect and use it. No additional configuration needed! The installation process will skip installing duplicate data.

## License

GPL-3. See [LICENSE](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Acknowledgments

Stopword lists are sourced from the [NLTK corpus](https://www.nltk.org/), which provides curated stopword lists for multiple languages.

