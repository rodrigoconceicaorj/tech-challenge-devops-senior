from flask import Flask, request, jsonify   
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware

app = Flask(__name__)
"nao estava aparecendo o /metrics na rota"
metrics = PrometheusMetrics(app, path="/metrics")
app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {"/metrics": make_wsgi_app()})

# DB in memory (inicial)
comments = []


@app.route("/health", methods=["GET"]) 
def health():
    """Liveness e readiness kubernetes"""
    return jsonify({"status": "ok"}), 200


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
    
    new_comment = {
        "email": str(email),
        "comment": str(comment_text),
        "content_id": str(content_id)
    }
    
    comments.append(new_comment)
    return jsonify(new_comment), 201


@app.route("/api/comment/list/<content_id>", methods=["GET"])
def list_comments(content_id):
    """Retorna comentários filtrados por content_id"""
    filtered = [c for c in comments if c.get("content_id") == str(content_id)]
    return jsonify(filtered), 200


# /metrics é criado automaticamente pelo PrometheusMetrics(app)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
