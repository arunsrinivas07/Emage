from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
from speech_service import SpeechService
from rag_pipeline import RagPipeline

app = Flask(__name__)
CORS(app)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("emergency_api")

# Initialize RAG pipeline
rag_pipeline = RagPipeline()
speech_service = SpeechService()

@app.route('/api/process_query', methods=['POST'])
def process_query():
    data = request.json
    if not data or 'query' not in data:
        return jsonify({"error": "No query provided"}), 400
    
    query = data['query']
    logger.info(f"Received query: {query}")

    result = speech_service.process_query(query)
    return jsonify(result)

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
