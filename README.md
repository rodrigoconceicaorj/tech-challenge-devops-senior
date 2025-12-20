## Stack Cloud

- Python 3.11 + Flask (FastAPI style endpoints)
- **AWS**: Provedor de Nuvem Principal
- **EKS**: Kubernetes Gerenciado para orquestração
- **RDS**: Banco de dados PostgreSQL Gerenciado (privado)
- **Terraform**: Infraestrutura como Código
- **GitHub Actions**: Pipeline CI/CD completo

## Como rodar localmente

### Pré-requisitos
- Docker & Docker Compose
- Python 3.11+ (opcional, para rodar sem container)

### Execução via Docker Compose (Recomendado)
A maneira mais simples de subir a aplicação completa (API + Banco de Dados) localmente:

1. Clone o repositório
2. Execute o comando na raiz do projeto:
```bash
docker-compose up --build
```
3. A API estará disponível em `http://localhost:5000`

### Execução Manual (Python venv)

1. Crie e ative ambiente virtual:
   - Windows: `python -m venv venv; .\venv\Scripts\Activate.ps1`
   - Linux/Mac: `python -m venv venv; source venv/bin/activate`

2. Instale dependências:
```bash
pip install -r api/requirements.txt
```

3. Configure as variáveis de ambiente (crie um arquivo `.env` ou exporte no terminal):
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=commentsdb
DB_USER=commentsuser
DB_PASSWORD=commentspass
```

4. Suba apenas o banco via Docker:
```bash
docker-compose up -d postgres
```

5. Rode a API:
```bash
python api/app.py
```

## Provisionamento na AWS (Terraform)

A infraestrutura é gerenciada via Terraform na pasta `infra/terraform`.

### Pré-requisitos
- AWS CLI configurado (`aws configure`)
- Terraform instalado
- Permissões de AdministratorAccess (ou equivalentes para VPC, EKS, RDS)

### Passos
1. Navegue até a pasta:
```bash
cd infra/terraform
```
2. Inicialize e aplique:
```bash
terraform init
terraform apply
```
3. O output fornecerá o endpoint do cluster EKS e dados de conexão.

## CI/CD (GitHub Actions)

O pipeline automatizado cobre:
1. **Build**: Construção da imagem Docker.
2. **Package**: Push da imagem para o ECR.
3. **Deploy**: Atualização dos manifestos Kubernetes no EKS e criação do segredo de DB.

Para acionar, basta fazer um push para a branch `main`.

## Monitoramento

- **Health Check**: `GET /health`
- **Métricas**: `GET /metrics` (Formato Prometheus)
- **Dashboard**: Grafana (vide pasta `ops/grafana`)

## Endpoints da API

- `POST /api/comment/new`: Cria um novo comentário.
- `GET /api/comment/list/{content_id}`: Lista comentários de um conteúdo específico.

## Decisões Técnicas e Arquitetura

- Provedor: **AWS** (ambiente real).
- Rede: **VPC** `10.0.0.0/16` com subnets privadas e **NAT** para saída; **IGW** para tráfego público do LoadBalancer.
- Segurança: **Security Groups** separados para app (HTTP 80) e banco (Postgres 5432 apenas do SG da app).
- Banco: **RDS PostgreSQL** privado (subnets privadas), sem acesso público; credenciais e host consumidos via **Secret** no Kubernetes.
- Compute: **EKS** `1.30` com **NodeGroup** em subnets privadas (`instance_types = ["t3.small"]`, `disk_size = 30`).
- Exposição: **Service** `LoadBalancer` para a API.
- Deploy: **GitHub Actions** publica a imagem no **ECR**, cria/atualiza o **Secret** com o endpoint do RDS e aplica `Deployment`, `Service` e `HPA`.
- Container: **Dockerfile** `python:3.11-slim`, execução com **gunicorn**, usuário **não-root**.
- Observabilidade: **/health** e **/metrics** (Prometheus).
- Destruição: `terraform destroy` e workflow `Destroy Infra` para remoção organizada.

### Racional
- Subnets privadas protegem o banco; NAT permite saída controlada sem expor instâncias.
- Segredo de DB no cluster evita variáveis sensíveis em repositório.
- Service `LoadBalancer` simplifica validação pública sem exigir Ingress/TLS no desafio.
- Usuário não-root e imagem slim reduzem superfície de ataque e tamanho.

### Como Validar
1. Executar `terraform apply` em `infra/terraform`.
2. Disparar `Build and Deploy` no GitHub Actions.
3. `kubectl get svc comments-api-svc` e acessar `EXTERNAL-IP`:
   - `GET /health`, `POST /api/comment/new`, `GET /api/comment/list/{content_id}`, `GET /metrics`.
4. Encerrar custos com `Destroy Infra` (Actions) ou `terraform destroy`.
