## Stack Cloud

- Python 3.11 + Flask (FastAPI style endpoints)
- **AWS**: Provedor de Nuvem Principal
- **EKS**: Kubernetes Gerenciado para orquestração
- **RDS**: Banco de dados PostgreSQL Gerenciado (privado)
- **Terraform**: Infraestrutura como Código
- **GitHub Actions**: Pipeline CI/CD completo
-
## Como rodar localmente (dev)
 
### Pré-requisitos
- Python 3.11+
- Pip e venv
 
### Passos
1. Criar e ativar venv:
   - Windows:
     ```
     python -m venv venv
     .\venv\Scripts\Activate.ps1
     ```
   - Linux/Mac:
     ```
     python -m venv venv
     source venv/bin/activate
     ```
2. Instalar dependências:
   ```
   pip install -r api/requirements.txt
   ```
3. Configurar variáveis (exemplo banco local ou remoto):
   ```
   set DB_HOST=localhost
   set DB_PORT=5432
   set DB_NAME=commentsdb
   set DB_USER=comments_user
   set DB_PASSWORD=commentspass
   ```
   Linux/Mac: use `export VAR=valor`.
4. Executar API:
   ```
   python api/app.py
   ```
5. Endpoints:
   - `GET http://localhost:5000/health`
   - `POST http://localhost:5000/api/comment/new`
   - `GET http://localhost:5000/api/comment/list/{content_id}`
   - `GET http://localhost:5000/metrics`
 
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
1. **Test**: Executa testes unitários (`pytest`) da API.
2. **Scan (IaC)**: Checkov (Terraform).
3. **Build**: Construção da imagem Docker.
4. **Scan (Container)**: Trivy (CRITICAL/HIGH).
5. **Package**: Push da imagem para o ECR.
6. **Deploy**: Atualização dos manifestos Kubernetes no EKS e criação/atualização do segredo de DB.

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
5. Evidências operacionais e comandos: veja `COMMENTS.md` (seção "Evidências Operacionais").

### Comandos úteis
- Imagem do deployment:
  ```
  kubectl get deployment comments-api -o jsonpath='{.spec.template.spec.containers[0].image}'
  ```
- Status de rollout:
  ```
  kubectl rollout status deployment/comments-api --timeout=180s
  ```
- Pods do app:
  ```
  kubectl get pods -l app=comments-api -o wide
  ```
- Hostname do LoadBalancer:
  ```
  kubectl get svc comments-api-svc -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  ```
- Health check:
  ```
  curl http://<EXTERNAL-HOSTNAME>/health
  ```

## Rollback
- Ver histórico:
  ```
  kubectl rollout history deployment/comments-api
  ```
- Desfazer para revisão anterior:
  ```
  kubectl rollout undo deployment/comments-api
  ```

## Gestão de Segredos
- Atual: Kubernetes Secret (`db-secret`) gerado pelo pipeline com endpoint do RDS e credenciais.
- Evolução: AWS Secrets Manager + External Secrets Operator (planejado) para reduzir acoplamento e reforçar RBAC/IRSA.

## Transparência (tempo, referências)
- Tempo gasto: ~2 dias úteis em ajustes, validações e automações; ~1 dia em provisionamento/depuração AWS.
- Referências:
  - Documentação AWS (EKS, RDS, ECR, VPC)
  - Kubernetes Probes e HPA
  - Checkov e Trivy (ações oficiais)
