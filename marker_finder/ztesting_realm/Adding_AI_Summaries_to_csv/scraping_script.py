import requests
from bs4 import BeautifulSoup
import openai

# Set your OpenAI API key
openai.api_key = "your_openai_api_key"

def scrape_webpage(url):
    try:
        # Fetch the webpage content
        response = requests.get(url)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Extract text content from the webpage
        text = ' '.join([p.get_text() for p in soup.find_all('p')])
        return text
    except requests.exceptions.RequestException as e:
        print(f"Error fetching the webpage: {e}")
        return None

def summarize_text(text):
    try:
        # Use OpenAI API to summarize the text
        response = openai.Completion.create(
            engine="text-davinci-003",
            prompt=f"Summarize the following text:\n\n{text}",
            max_tokens=150,
            temperature=0.7
        )
        summary = response.choices[0].text.strip()
        return summary
    except Exception as e:
        print(f"Error generating summary: {e}")
        return None

if __name__ == "__main__":
    # Example URL to scrape
    url = "https://example.com"
    
    # Scrape the webpage
    content = scrape_webpage(url)
    if content:
        print("Webpage content scraped successfully.")
        
        # Generate AI summary
        summary = summarize_text(content)
        if summary:
            print("\nSummary of the webpage:")
            print(summary)
        else:
            print("Failed to generate summary.")
    else:
        print("Failed to scrape the webpage.")