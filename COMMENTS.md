# Decisões e Histórico do Projeto

## Decisões Técnicas

### Arquitetura
- **Cloud Provider**: AWS (escolhida por familiaridade e suporte robusto a EKS).
- **Orquestração**: EKS (Elastic Kubernetes Service) para gerenciamento de containers.
- **Banco de Dados**: Amazon RDS (PostgreSQL) para persistência gerenciada.
- **IaC**: Terraform para provisionamento de infraestrutura.
- **CI/CD**: GitHub Actions para automação de build, scan e deploy.

### Desenvolvimento da API
- **Linguagem**: Python (Flask) pela robustez e simplicidade.
- **Container**: Dockerfile multi-stage build para gerar imagem slim e segura (usuário não-root).

### Infraestrutura
- **Rede**: VPC com subnets públicas (para Load Balancers) e privadas (para EKS e RDS).
- **Segurança**: Security Groups restritos, IAM Roles com least privilege.

## Histórico de Experimentos e Mudanças de Direção

### Foco Total em Ambiente Remoto (AWS)
- **Contexto**: Inicialmente mantínhamos configurações para `docker-compose` local.
- **Decisão**: Removemos artefatos de desenvolvimento local (`docker-compose.yml`, scripts locais) para focar 100% na validação do ambiente produtivo no EKS. Isso garante que "funciona na minha máquina" não seja um argumento, pois todo o desenvolvimento é validado diretamente na nuvem, alinhado com a proposta de um teste sênior de DevOps.

### Estratégia de "Destroy" Robusta
- **Problema**: O `terraform destroy` pode falhar se o estado estiver inconsistente ou se recursos forem criados fora do Terraform (ex: LoadBalancers criados dinamicamente pelo Kubernetes).
- **Solução**: Implementamos um pipeline de destruição em duas camadas:
    1. **Camada 1 (Terraform)**: Tenta destruir via IaC padrão.
    2. **Camada 2 (Fallback Script)**: Um script bash "agressivo" que varre a AWS via CLI e remove recursos órfãos (VPC, Subnets, Security Groups, ECR, Cluster) caso o Terraform falhe. Isso previne custos acidentais ("cobrança surpresa") por recursos esquecidos.

### Testes com LocalStack
- Inicialmente, tentamos simular o ambiente AWS localmente com LocalStack para economizar custos.
- **Resultado**: Abandonado devido a complexidades na emulação de EKS e RDS, optando por testes diretos na AWS com recursos mínimos (Free Tier elegível onde possível).

### Gestão de Segredos
- **Decisão**: Utilizar variáveis de ambiente injetadas via Kubernetes Secrets (para simplicidade inicial) com plano de migração para AWS Secrets Manager + External Secrets Operator.

## Testes Executados
- **Unitários (pytest)**:
  - `/health`: sucesso (mock DB conectado) e falha (mock exceção), ambos cobrindo códigos 200 e 503.
  - `POST /api/comment/new`: sucesso (payload válido) e validação (payload inválido).
  - `GET /api/comment/list/{content_id}`: retorna lista simulada com duas entradas.
- **Resultado**: todos passaram localmente; pipeline agora executa `pytest` antes de scan/build.

## Evidências Operacionais
- Pods `comments-api` em `Running` e `db-init-job` em `Completed`.
- Endpoint público acessível via LoadBalancer (`/health` retornando status ok e banco conectado).
- Pipeline CI/CD acionado por push, com etapas de test, scan, package e deploy aplicadas no cluster.

### Comandos e Saídas
- Imagem atual do Deployment:
  ```
  kubectl get deployment comments-api -o jsonpath='{.spec.template.spec.containers[0].image}'
  408093795144.dkr.ecr.us-east-1.amazonaws.com/tech-challenge-api:d0c921511ff721035a140fc19fcc1b4e06f98f01
  ```
- Status do rollout:
  ```
  kubectl rollout status deployment/comments-api --timeout=180s
  deployment "comments-api" successfully rolled out
  ```
- Pods do aplicativo:
  ```
  kubectl get pods -l app=comments-api -o wide
  comments-api-7cffb8496-wkghg   1/1   Running   0   84s   10.0.2.80   ip-10-0-2-53.ec2.internal
  ```
- Endpoint público:
  ```
  kubectl get svc comments-api-svc -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  a278430904ef44afaa6ae2a2481e0d49-1781667903.us-east-1.elb.amazonaws.com
  ```
- Health check:
  ```
  GET http://a278430904ef44afaa6ae2a2481e0d49-1781667903.us-east-1.elb.amazonaws.com/health
  {"database":"connected","status":"ok"}
  ```
## Próximos Passos (Ideias de Evolução)
- Implementar External Secrets Operator.
- Adicionar dashboard Grafana para visualização de métricas Prometheus.
- Refinar políticas de Network Policies no Kubernetes.
