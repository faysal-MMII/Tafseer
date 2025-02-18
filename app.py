from flask import Flask, request, jsonify, render_template
from src.quran.quran_rag import QuranRAG
from src.hadith.hadith_rag import HadithRAG
from src.common.config import get_config
from flask_cors import CORS
import os
import traceback
import time

app = Flask(__name__)
CORS(app)

# Initialize configuration and RAG systems
try:
    print("Loading configuration...")
    config = get_config()
    app.config.from_object(config)
    
    print("Initializing Quran and Hadith systems...")
    quran_system = QuranRAG(config)
    hadith_system = HadithRAG(config)  # Using HadithRAG
    print("Systems initialized successfully")
    
except Exception as e:
    print(f"Error during initialization: {str(e)}")
    traceback.print_exc()
    raise

@app.route('/')
def home():
    """Render the main page"""
    return render_template('index.html', title='Islam101')

@app.route('/api/ask', methods=['POST'])
def ask_question():
    """Handle question requests"""
    try:
        start_time = time.time()
        print("\n--- Processing new question ---")
        
        data = request.get_json()
        if not data or 'question' not in data:
            return jsonify({'error': 'Please provide a question'}), 400
        
        question = data['question'].strip()
        print(f"Received question: {question}")
        
        if not question:
            return jsonify({
                'error': config.ERROR_MESSAGES['invalid_query']
            }), 400

        response = {}

        # Get Quran response
        try:
            print("Getting Quran response...")
            quran_response = quran_system.generate_response(question)
            response['quran_results'] = quran_response
            print("Quran response received")
        except Exception as e:
            print(f"Error in Quran response: {str(e)}")
            response['quran_results'] = {
                "answer": "Error processing Quran search. Please try again.",
                "verses": []
            }

        # Get Hadith response
        try:
            print("Getting Hadith response...")
            hadith_response = hadith_system.generate_response(question)
            print("Hadith response received")
            response['hadith_results'] = hadith_response
        except Exception as e:
            print(f"Error in Hadith response: {str(e)}")
            response['hadith_results'] = {
                "answer": "Error processing Hadith search. Please try again.",
                "hadiths": []
            }

        response['processing_time'] = f"{time.time() - start_time:.2f} seconds"
        return jsonify(response)

    except Exception as e:
        print(f"Error processing request: {str(e)}")
        traceback.print_exc()
        return jsonify({
            'error': str(e),
            'message': 'An unexpected error occurred'
        }), 500

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    try:
        return jsonify({
            'status': 'healthy',
            'quran_system': 'ok',
            'hadith_system': 'ok',
            'version': '1.0.0'
        })
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 500

@app.errorhandler(404)
def not_found(e):
    """Handle 404 errors"""
    return jsonify({
        'error': 'Route not found',
        'message': 'The requested resource does not exist'
    }), 404

@app.errorhandler(500)
def server_error(e):
    """Handle 500 errors"""
    return jsonify({
        'error': 'Internal server error',
        'message': 'An unexpected error occurred'
    }), 500

if __name__ == '__main__':
    print("\nStarting Islam101 server...")
    port = int(os.getenv('PORT', 8000))
    debug = config.DEBUG if hasattr(config, 'DEBUG') else True
    
    print(f"Server configured on port {port}")
    print(f"Debug mode: {debug}")
    print("Ready to handle requests\n")
    
    app.run(
        debug=debug,
        host='127.0.0.1',
        port=port
    )