# Decisões e Histórico do Projeto

## Dia 1 - Entendimento da demanda, escolhendo stack     (14/12/2025)
**Aws - (familiarizado e requisitado no mercado)
**EKS - (preferencia do desafio e experiencia com k8s)
**RDS postgres - (robusto e comum em produção)
**Python + Flask (curva de aprendizado menor)

## estrutura do repositorio 
-  api/, infra/, k8s/, ops/
- .github/workflows/ (pipeline github action)


## Dia 2 - API básica local (14/12/2025)

### O que foi feito
- ✅ Setup do ambiente virtual Python
- ✅ Implementação de todos os endpoints básicos:
  - `GET /health` - retorna status ok
  - `POST /api/comment/new` - cria comentário com validação
  - `GET /api/comment/list/{id}` - lista comentários filtrados por content_id
  - `GET /metrics` - métricas Prometheus
- ✅ Storage em memória funcionando
- ✅ Testes manuais com Postman - todos endpoints validados

### Decisões técnicas
- Usei `prometheus-flask-exporter` para métricas automáticas
- Adicionei `DispatcherMiddleware` para garantir que `/metrics` apareça corretamente
- Validação de campos obrigatórios antes de salvar comentário
- Filtragem por `content_id` usando list comprehension

### Problemas encontrados
- Inicialmente `/metrics` não aparecia - resolvido com DispatcherMiddleware
- Erro 400 no Postman - faltava vírgula no JSON (erro de sintaxe)

### Tempo gasto
Aproximadamente 2 horas (incluindo troubleshooting)

### Próximos passos (Dia 3)
- Integrar com banco Postgres local (Docker Compose)
- Criar Dockerfile
- Substituir storage em memória por INSERT/SELECT no DB
