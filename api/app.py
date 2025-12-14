from flask import Flask, request, jsonify   
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware
import psycopg2 #postgres
import os #ler variaveis de ambiente
from dotenv import load_dotenv #para carregar o .env

# Carregar variáveis de ambiente do arquivo .env
load_dotenv()

app = Flask(__name__)
metrics = PrometheusMetrics(app, path="/metrics")
app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {"/metrics": make_wsgi_app()})

# Função para conectar no banco Postgres
def get_db_connection():
    conn = psycopg2.connect(
        host=os.getenv('DB_HOST'),
        port=os.getenv('DB_PORT'),
        database=os.getenv('DB_NAME'),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD')
    )
    return conn


@app.route("/health", methods=["GET"]) 
def health():
    """Liveness e readiness kubernetes"""
    try:
        # Testa conexão com o banco
        conn = get_db_connection()
        conn.close()
        return jsonify({"status": "ok", "database": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "error", "database": "disconnected", "error": str(e)}), 503


@app.route("/api/comment/new", methods=["POST"])
def create_comment():
    if not request.is_json:
        return jsonify({"error": "Content-Type deve ser application/json"}), 400
    
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Body JSON vazio"}), 400
    
    email = data.get("email")
    comment_text = data.get("comment")
    content_id = data.get("content_id")
    
    if not email or not comment_text or not content_id:
        return jsonify({
            "error": "Campos obrigatórios: email, comment, content_id"
        }), 400
    
    try:
        # Conecta no banco e insere comentário
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute(
            "INSERT INTO comments (email, comment, content_id) VALUES (%s, %s, %s) RETURNING id, created_at",
            (email, comment_text, content_id)
        )
        
        result = cursor.fetchone()
        comment_id = result[0]
        created_at = result[1]
        
        conn.commit()
        cursor.close()
        conn.close()
        
        new_comment = {
            "id": comment_id,
            "email": email,
            "comment": comment_text,
            "content_id": content_id,
            "created_at": str(created_at)
        }
        
        return jsonify(new_comment), 201
        
    except Exception as e:
        return jsonify({"error": f"Erro ao salvar no banco: {str(e)}"}), 500


@app.route("/api/comment/list/<content_id>", methods=["GET"])
def list_comments(content_id):
    """Retorna comentários filtrados por content_id"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute(
            "SELECT id, email, comment, content_id, created_at FROM comments WHERE content_id = %s ORDER BY created_at DESC",
            (content_id,)
        )
        
        rows = cursor.fetchall()
        
        comments = []
        for row in rows:
            comments.append({
                "id": row[0],
                "email": row[1],
                "comment": row[2],
                "content_id": row[3],
                "created_at": str(row[4])
            })
        
        cursor.close()
        conn.close()
        
        return jsonify(comments), 200
        
    except Exception as e:
        return jsonify({"error": f"Erro ao buscar comentários: {str(e)}"}), 500


# /metrics é criado automaticamente pelo PrometheusMetrics(app)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
