import faiss
import numpy as np
import pickle
import os
from google import genai   # ✅ Gemini client
from mistralai import Mistral  # ✅ Mistral client


class RagPipeline:
    def __init__(self, 
                 index_path="vectors.index", 
                 chunks_path="chunks.pkl",
                 gemini_model="gemini-1.5-flash",
                 mistral_model="mistral-embed"):

        # Load API keys
        self.gemini_key = os.getenv("GEMINI_API_KEY") or "AIzaSyCMz0rytVT9biyUhYVCB8K42FjLAcRh7Hw"
        self.mistral_key = os.getenv("MISTRAL_API_KEY") or "u9QZxvoJD7xxQmJKiRRwTcFkJueATN9p"

        # Init clients
        self.client_gemini = genai.Client(api_key=self.gemini_key)
        self.client_mistral = Mistral(api_key=self.mistral_key)

        # Models
        self.gemini_model = gemini_model
        self.mistral_model = mistral_model

        # Load FAISS + chunks
        if not os.path.exists(index_path) or not os.path.exists(chunks_path):
            raise FileNotFoundError("Vector DB not found. Run pdf_to_vectors.py first.")

        self.index = faiss.read_index(index_path)
        with open(chunks_path, "rb") as f:
            data = pickle.load(f)

        self.chunks = data["chunks"]
        self.total_pages = data["total_pages"]

    def embed_text(self, text: str):
        """Generate embeddings using Mistral API"""
        response = self.client_mistral.embeddings.create(
            model=self.mistral_model,
            inputs=text
        )
        return np.array(response.data[0].embedding).reshape(1, -1)

    def retrieve(self, query: str, top_k=3):
        """Retrieve top-k chunks using FAISS"""
        query_vec = self.embed_text(query)
        scores, indices = self.index.search(query_vec.astype("float32"), top_k)

        retrieved_chunks = []
        for score, idx in zip(scores[0], indices[0]):
            if idx < len(self.chunks):
                retrieved_chunks.append((self.chunks[idx], float(score)))
        return retrieved_chunks

    def answer(self, query: str, top_k=3):
        """Generate answer with Gemini using retrieved context"""
        retrieved = self.retrieve(query, top_k=top_k)
        context = "\n\n".join([c[0] for c in retrieved])

        prompt = (
            "You are a helpful **medical chatbot**. "
            "You only answer medical or health-related questions. "
            "If the question is outside the scope of medicine, respond strictly with:\n"
            "'I am a medical chatbot and cannot provide recommendations on that topic. "
            "That's outside the scope of my medical expertise.'\n\n"
            f"Context (from PDF): {context}\n\n"
            f"User Question: {query}\nAnswer:"
        )

        response = self.client_gemini.models.generate_content(
            model=self.gemini_model,
            contents=[prompt]
        )

        answer_text = response.candidates[0].content.parts[0].text
        return answer_text, [c[0] for c in retrieved]
