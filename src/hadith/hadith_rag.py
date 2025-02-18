from .hadith_collector import HadithCollector
from typing import List, Dict
from openai import OpenAI
import traceback

class HadithRAG:
    def __init__(self, config):
        """Initialize HadithRAG with configuration"""
        self.config = config
        self.client = OpenAI(api_key=config.OPENAI_API_KEY)
        self.collector = HadithCollector()

    def process_query(self, query: str) -> List[Dict]:
        """Process and get relevant hadiths for the query"""
        try:
            hadiths = self.collector.get_hadiths(query)
            # Sort hadiths by length and take shortest ones first
            hadiths.sort(key=lambda x: len(x.get('text', '')))
            return hadiths[:5]  # Return only 5 shortest hadiths
        except Exception as e:
            print(f"Error processing query: {str(e)}")
            return []

    def generate_response(self, query: str) -> dict:
        """Generate a comprehensive response using hadiths"""
        try:
            print("HadithRAG: Starting generate_response")
            hadiths = self.process_query(query)
            print(f"HadithRAG: Found {len(hadiths)} hadiths")
            
            if not hadiths:
                return {
                    "answer": "I couldn't find specific hadiths for your question. Consider consulting with a local scholar for more guidance.",
                    "hadiths": []
                }

            # Take only first 3 hadiths and limit their length
            limited_hadiths = []
            for h in hadiths[:3]:  # Limit to 3 hadiths
                text = h['text']
                if len(text) > 500:  # Limit each hadith to 500 characters
                    text = text[:497] + "..."
                
                limited_hadiths.append({
                    'collection': h['collection'],
                    'number': h['number'],
                    'text': text
                })

            # Prepare hadith context
            hadith_context = "\n\n".join([
                f"Hadith from {h['collection']}, Number {h['number']}:\n{h['text']}"
                for h in limited_hadiths
            ])

            # Generate response using ChatGPT
            response = self.client.chat.completions.create(
                model=self.config.OPENAI_MODEL,
                messages=[
                    {
                        "role": "system", 
                        "content": """You are a knowledgeable Islamic scholar providing guidance based on authentic hadiths.
                        Keep your answers focused, clear, and practical. Explain any Islamic terms used."""
                    },
                    {
                        "role": "user", 
                        "content": f"""Question: {query}

                        Based on these hadiths, provide a clear and practical answer:
                        {hadith_context}"""
                    }
                ],
                temperature=0.7,
                max_tokens=1000  # Limit response length
            )

            return {
                "answer": response.choices[0].message.content,
                "hadiths": limited_hadiths
            }

        except Exception as e:
            print(f"HadithRAG Error: {str(e)}")
            traceback.print_exc()
            return {
                "answer": "I apologize, but I encountered an error processing your question. Please try asking in a different way.",
                "hadiths": []
            }

    def format_hadith_display(self, hadith: Dict) -> str:
        """Format a hadith for display"""
        return f"""
            Collection: {hadith['collection']}
            Number: {hadith['number']}
            Text: {hadith['text']}
            {f"Arabic: {hadith['arabic']}" if hadith.get('arabic') else ''}
            {f"Chapter: {hadith['chapter']}" if hadith.get('chapter') else ''}
        """.strip()

    def get_hadith_by_reference(self, collection: str, number: str) -> Dict:
        """Get a specific hadith by its reference"""
        try:
            hadiths = self.collector.collections.get(collection.lower(), {})
            for hadith in hadiths:
                if str(hadith.get('number')) == str(number):
                    return hadith
            return None
        except Exception as e:
            print(f"Error retrieving hadith: {str(e)}")
            return None