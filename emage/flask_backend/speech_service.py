import logging
from rag_pipeline import RagPipeline

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("emergency_bot")

class SpeechService:
    def __init__(self):
        # Load RAG pipeline
        self.rag = RagPipeline()

    def process_query(self, query: str):
        logger.info(f"Processing query with RAG: '{query}'")

        try:
            response, retrieved = self.rag.answer(query)
            return {"response": response, "retrieved_chunks": retrieved[:3]}
        except Exception as e:
            logger.error(f"Error in RAG pipeline: {e}")
            return {"response": "Error processing query"}
