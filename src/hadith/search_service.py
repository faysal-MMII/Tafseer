from typing import List, Dict
from .hadith_collector import HadithCollector
from .hadith_db import HadithDatabase

class HadithSearchService:
    def __init__(self):
        self.collector = HadithCollector()
        self.db = HadithDatabase()

    def search_hadiths(self, query: str, limit: int = 5) -> List[Dict]:
        """
        Search hadiths using both SQLite and JSON approaches,
        combine and rank results
        """
        # Get results from both sources
        db_results = self.db.search_hadiths(query, limit=limit)
        collector_results = self.collector.get_hadiths(query)
        
        # Combine results, removing duplicates
        seen_texts = set()
        combined_results = []
        
        # Process SQLite results first (they might be more accurate)
        for hadith in db_results:
            text = hadith['text']
            if text not in seen_texts:
                seen_texts.add(text)
                combined_results.append(hadith)
        
        # Add collector results if we haven't hit our limit
        for hadith in collector_results:
            if len(combined_results) >= limit:
                break
            text = hadith['text']
            if text not in seen_texts:
                seen_texts.add(text)
                combined_results.append(hadith)
        
        return combined_results[:limit]
