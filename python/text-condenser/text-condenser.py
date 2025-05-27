#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "ollama==0.4.3",
# ]
# ///
#
# Reference:
#   * ollama-python releases: https://github.com/ollama/ollama-python/releases

"""
An LLM-powered tool that rewrites text to be more information-dense.
"""

import sys
import argparse
from pathlib import Path
from typing import Optional
import ollama


def create_condensing_prompt(content: str, file_type: str) -> str:
    """Create a detailed prompt for the LLM to condense the file content."""
    return f"""You are a file condenser. Your task is to condense the following {file_type} file by removing redundant syntax elements while preserving ALL meaningful information.

Guidelines:
1. Remove redundant structural elements like brackets, quotes, field names when the context is clear
2. Preserve all actual data values and their relationships
3. Use natural language shortcuts where appropriate
4. The output should be readable to humans and other LLMs
5. Do NOT summarize or omit details - preserve all information
6. Use concise notation that maintains clarity

For JSON files specifically:
- Convert object notation to key=value pairs or natural language
- Remove unnecessary punctuation and quotes
- Group related items logically
- Use abbreviated forms where meaning is preserved

Input file content:
---
{content}
---

Please output ONLY the condensed version, with no explanations or metadata:"""


def condense_file(file_path: Path, model: str) -> str:
    """
    Condense a file using the specified LLM model.

    Args:
        file_path: Path to the file to condense
        model: Name of the Ollama model to use

    Returns:
        Condensed content as a string
    """
    # Read the input file
    try:
        content = file_path.read_text(encoding='utf-8')
    except Exception as e:
        raise RuntimeError(f"Failed to read file '{file_path}': {e}")

    # Determine file type
    file_extension = file_path.suffix.lower()
    file_type = {
        '.json': 'JSON',
        '.yaml': 'YAML',
        '.yml': 'YAML',
        '.xml': 'XML',
        '.toml': 'TOML',
        '.csv': 'CSV',
    }.get(file_extension, 'text')

    # Create the prompt
    prompt = create_condensing_prompt(content, file_type)

    # Call the LLM
    try:
        response = ollama.generate(
            model=model,
            prompt=prompt,
            options={
                'temperature': 0.3,  # Lower temperature for more consistent output
                'top_p': 0.9,
            }
        )
        return response['response'].strip()
    except Exception as e:
        raise RuntimeError(f"Failed to generate condensed output: {e}")


def main():
    """Main entry point for the file condenser."""
    parser = argparse.ArgumentParser(
        description="Condense files by removing redundant syntax while preserving information"
    )
    parser.add_argument(
        'input_file',
        type=Path,
        help='Path to the input file to condense'
    )
    parser.add_argument(
        '--model',
        default='qwen3:30b-a3b',
        help='Ollama model to use'
    )

    args = parser.parse_args()

    # Validate input file
    if not args.input_file.exists():
        print(f"Error: Input file '{args.input_file}' does not exist", file=sys.stderr)
        sys.exit(1)

    if not args.input_file.is_file():
        print(f"Error: '{args.input_file}' is not a file", file=sys.stderr)
        sys.exit(1)

    try:
        condensed = condense_file(args.input_file, args.model)
        print(condensed)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
