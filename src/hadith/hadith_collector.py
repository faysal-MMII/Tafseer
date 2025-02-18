import requests
import json
from pathlib import Path
from typing import List, Dict

class HadithCollector:
    def __init__(self):
        self.data_dir = Path(__file__).parent.parent.parent / 'data'
        self.data_dir.mkdir(exist_ok=True)
        self.data_file = self.data_dir / 'hadith_data.json'
        self.collections = self.load_hadith_data()
        
        # Enhanced topic mappings
        self.topic_mappings = {
            'prayer': ['salah', 'salat', 'pray', 'worship', 'mosque', 'masjid', 'prostration', 'ruku', 'sujud'],
            'fasting': ['fast', 'sawm', 'ramadan', 'iftar', 'suhoor', 'suhur', 'taraweeh'],
            'zakat': ['charity', 'sadaqah', 'sadaqa', 'alms', 'giving', 'wealth', 'poor', 'needy'],
            'purification': ['wudu', 'ghusl', 'tayammum', 'clean', 'pure', 'ablution', 'water'],
            'faith': ['iman', 'belief', 'allah', 'prophet', 'quran', 'islam', 'muslim'],
            # Add more mappings as needed
        }

    def load_hadith_data(self):
        """Load or download hadith data"""
        try:
            if self.data_file.exists():
                print("Loading cached hadith data...")
                with open(self.data_file, 'r', encoding='utf-8') as f:
                    return json.load(f)

            print("Downloading hadith collection...")
            urls = [
                "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-bukhari.json",
                "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-muslim.json"
            ]
            
            combined_data = {}
            for url in urls:
                response = requests.get(url)
                response.raise_for_status()
                data = response.json()
                collection_name = 'bukhari' if 'bukhari' in url else 'muslim'
                combined_data[collection_name] = data['hadiths']

            with open(self.data_file, 'w', encoding='utf-8') as f:
                json.dump(combined_data, f, ensure_ascii=False)

            return combined_data

        except Exception as e:
            print(f"Error loading hadith data: {str(e)}")
            return {}

    def expand_search_terms(self, query: str) -> List[str]:
        """Improved search term expansion"""
        search_terms = set()
        query_words = query.lower().split()
        
        # Add original query and words
        search_terms.add(query.lower())
        search_terms.update(query_words)
        
        # Add related terms from mappings
        for word in query_words:
            for topic, related_terms in self.topic_mappings.items():
                if word in [topic] or word in related_terms:
                    search_terms.update(related_terms)
                    search_terms.add(topic)
        
        # Add word combinations for multi-word queries
        if len(query_words) > 1:
            for i in range(len(query_words)-1):
                search_terms.add(f"{query_words[i]} {query_words[i+1]}")
        
        return list(search_terms)

    def get_hadiths(self, query: str) -> List[Dict]:
        """Enhanced search for hadiths with better relevance"""
        search_terms = self.expand_search_terms(query)
        print(f"Searching for terms: {search_terms}")
        scored_results = []
        
        for collection_name, hadiths in self.collections.items():
            for hadith in hadiths:
                hadith_text = hadith['text'].lower()
                score = 0
                
                # Calculate relevance score
                for term in search_terms:
                    if term in hadith_text:
                        # Base score for term presence
                        base_score = hadith_text.count(term) * 2
                        
                        # Bonus for terms appearing early in the text
                        position_bonus = 0
                        first_pos = hadith_text.find(term)
                        if first_pos < len(hadith_text) // 4:  # First quarter
                            position_bonus = 3
                        elif first_pos < len(hadith_text) // 2:  # First half
                            position_bonus = 1
                        
                        # Bonus for exact phrase matches
                        phrase_bonus = 4 if query.lower() in hadith_text else 0
                        
                        # Total score for this term
                        score += base_score + position_bonus + phrase_bonus
                
                if score > 0:
                    scored_results.append((score, {
                        'collection': collection_name.title(),
                        'number': hadith.get('reference', hadith.get('number', 'N/A')),
                        'text': hadith['text'],
                        'arabic': hadith.get('arabic', ''),
                        'chapter': hadith.get('chapter', '')
                    }))
        
        # Sort by relevance score and take top 5
        scored_results.sort(reverse=True, key=lambda x: x[0])
        results = [item[1] for item in scored_results[:5]]
        
        print(f"Found {len(results)} relevant results")
        return results