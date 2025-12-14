## Stack Cloud

- python 3.11 + flask
- AWS
- EKS
- RDS postgres
- terraform
- github actions

## Como rodar localmente

### Pré-requisitos
- Python 3.11+ (testado em 3.13)
- pip

### Instalação

1. Clone o repositório
2. Crie e ative ambiente virtual:

Windows PowerShell
python -m venv venv
.\venv\Scripts\Activate.ps1

Linux/macOS
python -m venv venv
source venv/bin/activate

3. Instale dependências:
pip install -r api/requirements.txt

4. Execute a API:
python api/app.py

A API estará disponível em `http://localhost:5000`

## Banco local com Docker

- Subir Postgres:
```
docker compose up -d postgres
```
- Ver status:
```
docker compose ps
```
- Variáveis usadas pela API (`.env`):
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=commentsdb
DB_USER=commentsuser
DB_PASSWORD=commentspass
```

### Endpoints disponíveis

- `GET /health` - Health check
- `POST /api/comment/new` - Criar comentário
- `GET /api/comments/list/<content_id>` - Listar comentários por content_id
- `GET /metrics` - Métricas Prometheus

### Exemplo de uso

**Criar comentário:**
POST http://localhost:5000/api/comment/new
Content-Type: application/json

{
"email": "user@example.com",
"comment": "Ótimo artigo!",
"content_id": "123"
}

text

**Listar comentários:**
GET http://localhost:5000/api/comments/list/123

## Validação com Postman

- Baixe e abra o Postman
- Crie um Environment chamado `local` com a variável:
  - `base_url = http://localhost:5000`
- Requests:
  - POST `{{base_url}}/api/comment/new`
    - Aba `Body` → `raw` → `JSON`
    - Cabeçalho: `Content-Type: application/json`
    - Corpo:
      ```
      {
        "email": "user@example.com",
        "comment": "Ótimo artigo!",
        "content_id": "123"
      }
      ```
    - Esperado: Status `201 Created` e o JSON do comentário
  - GET `{{base_url}}/api/comments/list/123`
    - Esperado: Status `200 OK` e lista de comentários
  - GET `{{base_url}}/metrics`
    - Esperado: Status `200 OK` e conteúdo em `text/plain` com métricas

### Dicas rápidas
- Se der `400` no POST, confira o `Content-Type: application/json` e o JSON válido
- Se `/metrics` retornar `404`, reinicie a API e tente `http://localhost:5000/metrics`
- Use sempre o mesmo `python` do seu venv: `python -m pip install ...` e `python api/app.py`

## Testes via curl (terminal)

### Windows PowerShell
- Health:
```
curl.exe http://localhost:5000/health
```
- Criar comentário:
```
curl.exe -X POST http://localhost:5000/api/comment/new ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"user@example.com\",\"comment\":\"Ótimo artigo!\",\"content_id\":\"123\"}"
```
- Listar comentários:
```
curl.exe http://localhost:5000/api/comments/list/123
```
- Métricas:
```
curl.exe http://localhost:5000/metrics
```

### Linux/macOS (bash)
- Health:
```
curl http://localhost:5000/health
```
- Criar comentário:
```
curl -X POST http://localhost:5000/api/comment/new \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","comment":"Ótimo artigo!","content_id":"123"}'
```
- Listar comentários:
```
curl http://localhost:5000/api/comments/list/123
```
- Métricas:
```
curl http://localhost:5000/metrics
```
