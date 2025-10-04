# Stopwords Filter

A fast, multilingual text processing utility that filters stopwords from input text. Supports 33 languages with efficient O(1) lookup using Bash associative arrays.

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
- For regenerating stopword data files (optional):
  - Python 3.6+
  - NLTK library with stopwords corpus

### Setup

1. Clone or download this repository:
```bash
git clone https://github.com/Open-Technology-Foundation/stopwords.bash
cd stopwords
```

2. Make the script executable:
```bash
chmod +x stopwords.sh
```

3. (Optional) Download NLTK stopwords corpus for data regeneration:
```bash
python -m nltk.downloader stopwords
```

## Usage

### Basic Usage

Filter stopwords from English text (default language):

```bash
./stopwords.sh 'the quick brown fox jumps over the lazy dog'
# Output: quick brown fox jumps lazy dog
```

### Reading from stdin

```bash
echo 'the quick brown fox' | ./stopwords.sh
# Output: quick brown fox

cat document.txt | ./stopwords.sh
```

### Language Selection

Use the `-l` or `--language` option to specify a language:

```bash
# Spanish
./stopwords.sh -l spanish 'el rápido zorro marrón salta sobre el perro perezoso'
# Output: rápido zorro marrón salta perro perezoso

# Indonesian
./stopwords.sh -l indonesian 'Pohon mangga tumbuh di halaman rumah'
# Output: pohon mangga tumbuh halaman rumah

# French
./stopwords.sh -l french 'le chat noir dort sur le canapé'
# Output: chat noir dort canapé
```

### Punctuation Preservation

By default, punctuation is removed. Use `-p` or `--keep-punctuation` to preserve it:

```bash
./stopwords.sh 'Hello, world! How are you?'
# Output: hello world

./stopwords.sh -p 'Hello, world! How are you?'
# Output: hello, world!
```

### List Output

Use `-w` or `--list-words` to output one word per line:

```bash
./stopwords.sh -w 'the quick brown fox'
# Output:
# quick
# brown
# fox
```

### Word Frequency Counting

Use `-c` or `--count` to count word frequencies:

```bash
./stopwords.sh -c 'the quick brown fox jumps over the lazy dog and the fox runs'
# Output:
# 1 brown
# 1 dog
# 1 jumps
# 1 lazy
# 1 quick
# 1 runs
# 2 fox

# From a file
./stopwords.sh -c < document.txt
```

The output format is `count word`, sorted numerically by count (ascending).

### Combining Options

```bash
# Spanish text with punctuation preserved, output as list
./stopwords.sh -l spanish -p -w 'Hola, ¿cómo estás? Muy bien, gracias.'

# Word frequency from German text
./stopwords.sh -l german -c 'Der Hund läuft und der Hund spielt'
```

### Version and Help

```bash
# Show version
./stopwords.sh -V
# Output: stopwords 1.0.0

# Show help message
./stopwords.sh -h
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

Stopword lists are stored in the `data/` directory:
- One `.txt` file per language (e.g., `data/english.txt`, `data/spanish.txt`)
- One stopword per line
- Alphabetically sorted
- UTF-8 encoded

### Regenerating Data Files

To regenerate stopword data files from the NLTK corpus:

1. Ensure NLTK is installed with the stopwords corpus:
```bash
pip install nltk
python -m nltk.downloader stopwords
```

2. Run the data generation script:
```bash
./generate-stopwords-data.py
```

The script will:
- Create the `data/` directory if it doesn't exist
- Generate a `.txt` file for each language in the NLTK stopwords corpus
- Display the number of words per language

## Using as a Sourced Function

The stopwords filter can also be sourced and used as a Bash function:

```bash
# Source the script
source stopwords.sh

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
cat article.txt | ./stopwords.sh -w | sort | uniq

# Find most common words in a document
./stopwords.sh -c < article.txt | tail -20
```

### Search Query Processing

```bash
# Clean up search queries
echo "how to install python on ubuntu" | ./stopwords.sh
# Output: install python ubuntu
```

### Multi-Language Content Analysis

```bash
# Analyze Spanish content
curl -s https://example.com/es/article | ./stopwords.sh -l spanish -c
```

### Preprocessing for NLP

```bash
# Remove stopwords before feeding to ML model
for file in corpus/*.txt; do
  ./stopwords.sh < "$file" > "processed/$(basename "$file")"
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

1. **Load Stopwords**: Reads stopwords from `data/{language}.txt` into a Bash associative array for O(1) lookup
2. **Normalize Text**: Converts input to lowercase for case-insensitive matching
3. **Tokenize**: Splits text on whitespace (optionally removes punctuation first)
4. **Filter**: Checks each word against stopwords dictionary
5. **Output**: Formats results based on selected output mode

### Performance

- O(1) stopword lookup using Bash associative arrays
- Efficient for processing moderate-sized texts (< 1MB)
- **Recommendation**: For documents > 1,500 words, Python is the better choice for performance-critical applications
- Bash excels at small inputs (< 1500 words) due to lower startup overhead

For small texts Bash is typically faster due to Python's startup overhead. The crossover point starts at around 1,500 words, where Python's superior string processing begins to dominate.

## License

GPL-3. See [LICENSE](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Acknowledgments

Stopword lists are sourced from the [NLTK corpus](https://www.nltk.org/), which provides curated stopword lists for multiple languages.

