from hadith_db import HadithDatabase
import json
from pathlib import Path

def load_hadith_data():
    """Load hadiths with proper categorization"""
    db = HadithDatabase()
    
    # Topic mappings for better categorization
    topic_mappings = {
        'prayer': ['salah', 'salat', 'pray', 'worship', 'mosque', 'masjid', 'prostration', 'ruku', 'sujud'],
        'fasting': ['fast', 'sawm', 'ramadan', 'iftar', 'suhoor', 'suhur', 'taraweeh'],
        'zakat': ['charity', 'sadaqah', 'sadaqa', 'alms', 'giving', 'wealth', 'poor', 'needy'],
        'purification': ['wudu', 'ghusl', 'tayammum', 'clean', 'pure', 'ablution', 'water'],
        'faith': ['iman', 'belief', 'allah', 'prophet', 'quran', 'islam', 'muslim'],
        # Add more categories as needed
    }

    # Add Bukhari collection
    bukhari_id = db.add_collection(
        name="Sahih Bukhari",
        description="The most authentic collection of hadith"
    )
    
    # Load the JSON data
    data_dir = Path(__file__).parent.parent.parent / 'data'
    try:
        with open(data_dir / 'hadith_data.json', 'r', encoding='utf-8') as f:
            collections = json.load(f)
            
        print("Loading hadiths into database...")
        total_loaded = 0
        
        for collection_name, hadiths in collections.items():
            for hadith in hadiths:
                # Extract relevant keywords based on content
                keywords = set()
                text = hadith['text'].lower()
                
                # Add topic-based keywords
                for topic, related_terms in topic_mappings.items():
                    if any(term in text for term in [topic] + related_terms):
                        keywords.add(topic)
                        keywords.update(term for term in related_terms if term in text)
                
                # Add additional context words
                words = text.split()[:20]  # Use first 20 words for additional context
                keywords.update(word for word in words if len(word) > 3)
                
                db.add_hadith({
                    'collection_id': bukhari_id,
                    'hadith_number': str(hadith.get('reference', hadith.get('number', 'N/A'))),
                    'text': hadith['text'],
                    'arabic_text': hadith.get('arabic', ''),
                    'keywords': ','.join(keywords),
                    'grade': 'Sahih',  # For Bukhari
                    'narrator': extract_narrator(hadith['text'])  # Helper function to extract narrator
                })
                total_loaded += 1
                
                if total_loaded % 100 == 0:
                    print(f"Loaded {total_loaded} hadiths...")
        
        print(f"Successfully loaded {total_loaded} hadiths into the database.")
        
    except Exception as e:
        print(f"Error loading hadith data: {str(e)}")

def extract_narrator(text):
    """Extract narrator from hadith text"""
    try:
        # Most hadiths start with "Narrated ..."
        if text.startswith('Narrated '):
            narrator_end = text.find(':')
            if narrator_end != -1:
                return text[9:narrator_end].strip()
    except Exception:
        pass
    return ''

if __name__ == "__main__":
    load_hadith_data()