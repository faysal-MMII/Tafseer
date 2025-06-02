# Tafseer: Islamic Knowledge & Guidance App

Tafseer is a comprehensive Flutter application providing Islamic knowledge, guidance, and practical features for Muslims worldwide. The app combines traditional Islamic texts with modern AI technology to provide accurate, contextual answers to Islamic questions.

## 📱 Latest Release
The latest version of the app can be found in the [Releases](https://github.com/faysal-MMII/Tafseer/releases) section. Each release includes:

- Release notes detailing new features and bug fixes
- Downloadable APK files for Android (if applicable)
- Installation instructions
- Known issues or limitations

⚠️ Always download the app from the official releases page to ensure you have the latest stable version.

## 🌟 Features

### Islamic Q&A with AI
- AI-powered question answering system using OpenAI (You can use whichever AI you want, just make sure you follow the API's documentation.)
- Answers grounded in Quranic verses and authentic Hadiths
- Retrieval-Augmented Generation (RAG) ensuring accurate Islamic context
- Pre-defined Q&A dataset for common Islamic questions

### Quran & Hadith
- Browse and search through the complete Quran
- Access Imam Nawawi's 40 Hadith collection
- Detailed verse and Hadith views
- Smart search functionality for finding relevant verses and Hadiths

### Practical Tools
- Islamic Places Finder
  - Locate nearby mosques, halal restaurants, and Islamic centers
  - Filter by place type and radius
  - Support for manual location input
- Personalized Islamic Facts
  - Region-specific facts
  - Context-aware fun facts
  - Monthly Islamic knowledge

### Additional Features
- Search history tracking
- Frequently Asked Questions (FAQ) section
- Responsive design for all screen sizes
- Offline support with data caching
- Analytics and crash reporting

## 🚀 Getting Started

### Prerequisites
- Flutter (latest version)
- Firebase account
- OpenAI API key

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/islamic-app.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Create a `.env` file in the root directory with your API keys:
```
OPENAI_API_KEY=your_openai_api_key
```

4. Set up Firebase:
   - Create a new Firebase project
   - Add your Firebase configuration files
   - Enable Analytics and Crashlytics

5. Run the app
```bash
flutter run
```

## 📱 App Structure

### Core Components

- **Screens**
  - HomeScreen: Main interface with search and navigation
  - QuranScreen: Quran browsing and search
  - HadithScreen: Hadith collection viewer
  - PlacesScreen: Islamic places finder
  - SearchResultsScreen: AI-powered search results
  - HistoryScreen: User search history

- **Services**
  - OpenAiService: AI integration
  - QuranService: Quranic data management
  - HadithService: Hadith data management
  - FirestoreService: Firebase integration
  - LocationService: Geolocation features
  - IslamicFactsData: Islamic knowledge base

- **RAG Services**
  - QuranRAGService: Quran-based AI responses
  - HadithRAGService: Hadith-based AI responses

### Data Sources
- Local JSON assets for Quran translations
- Nawawi's 40 Hadith collection
- Islamic Q&A dataset
- Regional boundary data for personalization

## 🛠 Technical Details

### Built With
- Flutter - UI framework
- Firebase - Backend services
- OpenAI API - AI capabilities
- flutter_map - Maps integration
- shared_preferences - Local storage
- http - API communication

### Key Features
- Responsive design for all screen sizes
- Efficient data caching
- Error handling and crash reporting
- Analytics integration
- Location-based services

## 📝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the LICENSE file for details.

## 🙏 Acknowledgments

- OpenAI for AI capabilities
- Firebase for backend services
- The Flutter team
- Contributors to the Islamic datasets used in this project

## 📞 Support

For support, please:
- Open an issue in this repository
- Contact us at [eccodg02@proton.me]

---
Made with ❤️ for the Muslim Ummah
# agile-final-project
