# Tafseer

An Islamic Q&A application available in both Flutter (mobile) and Flask (web) versions, providing answers to questions about Islam through Quranic verses and Hadith guidance.

## Project Overview

Tafseer exists in two versions:

### Flask Version (Web)
- Built with Python Flask framework
- Powered by OpenAI's API for dynamic responses
- Accessible via web browser at `http://127.0.0.1:8000/` after running app.py
- Provides real-time answers using ChatGPT

### Flutter Version (Mobile)
- Native mobile application
- Uses pre-compiled Q&A database
- Offline functionality
- Structured responses with Quranic and Hadith sections

## Features

- Islamic knowledge Q&A system
- Split view of Quranic verses and Hadith guidance
- Elegant UI (Lesss is more)
- Search functionality for quick answers



## Technology Stack

- **Flask Version:**
  - Python
  - Flask
  - OpenAI API
  - HTML/CSS

- **Flutter Version:**
  - Dart
  - Flutter SDK
  - SQLite
  - JSON data storage

## Installation

### Flask Version
1. Clone the repository
2. Install requirements:
   ```bash
   pip install -r requirements.txt
   ```
3. Set up OpenAI API key in `.env` file
4. Run the application:
   ```bash
   python app.py
   ```
5. Navigate to `http://127.0.0.1:8000/`

### Flutter Version
1. Ensure Flutter is installed
2. Clone the repository
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Usage

1. Launch the application (web or mobile)
2. Enter your Islamic question in the search box
3. View the response split into:
   - Quranic Evidence
   - Hadith Guidance

## Data Sources

- **Flask Version:** Utilizes OpenAI's GPT model for dynamic responses
- **Flutter Version:** Uses curated `islamic_qa.json` database with pre-compiled answers

## Development

The project evolved from a web-based Flask application to a mobile Flutter application, with the key difference being:
- Flask version: Dynamic responses using AI
- Flutter version: Static responses from curated database




## Contributing

Feel free to submit issues and enhancement requests.

## Contact

[eccodg02@proton.me]

## Modifying the Q&A Database

The Q&A database is stored in `assets/data/islamic_qa.json`. To add or modify questions:

1. Each question should follow this format:
```json
{
  "keywords": ["keyword1", "keyword2", ...],
  "question": "Your question here?",
  "quran_results": {
    "answer": "Your Quranic answer...",
    "verses": ["**Verse X:Y**", ...]
  },
  "hadith_results": {
    "answer": "Your Hadith guidance...",
    "hadiths": [
      {
        "collection": "Collection name",
        "reference": "Reference number",
        "text": "Hadith text"
      }
    ]
  }
}
