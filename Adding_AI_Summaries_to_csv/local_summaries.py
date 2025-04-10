import requests
import json
import argparse
import logging
import pandas as pd
from tqdm import tqdm
import re
import os
import time
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union

# from subprocess import call
# from bs4 import BeautifulSoup


# Configure logging

logging.basicConfig(
    level = logging.INFO,
    format = '%(asctime)s - %(levelname)s - %(message)s',
    handlers = [
        logging.FileHandler("summaries.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("local_summaries")



input = "give me one random word. print a single exclamation mark before the word you choose. print nothing but the exclamation mark and the word"

# articles im reading for help:
# https://saturncloud.io/blog/how-to-select-specific-csv-columns-using-python-and-pandas/


#stuff to call the deepseek model and feed it our requests
url = "http://localhost:11434/api/generate"

headers = {
    "Content-type": "application/json",
}
data = {
    "model": "deepseek-r1:latest",
    "prompt": input,
    "stream": False,
    }

# code to gather the response from the model
response = requests.post(url, headers=headers, data=json.dumps(data))

if response.status_code == 200:
    response_text = response.text
    data = json.loads(response_text)
    actual_response = data["response"]
    print(actual_response)
else:
    print("Error: ", response.status_code, response.text)

clean_actual_response = re.sub(r"<.*!", "", actual_response)
print(clean_actual_response)





# df = pd.read_csv("test.csv")  # Load CSV file
# df['summary'] = "filler"  # Create a new column for summaries
# df.to_csv("test2.csv", index=False)  # Save the file

# df = pd.read_csv("test2.csv")  # Load CSV file
# df.summary[1] = clean_actual_response  # Write the value 10 to column summary, row 5 (zero-indexed)


df = pd.read_csv("test.csv")  # Load CSV file
df['new_column'] = '"filler"'  # Create a new column for summaries
df.to_csv("test2.csv", index=False)  # Save the file














# def scrape_webpage(url):
#     """
#     Scrapes the content of a webpage and returns the text.
#     """
#     try:
#         response = requests.get(url)
#         response.raise_for_status()
#         soup = BeautifulSoup(response.text, 'html.parser')
#         # Extract text from paragraphs
#         paragraphs = soup.find_all('p')
#         content = ' '.join([p.get_text() for p in paragraphs])
#         return content
#     except requests.exceptions.RequestException as e:
#         print(f"Error fetching the webpage: {e}")
#         return None


# # executes the actual command
# call(["ls", "-l"])








# def summarize_text_with_ollama(text):
#     """
#     Sends the text to the local Ollama model for summarization.
#     """
#     try:
#         ollama_url = "http://localhost:8000/summarize"  # Replace with your local Ollama endpoint
#         payload = {"text": text}
#         headers = {"Content-Type": "application/json"}
#         response = requests.post(ollama_url, json=payload, headers=headers)
#         response.raise_for_status()
#         summary = response.json().get("summary", "No summary returned.")
#         return summary
#     except requests.exceptions.RequestException as e:
#         print(f"Error communicating with the Ollama model: {e}")
#         return None

# if __name__ == "__main__":
#     # Example usage
#     webpage_url = input("Enter the URL of the webpage to summarize: ")
#     content = scrape_webpage(webpage_url)
#     if content:
#         print("Webpage content scraped successfully.")
#         summary = summarize_text_with_ollama(content)
#         if summary:
#             print("\nSummary of the webpage:")
#             print(summary)