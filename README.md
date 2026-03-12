# Raffle API

API em Ruby on Rails para gestão de rifas vinculadas a resultados de loterias externas. O projeto organiza operações multi-tenant por `organization`, controla autenticação com JWT, expõe endpoints REST para administração das rifas e sincroniza sorteios a partir de uma API externa.

## Visão geral do escopo

O sistema cobre quatro frentes principais:

- autenticação de participantes, administradores e super admins;
- cadastro e gestão de organizações;
- criação e operação de rifas com regras de ciclo de vida;
- sincronização de loterias, horários e resultados de sorteio.

## Regras de negócio principais

### Organizações

- cada organização possui identidade própria, `slug`, contato e logo;
- usuários comuns e admins pertencem a uma organização;
- super admins podem operar sem vínculo com organização.

### Usuários e perfis

- `participant`: consome rifas abertas;
- `admin`: gerencia rifas e identidade da organização;
- `super_admin`: gerencia organizações em nível global.

### Rifas

- uma rifa pertence a uma organização e a uma loteria;
- modos de sorteio suportados:
  - `centena`: 100 bilhetes
  - `milhar`: 1.000 bilhetes
  - `dezena_de_milhar`: 10.000 bilhetes
- status suportados:
  - `draft`
  - `open`
  - `closed`
  - `drawn`
  - `cancelled`
- transições permitidas:
  - `draft -> open/cancelled`
  - `open -> closed/cancelled`
  - `closed -> drawn/cancelled`
- a data do sorteio precisa estar no futuro na criação;
- o `draw_mode` não pode ser alterado depois que a rifa sai de `draft`;
- cada rifa pode ter até 5 prêmios configurados.

### Bilhetes e resultados

- bilhetes pertencem a um usuário e a uma rifa;
- resultados de sorteio são armazenados por data e horário da loteria;
- a integração externa alimenta `lotteries`, `lottery_schedules` e `draws`.

## Stack técnica

- Ruby `4.0.0` no Dockerfile
- Rails `8.1.2`
- PostgreSQL
- JWT para autenticação
- Active Storage para logo da organização
- Solid Queue, Solid Cache e Solid Cable
- RSpec, FactoryBot, VCR, WebMock, Rswag e SimpleCov
- Motor Admin para painel administrativo
- Kamal para deploy

## Arquitetura resumida

### Camadas

- `app/controllers`: endpoints da API
- `app/services`: regras de aplicação e integrações externas
- `app/models`: domínio e validações
- `app/jobs`: processamento assíncrono e rotinas de sincronização
- `spec`: testes automatizados
- `swagger/v1/swagger.yaml`: documentação OpenAPI

### Fluxo principal

1. o usuário autentica via JWT;
2. a organização é identificada pelo token ou pelo header `X-Organization-Id`;
3. admins criam e operam rifas;
4. jobs sincronizam loterias e resultados;
5. os resultados persistidos podem ser usados para concluir sorteios.

## Endpoints principais

### Autenticação

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`

### Organização autenticada

- `PUT /api/v1/organization/update_logo`
- `DELETE /api/v1/organization/destroy_logo`

### Rifas

- `GET /api/v1/raffles`
- `GET /api/v1/raffles/:id`
- `POST /api/v1/raffles`
- `PUT /api/v1/raffles/:id`
- `DELETE /api/v1/raffles/:id`
- `POST /api/v1/raffles/:id/open`
- `POST /api/v1/raffles/:id/close`

### Super admin

- `GET /api/v1/super_admin/organizations`
- `GET /api/v1/super_admin/organizations/:id`
- `POST /api/v1/super_admin/organizations`
- `PUT /api/v1/super_admin/organizations/:id`
- `DELETE /api/v1/super_admin/organizations/:id`

### Utilitários

- `GET /up`: healthcheck
- `GET /api-docs`: UI da documentação Swagger
- `GET /motor_admin`: painel administrativo

## Autenticação e headers

Para rotas autenticadas, envie:

```http
Authorization: Bearer <jwt>
```

Para registro/login de usuários vinculados a uma organização, envie também:

```http
X-Organization-Id: <organization_id>
```

Observação: o login de `super_admin` funciona sem `X-Organization-Id`.

## Integração com API de loterias

O projeto consome uma API externa configurada por:

- `LOTTERY_API_KEY` obrigatório
- `LOTTERY_API_BASE_URL` opcional

Valor padrão atual para `LOTTERY_API_BASE_URL`:

```bash
https://api.sispts.com
```

Serviços relacionados:

- `LotteryApi::SyncLotteriesService`: sincroniza loterias e horários
- `LotteryApi::FetchDrawsService`: busca resultados por data
- `CheckPendingDrawsJob`: identifica sorteios pendentes do dia
- `SyncLotteriesJob`: dispara sincronização de loterias
- `FetchDrawsJob`: busca sorteios de uma loteria/data

## Setup local

### Pré-requisitos

- Ruby compatível com o projeto
- Bundler
- PostgreSQL
- libvips para processamento de imagem

### Banco via Docker

O repositório já inclui um `docker-compose.yml` com PostgreSQL:

```bash
docker compose up -d
```

Credenciais padrão locais:

- `DB_HOST=localhost`
- `DB_PORT=5432`
- `DB_USER=raffle`
- `DB_PASSWORD=raffle`
- banco `raffle_development`

### Instalação

```bash
bundle install
bin/setup --skip-server
```

### Subir a aplicação

```bash
bin/dev
```

A aplicação sobe em ambiente Rails local. O endpoint de healthcheck é `GET /up`.

## Variáveis de ambiente úteis

### Aplicação

- `LOTTERY_API_KEY`
- `LOTTERY_API_BASE_URL`
- `RAILS_MASTER_KEY`

### Banco

- `DB_HOST`
- `DB_PORT`
- `DB_USER`
- `DB_PASSWORD`

### Produção

- `RAFFLE_DATABASE_PASSWORD`

## Testes e qualidade

Testes automatizados estão concentrados em `spec/`.

Comandos úteis:

```bash
bundle exec rspec
bin/rubocop
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit
```

Também existe um pipeline local em:

```bash
bin/ci
```

## Deploy

O projeto já possui artefatos para operação em container:

- `Dockerfile`
- `captain-definition`
- `config/deploy.yml` para Kamal

Em produção, o `deploy.yml` está preparado para executar o Solid Queue junto do processo web com `SOLID_QUEUE_IN_PUMA=true`.

## Estrutura do repositório

```text
app/
  controllers/   # endpoints REST e autenticação
  jobs/          # rotinas assíncronas
  models/        # entidades e validações
  serializers/   # payloads JSON
  services/      # casos de uso e integração externa
config/
db/
spec/
swagger/
```

## Status atual do projeto

O repositório já contém:

- modelagem inicial do domínio;
- autenticação JWT;
- endpoints REST principais;
- integração com loterias externas;
- documentação Swagger;
- cobertura inicial de testes com RSpec.

Pontos que ainda parecem em evolução:

- popular seeds de desenvolvimento;
- detalhar rotina de processamento final da rifa após resultados;
- expandir documentação operacional conforme o fluxo de compra/pagamento dos bilhetes for implementado.
