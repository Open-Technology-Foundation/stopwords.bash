#!/usr/bin/env python3
"""Python implementation of stopwords filter for performance comparison."""
import os
import sys
from typing import Set, List, Dict

def load_stopwords(language: str = 'english') -> Set[str]:
    """Load stopwords from data file."""
    script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_file = os.path.join(script_dir, 'data', f'{language}.txt')

    if not os.path.exists(data_file):
        raise FileNotFoundError(f"Stopwords file not found: {data_file}")

    stopwords = set()
    with open(data_file, 'r', encoding='utf-8') as f:
        for line in f:
            stopwords.add(line.strip().lower())

    return stopwords

def filter_stopwords(text: str, language: str = 'english', keep_punctuation: bool = False) -> List[str]:
    """Filter stopwords from text."""
    import re

    stopwords = load_stopwords(language)
    lower_text = text.lower()

    if keep_punctuation:
        # Split on whitespace only
        words = lower_text.split()
    else:
        # Remove punctuation
        lower_text = re.sub(r"'s\b", ' ', lower_text)
        lower_text = re.sub(r'[^\w\s]', ' ', lower_text)
        words = lower_text.split()

    # Filter out stopwords and empty strings
    filtered = [word for word in words if word and word not in stopwords]

    return filtered

def count_words(text: str, language: str = 'english', keep_punctuation: bool = False) -> Dict[str, int]:
    """Count word frequencies after filtering stopwords."""
    import re

    stopwords = load_stopwords(language)
    lower_text = text.lower()

    if keep_punctuation:
        words = lower_text.split()
    else:
        lower_text = re.sub(r"'s\b", ' ', lower_text)
        lower_text = re.sub(r'[^\w\s]', ' ', lower_text)
        words = lower_text.split()

    # Count frequencies
    counts: Dict[str, int] = {}
    for word in words:
        if word and word not in stopwords:
            counts[word] = counts.get(word, 0) + 1

    return counts

def main():
    """Main function for CLI usage."""
    if len(sys.argv) < 2:
        text = sys.stdin.read()
    else:
        text = ' '.join(sys.argv[1:])

    filtered = filter_stopwords(text)
    print(' '.join(filtered))

if __name__ == '__main__':
    main()

#fin
