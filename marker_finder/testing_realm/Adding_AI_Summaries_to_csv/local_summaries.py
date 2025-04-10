#!/usr/bin/env python3
"""
Local Summaries Generator for Historical Markers

This script processes a CSV file containing historical marker data,
generates summaries for marker inscriptions using a local LLM (Ollama),
and saves the results to a new CSV file.
"""

import argparse
import json
import logging
import os
import re
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union

import pandas as pd
import requests
from tqdm import tqdm

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("summaries.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("local_summaries")

# Constants
OLLAMA_API_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = "deepseek-r1:latest"  # Change to your preferred model
CACHE_DIR = Path("summary_cache")
CACHE_DIR.mkdir(exist_ok=True)
MAX_RETRIES = 3
RETRY_DELAY = 2  # seconds

def parse_arguments() -> argparse.Namespace:
    """
    Parse command line arguments.
    """
    parser = argparse.ArgumentParser(description="Generate summaries for historical markers using a local LLM")
    parser.add_argument(
        "--input", "-i", type=str, default="test.csv",
        help="Input CSV file containing marker data"
    )
    parser.add_argument(
        "--output", "-o", type=str, default="output.csv",
        help="Output CSV file to save results"
    )
    parser.add_argument(
        "--column", "-c", type=str, default="Inscription",
        help="Column name containing text to summarize"
    )
    parser.add_argument(
        "--id-column", "-id", type=str, default="MarkerID",
        help="Column name containing unique marker IDs"
    )
    parser.add_argument(
        "--limit", "-l", type=int, default=None,
        help="Limit processing to this many rows"
    )
    parser.add_argument(
        "--force", "-f", action="store_true",
        help="Force regeneration of summaries even if cached"
    )
    parser.add_argument(
        "--debug", "-d", action="store_true",
        help="Enable debug logging"
    )
    parser.add_argument(
        "--test", "-t", action="store_true",
        help="Run in test mode with a sample prompt"
    )
    return parser.parse_args()


def get_cached_summary(marker_id: Union[int, str]) -> Optional[str]:
    """
    Get a cached summary for a marker if it exists.

    Args:
        marker_id: The ID of the marker

    Returns:
        The cached summary or None if not found
    """
    cache_file = CACHE_DIR / f"summary_{marker_id}.txt"
    if cache_file.exists():
        try:
            with open(cache_file, "r", encoding="utf-8") as f:
                return f.read().strip()
        except IOError as e:
            logger.warning(f"Error reading cache for marker {marker_id}: {e}")
    return None


def save_to_cache(marker_id: Union[int, str], summary: str) -> None:
    """
    Save a summary to the cache.

    Args:
        marker_id: The ID of the marker
        summary: The summary to cache
    """
    cache_file = CACHE_DIR / f"summary_{marker_id}.txt"
    try:
        with open(cache_file, "w", encoding="utf-8") as f:
            f.write(summary)
    except IOError as e:
        logger.warning(f"Error saving cache for marker {marker_id}: {e}")


def generate_summary(text: str, marker_id: Union[int, str] = None, force: bool = False) -> str:
    """
    Generate a summary for the given text using the local LLM.

    Args:
        text: The text to summarize
        marker_id: The ID of the marker (for caching)
        force: Whether to force regeneration even if cached

    Returns:
        The generated summary
    """
    # Check if we have a cached summary
    if marker_id is not None and not force:
        cached_summary = get_cached_summary(marker_id)
        if cached_summary:
            logger.debug(f"Using cached summary for marker {marker_id}")
            return cached_summary

    # If text is empty or too short, return a placeholder
    if not text or len(text.strip()) < 10:
        return "No text available to summarize."

    # Create a prompt for the LLM
    prompt = f"""
    Below is the inscription text from a historical marker. Please provide a concise summary (2-3 sentences)
    that captures the key historical information. Focus on the historical significance, key dates, and people mentioned.

    INSCRIPTION:
    {text}

    SUMMARY:
    """

    # Try to generate a summary with retries
    for attempt in range(MAX_RETRIES):
        try:
            headers = {"Content-Type": "application/json"}
            data = {
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False,
            }

            response = requests.post(OLLAMA_API_URL, headers=headers, json=data, timeout=30)
            response.raise_for_status()

            response_data = response.json()
            summary = response_data.get("response", "").strip()

            # Clean up the summary
            summary = re.sub(r'\n+', ' ', summary)
            summary = re.sub(r'\s+', ' ', summary).strip()

            # Cache the summary if we have a marker ID
            if marker_id is not None:
                save_to_cache(marker_id, summary)

            return summary

        except requests.exceptions.RequestException as e:
            logger.warning(f"Attempt {attempt+1}/{MAX_RETRIES} failed: {e}")
            if attempt < MAX_RETRIES - 1:
                time.sleep(RETRY_DELAY * (attempt + 1))  # Exponential backoff
            else:
                return f"Error generating summary: {e}"

        except Exception as e:
            logger.error(f"Unexpected error: {e}", exc_info=True)
            return f"Error generating summary: {e}"


def process_csv(input_file: str, output_file: str, text_column: str = "Inscription",
                id_column: str = "MarkerID", limit: Optional[int] = None, force: bool = False) -> None:
    """
    Process a CSV file, generate summaries, and save the results.

    Args:
        input_file: Path to the input CSV file
        output_file: Path to the output CSV file
        text_column: Name of the column containing text to summarize
        id_column: Name of the column containing unique marker IDs
        limit: Maximum number of rows to process
        force: Whether to force regeneration of summaries even if cached
    """
    try:
        # Read the CSV file
        df = pd.read_csv(input_file)
        logger.info(f"Loaded {len(df)} rows from {input_file}")

        # Limit the number of rows if specified
        if limit and limit > 0:
            df = df.head(limit)
            logger.info(f"Limited to {limit} rows")

        # Check if the required columns exist
        if text_column not in df.columns:
            logger.error(f"Column '{text_column}' not found in the CSV file")
            raise ValueError(f"Column '{text_column}' not found in the CSV file")

        if id_column not in df.columns:
            logger.warning(f"Column '{id_column}' not found in the CSV file. Caching will be disabled.")

        # Create a new column for summaries if it doesn't exist
        if "Summary" not in df.columns:
            df["Summary"] = ""

        # Process each row
        for index, row in tqdm(df.iterrows(), total=len(df), desc="Generating summaries"):
            # Get the text to summarize
            text = row.get(text_column, "")

            # Get the marker ID for caching
            marker_id = row.get(id_column) if id_column in df.columns else None

            # Generate a summary
            summary = generate_summary(text, marker_id, force)

            # Update the DataFrame
            df.at[index, "Summary"] = summary

        # Save the updated DataFrame
        df.to_csv(output_file, index=False)
        logger.info(f"Saved {len(df)} rows with summaries to {output_file}")

    except Exception as e:
        logger.error(f"Error processing CSV: {e}", exc_info=True)
        raise


def test_ollama_connection() -> bool:
    """
    Test the connection to the Ollama API.

    Returns:
        True if the connection is successful, False otherwise
    """
    try:
        test_prompt = "Say hello in one word."
        headers = {"Content-Type": "application/json"}
        data = {
            "model": OLLAMA_MODEL,
            "prompt": test_prompt,
            "stream": False,
        }

        response = requests.post(OLLAMA_API_URL, headers=headers, json=data, timeout=10)
        response.raise_for_status()

        response_data = response.json()
        result = response_data.get("response", "").strip()

        logger.info(f"Ollama test response: {result}")
        return True

    except Exception as e:
        logger.error(f"Error connecting to Ollama: {e}")
        return False


def run_test_mode() -> None:
    """
    Run the script in test mode with a sample prompt.
    """
    print("\n=== Running in Test Mode ===\n")

    # Test the connection to Ollama
    print("Testing connection to Ollama...")
    if not test_ollama_connection():
        print("❌ Failed to connect to Ollama. Make sure it's running and the model is available.")
        return

    print("✅ Successfully connected to Ollama!\n")

    # Sample inscription text
    sample_text = """
    Graceland, home of Elvis Presley, was built in 1939 by Dr. Thomas Moore and his wife Ruth.
    Elvis purchased the estate on March 19, 1957, and moved in with his parents, Vernon and Gladys Presley.
    The Colonial Revival style mansion sits on 13.8 acres and was named to the National Register of Historic Places in 1991.
    """

    print("Generating a summary for a sample inscription...\n")
    print(f"Sample text:\n{sample_text}\n")

    # Generate a summary
    summary = generate_summary(sample_text)

    print(f"Generated summary:\n{summary}\n")
    print("=== Test Complete ===\n")


def main() -> int:
    """
    Main function.

    Returns:
        Exit code (0 for success, non-zero for failure)
    """
    # Parse command line arguments
    args = parse_arguments()

    # Set logging level
    if args.debug:
        logger.setLevel(logging.DEBUG)

    # Run in test mode if requested
    if args.test:
        run_test_mode()
        return 0

    # Test the connection to Ollama
    if not test_ollama_connection():
        logger.error("Failed to connect to Ollama. Make sure it's running and the model is available.")
        return 1

    # Process the CSV file
    try:
        process_csv(
            input_file=args.input,
            output_file=args.output,
            text_column=args.column,
            id_column=args.id_column,
            limit=args.limit,
            force=args.force
        )
        logger.info("Processing completed successfully")
        return 0

    except Exception as e:
        logger.error(f"Error in main process: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())