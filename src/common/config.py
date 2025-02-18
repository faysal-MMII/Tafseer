from dotenv import load_dotenv
import os
import secrets

# Load environment variables from .env file
load_dotenv()

print("Loading dotenv...")
load_dotenv()

print("Environment variables loaded.")
print(f"OPENAI_API_KEY: {os.getenv('OPENAI_API_KEY')}")
print(f"OPENAI_MODEL: {os.getenv('OPENAI_MODEL')}")
print(f"QURAN_API_URL: {os.getenv('QURAN_API_URL')}")
print(f"QURAN_API_LANGUAGE: {os.getenv('QURAN_API_LANGUAGE')}")
print(f"APP_SECRET_KEY: {os.getenv('APP_SECRET_KEY')}")
print(f"DEBUG: {os.getenv('DEBUG')}")
print(f"MAX_SEARCH_RESULTS: {os.getenv('MAX_SEARCH_RESULTS')}")
print(f"CACHE_TIMEOUT: {os.getenv('CACHE_TIMEOUT')}")
print(f"MAX_REQUESTS_PER_MINUTE: {os.getenv('MAX_REQUESTS_PER_MINUTE')}")
print(f"FLASK_ENV: {os.getenv('FLASK_ENV')}")


class Config:
    """Configuration class for IlmCompass application"""
    
    # OpenAI Configuration
    OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
    OPENAI_MODEL = os.getenv('OPENAI_MODEL', 'gpt-3.5-turbo')
    
    # Quran API Configuration
    QURAN_API_URL = os.getenv('QURAN_API_URL', 'https://api.quran.com/api/v4')
    QURAN_API_LANGUAGE = os.getenv('QURAN_API_LANGUAGE', 'en')
    
    # Application Configuration
    APP_SECRET_KEY = os.getenv('APP_SECRET_KEY', secrets.token_hex(32))
    DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'
    MAX_SEARCH_RESULTS = int(os.getenv('MAX_SEARCH_RESULTS', 10))
    CACHE_TIMEOUT = int(os.getenv('CACHE_TIMEOUT', 3600))
    
    # Rate Limiting
    MAX_REQUESTS_PER_MINUTE = int(os.getenv('MAX_REQUESTS_PER_MINUTE', 60))
    
    # Error Messages
    ERROR_MESSAGES = {
        'no_results': 'No verses found. Try rephrasing your question.',
        'api_error': 'An error occurred while searching. Please try again.',
        'rate_limit': 'Too many requests. Please wait a moment.',
        'invalid_query': 'Please provide a valid question.'
    }
    
    # Verse Display Settings
    SHOW_ARABIC_TEXT = True
    SHOW_TRANSLATION = True
    SHOW_CONTEXT = True
    
    # ChatGPT Prompt Settings
    CHATGPT_TEMPERATURE = 0.7
    CHATGPT_MAX_TOKENS = 500
    CHATGPT_SYSTEM_PROMPT = """You are a knowledgeable Islamic scholar providing thoughtful,
    balanced interpretations of Quranic verses."""

    # RAG Configuration (ADD HERE)
    EMBEDDING_MODEL = "sentence-transformers/all-mpnet-base-v2"
    RAG_TOP_K_RESULTS = 5
    
    # Caching Settings for RAG
    VERSE_CACHE_SIZE = 1000
    EMBEDDING_CACHE_SIZE = 1000
    
    # Response Generation Settings
    INCLUDE_RELEVANCE_SCORES = True
    MINIMUM_SIMILARITY_THRESHOLD = 0.5
    
    @staticmethod
    def is_production():
        """Check if the application is running in production mode"""
        return os.getenv('FLASK_ENV') == 'production'
    
    @staticmethod
    def validate_config():
        """Validate that all required configuration variables are set"""
        required_vars = ['OPENAI_API_KEY']
        missing_vars = [var for var in required_vars if not os.getenv(var)]
        
        if missing_vars:
            raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    CACHE_TIMEOUT = 300  # 5 minutes in development

class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    CACHE_TIMEOUT = 3600  # 1 hour in production
    
    # Stricter rate limiting in production
    MAX_REQUESTS_PER_MINUTE = 30

# Create a config dictionary for different environments
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}

def get_config():
    """Get the appropriate configuration based on environment"""
    env = os.getenv('FLASK_ENV', 'development')
    return config.get(env, config['default'])