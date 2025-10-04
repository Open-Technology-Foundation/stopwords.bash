#!/usr/bin/env python3
import os
import sys
from nltk.corpus import stopwords  # type: ignore

def main():
  """Generate stopwords data files from NLTK corpus."""
  # Create data directory if it doesn't exist
  script_dir = os.path.dirname(os.path.abspath(__file__))
  data_dir = os.path.join(script_dir, 'data')

  try:
    os.makedirs(data_dir, exist_ok=True)
    print(f"Creating stopwords data files in {data_dir}/")

    # Get all available languages
    languages = stopwords.fileids()

    # Generate a file for each language
    for language in sorted(languages):
      output_file = os.path.join(data_dir, f"{language}.txt")
      words = stopwords.words(language)

      # Write stopwords to file, one per line
      with open(output_file, 'w', encoding='utf-8') as f:
        for word in sorted(words):
          f.write(f"{word}\n")

      print(f"  Created {language}.txt ({len(words)} words)")

    print(f"\nSuccessfully generated {len(languages)} stopwords files.")
    print(f"Available languages: {', '.join(sorted(languages))}")

  except LookupError as e:
    sys.stderr.write(f"Error: NLTK stopwords corpus not found.\n")
    sys.stderr.write("Please download it with: python -m nltk.downloader stopwords\n")
    sys.exit(1)
  except Exception as e:
    sys.stderr.write(f"Error: {str(e)}\n")
    sys.exit(1)

if __name__ == '__main__':
  main()

#fin