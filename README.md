# Stopwords Filter

A fast, multilingual text processing utility that filters stopwords from input text. Supports 33 languages with efficient O(1) lookup using Bash associative arrays.

> **Note:** For documents > 2,000 words, consider the **[Python implementation](https://github.com/Open-Technology-Foundation/stopwords)** which offers superior performance on larger datasets. Both use the same NLTK stopwords data.

## Features

- **Multilingual Support**: Filter stopwords in 33 different languages
- **Multiple Output Formats**: Single-line, list, or word frequency counts
- **Flexible Input**: Accept text via command-line arguments or stdin
- **Punctuation Control**: Optionally preserve or remove punctuation marks
- **Case-Insensitive**: Matches stopwords regardless of case
- **Fast Performance**: O(1) stopword lookup using associative arrays
- **Dual Usage**: Use as a standalone script or source as a Bash function

## Installation

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/stopwords.bash/main/install.sh | sudo bash
```

### Standard Install

**System-wide** (recommended):
```bash
git clone https://github.com/Open-Technology-Foundation/stopwords.bash
cd stopwords.bash
sudo ./install.sh install
```

**User-local** (no sudo):
```bash
PREFIX=$HOME/.local ./install.sh install
```

This installs the script to `$PREFIX/bin/stopwords` and stopwords data to `/usr/share/stopwords/` (33 languages, ~170KB). If Python NLTK stopwords are already installed, data installation is automatically skipped.

### Verify & Uninstall

```bash
# Verify installation
./install.sh check

# Uninstall (system)
sudo ./install.sh uninstall

# Uninstall (user)
PREFIX=$HOME/.local ./install.sh uninstall
```

## Usage

### Basic Filtering

```bash
./stopwords 'the quick brown fox jumps over the lazy dog'
# Output: quick brown fox jumps lazy dog
```

### Reading from stdin

```bash
echo 'the quick brown fox' | ./stopwords
cat document.txt | ./stopwords
```

### Language Selection (`-l`)

```bash
./stopwords -l spanish 'el rápido zorro marrón salta sobre el perro perezoso'
# Output: rápido zorro marrón salta perro perezoso
```

### Punctuation Preservation (`-p`)

```bash
./stopwords 'Hello, world!'      # Output: hello world
./stopwords -p 'Hello, world!'   # Output: hello, world!
```

### List Output (`-w`)

```bash
./stopwords -w 'the quick brown fox'
# Output:
# quick
# brown
# fox
```

### Word Frequency Counting (`-c`)

```bash
./stopwords -c 'the fox jumps and the fox runs'
# Output:
# 1 jumps
# 1 runs
# 2 fox

./stopwords -c < document.txt
```

## Supported Languages

albanian, arabic, azerbaijani, basque, belarusian, bengali, catalan, chinese, danish, dutch, english, finnish, french, german, greek, hebrew, hinglish, hungarian, indonesian, italian, kazakh, nepali, norwegian, portuguese, romanian, russian, slovene, spanish, swedish, tajik, tamil, turkish

## Command-Line Options

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-l LANG` | `--language LANG` | Set the language for stopwords (default: english) |
| `-p` | `--keep-punctuation` | Keep punctuation marks (default: remove) |
| `-w` | `--list-words` | Output filtered words as a list (one per line) |
| `-c` | `--count` | Output word frequency counts (sorted ascending) |
| `-V` | `--version` | Show version information |
| `-h` | `--help` | Show help message |

## Using as a Sourced Function

```bash
source stopwords
stopwords 'the quick brown fox'           # Output: quick brown fox
stopwords -l spanish 'el rápido zorro'    # Output: rápido zorro
```

## Practical Examples

```bash
# Extract keywords from a document
cat article.txt | ./stopwords -w | sort | uniq

# Find most common words
./stopwords -c < article.txt | tail -20

# Clean search queries
echo "how to install python on ubuntu" | ./stopwords
# Output: install python ubuntu

# Batch preprocessing
for file in corpus/*.txt; do
  ./stopwords < "$file" > "processed/$(basename "$file")"
done
```

## Exit Codes

- `0`: Success
- `1`: Data directory or stopwords file not found
- `2`: Missing argument for option
- `22`: Invalid option

## Troubleshooting

**Stopwords data not found?**

The script searches these locations in order:
1. `$NLTK_DATA/corpora/stopwords/` (custom NLTK path)
2. `/usr/share/nltk_data/corpora/stopwords/` (system NLTK)
3. `/usr/share/stopwords/` (bundled fallback)

Solutions:
```bash
# Install this package
sudo ./install.sh install

# OR use Python NLTK
pip install nltk && python -m nltk.downloader stopwords

# OR set NLTK_DATA manually
export NLTK_DATA=/path/to/your/nltk_data
```

**User-local install not in PATH?**
```bash
# Add to ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

## License

GPL-3. See [LICENSE](LICENSE)

## Contributing

Contributions welcome! Submit issues or pull requests on GitHub.

## Acknowledgments

Stopword lists sourced from the [NLTK corpus](https://www.nltk.org/).
