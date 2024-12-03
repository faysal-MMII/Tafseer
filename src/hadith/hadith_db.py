import sqlite3
import json
from pathlib import Path
from typing import List, Dict

class HadithDatabase:
    def __init__(self, db_path: str = "data/hadith.db"):
        self.db_path = db_path
        self.setup_database()

    def setup_database(self):
        """Create the database schema"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS collections (
                    id INTEGER PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT
                )
            """)

            conn.execute("""
                CREATE TABLE IF NOT EXISTS chapters (
                    id INTEGER PRIMARY KEY,
                    collection_id INTEGER,
                    name TEXT NOT NULL,
                    arabic_name TEXT,
                    FOREIGN KEY (collection_id) REFERENCES collections(id)
                )
            """)

            conn.execute("""
                CREATE TABLE IF NOT EXISTS hadiths (
                    id INTEGER PRIMARY KEY,
                    collection_id INTEGER,
                    chapter_id INTEGER,
                    hadith_number TEXT,
                    text TEXT NOT NULL,
                    arabic_text TEXT,
                    grade TEXT,
                    narrator TEXT,
                    keywords TEXT,
                    FOREIGN KEY (collection_id) REFERENCES collections(id),
                    FOREIGN KEY (chapter_id) REFERENCES chapters(id)
                )
            """)

            # Create full-text search index
            conn.execute("""
                CREATE VIRTUAL TABLE IF NOT EXISTS hadith_search 
                USING fts5(
                    hadith_id UNINDEXED,
                    text,
                    arabic_text,
                    keywords
                )
            """)

    def add_collection(self, name: str, description: str = None) -> int:
        """Add a new hadith collection"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                "INSERT INTO collections (name, description) VALUES (?, ?)",
                (name, description)
            )
            return cursor.lastrowid

    def add_chapter(self, collection_id: int, name: str, arabic_name: str = None) -> int:
        """Add a new chapter to a collection"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                "INSERT INTO chapters (collection_id, name, arabic_name) VALUES (?, ?, ?)",
                (collection_id, name, arabic_name)
            )
            return cursor.lastrowid

    def add_hadith(self, data: Dict) -> int:
        """Add a new hadith"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("""
                INSERT INTO hadiths (
                    collection_id, chapter_id, hadith_number, 
                    text, arabic_text, grade, narrator, keywords
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                data['collection_id'],
                data.get('chapter_id'),
                data['hadith_number'],
                data['text'],
                data.get('arabic_text'),
                data.get('grade'),
                data.get('narrator'),
                data.get('keywords')
            ))
            
            hadith_id = cursor.lastrowid
            
            # Add to search index
            conn.execute("""
                INSERT INTO hadith_search (hadith_id, text, arabic_text, keywords)
                VALUES (?, ?, ?, ?)
            """, (
                hadith_id,
                data['text'],
                data.get('arabic_text', ''),
                data.get('keywords', '')
            ))
            
            return hadith_id

    def search_hadiths(self, query: str, limit: int = 5) -> List[Dict]:
        """Search hadiths using full-text search"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            
            # Search in both text and keywords
            cursor = conn.execute("""
                SELECT h.*, c.name as collection_name, ch.name as chapter_name
                FROM hadith_search hs
                JOIN hadiths h ON hs.hadith_id = h.id
                JOIN collections c ON h.collection_id = c.id
                LEFT JOIN chapters ch ON h.chapter_id = ch.id
                WHERE hadith_search MATCH ?
                ORDER BY rank
                LIMIT ?
            """, (query, limit))
            
            results = []
            for row in cursor:
                results.append({
                    'collection': row['collection_name'],
                    'chapter': row['chapter_name'],
                    'hadith_number': row['hadith_number'],
                    'text': row['text'],
                    'arabic_text': row['arabic_text'],
                    'grade': row['grade'],
                    'narrator': row['narrator']
                })
            
            return results
