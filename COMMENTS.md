# Decisões e Histórico do Projeto

## Decisões Técnicas

### Arquitetura
- **Cloud Provider**: AWS (escolhida por familiaridade e suporte robusto a EKS).
- **Orquestração**: EKS (Elastic Kubernetes Service) para gerenciamento de containers.
- **Banco de Dados**: Amazon RDS (PostgreSQL) para persistência gerenciada.
- **IaC**: Terraform para provisionamento de infraestrutura.
- **CI/CD**: GitHub Actions para automação de build, scan e deploy.

### Desenvolvimento da API
- **Linguagem**: Python (FastAPI) pela rapidez de desenvolvimento e suporte nativo a async.
- **Container**: Dockerfile multi-stage build para gerar imagem slim e segura (usuário não-root).

### Infraestrutura
- **Rede**: VPC com subnets públicas (para Load Balancers) e privadas (para EKS e RDS).
- **Segurança**: Security Groups restritos, IAM Roles com least privilege.

## Histórico de Experimentos

### Testes com LocalStack
- Inicialmente, tentamos simular o ambiente AWS localmente com LocalStack para economizar custos.
- **Resultado**: Abandonado devido a complexidades na emulação de EKS e RDS, optando por testes diretos na AWS com recursos mínimos (Free Tier elegível onde possível).

### Gestão de Segredos
- **Decisão**: Utilizar variáveis de ambiente injetadas via Kubernetes Secrets (para simplicidade inicial) com plano de migração para AWS Secrets Manager + External Secrets Operator.

## Próximos Passos (Ideias de Evolução)
- Implementar External Secrets Operator.
- Adicionar dashboard Grafana para visualização de métricas Prometheus.
- Refinar políticas de Network Policies no Kubernetes.
