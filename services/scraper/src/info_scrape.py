import pandas as pd
import requests
from bs4 import BeautifulSoup
import re
import time

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    'Accept': 'text/html,application/xhtml+xml'
}

def ensure_desktop_url(url):
    return url.replace("en.m.wikipedia.org", "en.wikipedia.org")

def follow_canonical_redirect(soup):
    link_tag = soup.find('link', {'rel': 'canonical'})
    if link_tag:
        canonical_url = link_tag.get('href')
        if canonical_url and "wikipedia.org/wiki/" in canonical_url:
            return canonical_url
    return None


def extract_infobox(soup):
    info = {}
    # Try multiple infobox class names
    infobox = soup.find('table', class_=lambda x: x and 'infobox' in x)
    if not infobox:
        print("No infobox found")
        return info

    rows = infobox.find_all('tr')
    for row in rows:
        header = row.find('th')
        data = row.find('td')
        if header and data:
            key = header.get_text(strip=True).lower()
            value = data.get_text(separator=' ', strip=True)
            info[key] = value
    return info

def extract_intro_paragraphs_after_infobox(soup):
    paragraphs = []
    infobox = soup.find('table', class_=lambda x: x and 'infobox' in x)
    if not infobox:
        print("No infobox found, falling back to mw-parser-output")
        # fallback: just get first few paragraphs in mw-parser-output
        content_div = soup.find('div', class_='mw-parser-output')
        if content_div:
            for p in content_div.find_all('p', recursive=False):
                text = p.get_text(strip=True)
                if text and len(text) > 40:
                    paragraphs.append(text)
        return ' '.join(paragraphs)

    # Iterate over siblings after the infobox until we hit a heading (h2/h3)
    for sibling in infobox.find_next_siblings():
        if sibling.name in ['h2', 'h3']:
            break
        if sibling.name == 'p':
            text = sibling.get_text(strip=True)
            if text and len(text) > 40:
                paragraphs.append(text)

    if paragraphs:
        print(f"✅ Extracted {len(paragraphs)} intro paragraphs after infobox")
    else:
        print("⚠️ No paragraphs found after infobox")

    return ' '.join(paragraphs)




def clean_text(text):
    return re.sub(r'\[\d+\]', '', text)  # remove reference markers like [1]

def get_construction_date(infobox):
    possible_keys = [
        'completed',
        'built',
        'construction started',
        'construction',
        'opened',
        'established',
        'inaugurated',
        'groundbreaking'
    ]

    for key, value in infobox.items():
        key_lower = key.lower()
        if any(variant in key_lower for variant in possible_keys):
            return value
    return ''

def get_architect(infobox):
    possible_keys = [
        'architect',
        'architects',
        'designer',
        'design',
        'architecture firm',
        'engineer'
    ]

    for key, value in infobox.items():
        key_lower = key.lower()
        if any(variant in key_lower for variant in possible_keys):
            return value
    return ''


def get_architectural_style(infobox):
    # Normalize keys for easier matching
    for key, value in infobox.items():
        key_lower = key.lower()
        if any(term in key_lower for term in [
            'architectural style', 
            'style', 
            'architecture style',
            'architecture',
            'design',
            'building type'
        ]):
            return value
    return ''

def extract_field(infobox, possible_keys):
    for key, value in infobox.items():
        key_lower = key.lower()
        if any(variant in key_lower for variant in possible_keys):
            return value
    return ''


def scrape_building_info(wiki_url):
    try:
        wiki_url = ensure_desktop_url(wiki_url)
        response = requests.get(wiki_url, headers=headers, allow_redirects=True)
        soup = BeautifulSoup(response.content, 'html.parser')

        # 🔁 Follow redirect if needed
        canonical_url = follow_canonical_redirect(soup)
        if canonical_url and canonical_url != wiki_url:
            print(f"🔁 Redirecting to canonical URL: {canonical_url}")
            response = requests.get(canonical_url, headers=headers)
            soup = BeautifulSoup(response.content, 'html.parser')
        infobox = extract_infobox(soup)
        unstructured = extract_intro_paragraphs_after_infobox(soup)

        return {
            'built_year': get_construction_date(infobox),
            'architect': get_architect(infobox),
            'architectural_style': get_architectural_style(infobox),
            'location': extract_field(infobox, ['location', 'address']),
            'materials': extract_field(infobox, ['material', 'building material']),
            'building_type': extract_field(infobox, ['type', 'building type', 'use']),
            'owner': extract_field(infobox, ['owner', 'managed by']),
            'height': extract_field(infobox, ['height', 'roof height', 'elevation']),
            'construction_cost': extract_field(infobox, ['cost', 'construction cost']),
            'unstructured_info': clean_text(unstructured)
        }
    except Exception as e:
        print(f"Error processing {wiki_url}: {e}")
        return {
            'built_year': '',
            'architect': '',
            'style': '',
            'unstructured_info': ''
        }

def main(csv_path, output_path):
    df = pd.read_csv(csv_path)
    results = []

    for _, row in df.iterrows():
        id = row.get('id', '')
        building = row.get('name', '')
        url = row.get('source_url', '')
        print(f"Processing: {building} - {url}")
        
        data = {}
        data['id'] = id
        data['name'] = building
        data['source_url'] = url
        data.update(scrape_building_info(url))
        results.append(data)

        time.sleep(1)  # Respectful delay

    output_df = pd.DataFrame(results)
    output_df.to_csv(output_path, index=False)
    print(f"Saved to {output_path}")


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python scrape_metadata.py <input_csv> [output_csv]")
        sys.exit(1)

    input_csv = sys.argv[1]
    output_csv = sys.argv[2] if len(sys.argv) > 2 else None
    main(input_csv, output_csv)
