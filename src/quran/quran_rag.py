from typing import List, Tuple, Dict
import numpy as np
from sentence_transformers import SentenceTransformer
from openai import OpenAI
import requests
import json
import traceback
from ..common.config import Config  # Updated import path

class QuranRAG:  # Renamed from IslamicRAG:
    def __init__(self, config: Config):
        """Initialize the Islamic RAG system"""
        print("Initializing IslamicRAG system...")
        self.config = config
        self.embedding_model = SentenceTransformer("sentence-transformers/all-mpnet-base-v2")
        self.client = OpenAI(api_key=config.OPENAI_API_KEY)
        self.verses_cache: Dict[str, dict] = {}
        self.embeddings_cache: Dict[str, np.ndarray] = {}
        print("IslamicRAG system initialized successfully")

    def fetch_quran_verses(self, query: str) -> List[dict]:
        """Fetch relevant verses from Quran API"""
        try:
            print(f"\nFetching verses for query: {query}")
            params = {
                'language': self.config.QURAN_API_LANGUAGE,
                'size': self.config.MAX_SEARCH_RESULTS,
                'q': query
            }
            print(f"API URL: {self.config.QURAN_API_URL}/search")
            print(f"Params: {params}")
            
            response = requests.get(
                f"{self.config.QURAN_API_URL}/search",
                params=params
            )
            print(f"API Response status: {response.status_code}")
            
            response.raise_for_status()
            data = response.json()
            print(f"API Response data: {data}")
            
            results = data['search']['results']
            print(f"Found {len(results)} verses")
            return results
            
        except Exception as e:
            print(f"Error in fetch_quran_verses: {str(e)}")
            print(traceback.format_exc())
            return []

    def get_verse_details(self, verse_key: str) -> dict:
        """Get detailed information about a specific verse"""
        try:
            print(f"\nGetting details for verse: {verse_key}")
            
            if verse_key in self.verses_cache:
                print("Found verse in cache")
                return self.verses_cache[verse_key]
            
            print("Fetching verse from API...")
            response = requests.get(
                f"{self.config.QURAN_API_URL}/verses/by_key/{verse_key}",
                params={'language': self.config.QURAN_API_LANGUAGE}
            )
            print(f"API Response status: {response.status_code}")
            
            response.raise_for_status()
            verse_data = response.json()['verse']
            self.verses_cache[verse_key] = verse_data
            print("Verse details fetched successfully")
            return verse_data
            
        except Exception as e:
            print(f"Error in get_verse_details: {str(e)}")
            print(traceback.format_exc())
            return {}

    def compute_embedding(self, text: str) -> np.ndarray:
        """Compute embedding for a given text"""
        try:
            print(f"\nComputing embedding for text: {text[:50]}...")
            
            if text in self.embeddings_cache:
                print("Found embedding in cache")
                return self.embeddings_cache[text]
            
            print("Computing new embedding...")
            embedding = self.embedding_model.encode([text])[0]
            normalized_embedding = embedding / np.linalg.norm(embedding)
            self.embeddings_cache[text] = normalized_embedding
            print("Embedding computed successfully")
            return normalized_embedding
            
        except Exception as e:
            print(f"Error in compute_embedding: {str(e)}")
            print(traceback.format_exc())
            raise

    def get_relevant_verses(self, query: str, top_k: int = 5) -> List[Tuple[dict, float]]:
        """Get the most relevant verses for a query using semantic search"""
        try:
            print(f"\nGetting relevant verses for query: {query}")
            
            verses = self.fetch_quran_verses(query)
            if not verses:
                print("No verses found")
                return []

            print("Computing query embedding...")
            query_embedding = self.compute_embedding(query)
            
            print("Computing similarities...")
            similarities = []
            for verse in verses:
                verse_data = self.get_verse_details(verse['verse_key'])
                if verse_data:
                    verse_text = verse_data.get('translations', [{}])[0].get('text', '')
                    verse_embedding = self.compute_embedding(verse_text)
                    similarity = np.dot(query_embedding, verse_embedding)
                    similarities.append((verse_data, similarity))

            sorted_verses = sorted(similarities, key=lambda x: x[1], reverse=True)[:top_k]
            print(f"Found {len(sorted_verses)} relevant verses")
            return sorted_verses
            
        except Exception as e:
            print(f"Error in get_relevant_verses: {str(e)}")
            print(traceback.format_exc())
            return []

    def generate_response(self, query: str) -> dict:
        """Generate a complete response for the Islamic question"""
        try:
            print(f"\nGenerating response for query: {query}")
            
            relevant_verses = self.get_relevant_verses(query)
            if not relevant_verses:
                print("No relevant verses found")
                return {
                    "answer": self.config.ERROR_MESSAGES['no_results'],
                    "verses": []
                }

            print("Preparing verses context...")
            verses_context = "\n\n".join([
                f"Verse {verse['verse_key']}: {verse.get('translations', [{}])[0].get('text', '')}"
                for verse, _ in relevant_verses
            ])

            prompt = f"""Based on the following Quranic verses, provide a comprehensive answer to the question.
            Also explain how each verse relates to the question.

            Question: {query}

            Relevant Quranic Verses:
            {verses_context}

            Please provide:
            1. A direct answer to the question
            2. How each verse relates to the question
            3. Any important context or considerations"""

            print("Sending request to OpenAI...")
            response = self.client.chat.completions.create(
                model=self.config.OPENAI_MODEL,
                messages=[
                    {"role": "system", "content": self.config.CHATGPT_SYSTEM_PROMPT},
                    {"role": "user", "content": prompt}
                ],
                temperature=self.config.CHATGPT_TEMPERATURE,
                max_tokens=self.config.CHATGPT_MAX_TOKENS
            )
            print("Received response from OpenAI")

            result = {
                "answer": response.choices[0].message.content,
                "verses": [
                    {
                        "verse_key": verse["verse_key"],
                        "arabic": verse.get("text_uthmani", ""),
                        "translation": verse.get("translations", [{}])[0].get("text", ""),
                        "relevance_score": float(score)
                    }
                    for verse, score in relevant_verses
                ]
            }
            print("Response generated successfully")
            return result
            
        except Exception as e:
            print(f"Error in generate_response: {str(e)}")
            print(traceback.format_exc())
            return {
                "answer": self.config.ERROR_MESSAGES['api_error'],
                "verses": []
            }

if __name__ == "__main__":
    print("IslamicRAG module loaded successfully")