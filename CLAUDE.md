# Raffle API — Guia do Projeto

## Visão Geral

API Rails para gerenciamento de **rifas baseadas na Loteria Federal brasileira**. O resultado das rifas é determinado pelo sorteio oficial da Loteria Federal, consumido via API externa já disponível.

## Stack Tecnológica

| Componente | Escolha | Justificativa |
|---|---|---|
| Framework | Rails 8 (API mode) | Produtividade, ecossistema maduro |
| Banco de dados | PostgreSQL | Confiabilidade, suporte nativo no Rails |
| Background jobs | Solid Queue | Substitui Sidekiq/Redis, usa PostgreSQL |
| Cache | Solid Cache | Substitui Redis, usa PostgreSQL |
| Action Cable | Solid Cable | Substitui Redis adapter, usa PostgreSQL |
| Autenticação | JWT stateless | Token no header, sem sessão no servidor |
| Notificações | WhatsApp | Envio automático ao apurar ganhadores |
| Pagamento | Modelo misto | Gateway (webhook) + confirmação manual por admin |
| Multi-tenancy | Organization-scoped | Cada organização tem seus próprios dados |

## Princípio Solid-First

Evitar ao máximo dependências externas como Redis e Sidekiq. Usar os adapters Solid do Rails 8:

- **solid_queue** → jobs e workers
- **solid_cache** → cache store
- **solid_cable** → Action Cable adapter

Todos persistem no PostgreSQL, eliminando necessidade de Redis.

## Domínio do Negócio

### Entidades Principais

- **Organization**: tenant raiz — cada organização é isolada das demais (seller/empresa)
- **User**: usuário com papel (role) dentro de uma organização
  - `super_admin`: administrador da plataforma (acesso total, cross-tenant)
  - `admin`: administrador da organização (gerencia rifas, participantes, etc.)
  - `participant`: comprador de bilhetes dentro de uma organização
- **Raffle (Rifa)**: rifa criada por um admin, pertence a uma organização, vinculada a sorteio da Loteria Federal
- **Ticket (Bilhete)**: número(s) comprado(s) por um participante dentro de uma rifa
  - Status: `reserved` → `paid` | `expired` | `cancelled`
  - `reserved_until`: timestamp de expiração da reserva (ex: 30 min)
  - `payment_method`: `gateway` ou `manual`
  - `payment_reference`: ID da transação no gateway (quando aplicável)
  - **UNIQUE constraint em `(raffle_id, number)`** — unicidade garantida no banco, não na aplicação
- **Payment**: registro de pagamento vinculado ao ticket
  - Suporta webhook de gateway (confirmação automática)
  - Suporta confirmação manual por admin
- **LotteryResult (Resultado)**: resultado oficial da Loteria Federal, consultado via API externa
- **RafflePrize (Prêmio da Rifa)**: prêmio configurado em uma rifa — até 5 por rifa
  - `position`: 1º ao 5º prêmio
  - `description`: descrição do prêmio (ex: "Notebook", "R$ 500")
  - `lottery_prize_position`: qual prêmio da Loteria Federal determina o ganhador (1º, 2º, 3º...)
- **Draw (Sorteio)**: evento que processa o resultado da Loteria Federal e apura os ganhadores
  - Associa cada `RafflePrize` ao ticket vencedor com base no resultado da Loteria

### Multi-tenancy

- Todo recurso (rifas, bilhetes, usuários) pertence a uma **Organization**
- Queries sempre escopadas por `organization_id`
- Um usuário existe dentro do contexto de uma organização
- O `super_admin` é o único papel cross-tenant (gestão da plataforma)

### Regra de Negócio Principal

O resultado da Loteria Federal tem **4 dígitos** (0000–9999). O ganhador da rifa é determinado pela correspondência entre o número sorteado e o bilhete, com modalidades:

| Modalidade | Qtd. bilhetes | Correspondência |
|---|---|---|
| Centena | 100 números (00–99) | Últimos 2 dígitos do resultado |
| Milhar | 1.000 números (000–999) | Últimos 3 dígitos do resultado |
| Dezena de milhar | 10.000 números (0000–9999) | 4 dígitos completos do resultado |

- A **modalidade é configurada por rifa** no momento da criação
- O critério exato de correspondência (qual prêmio, quantos dígitos) é definido na rifa
- Pode haver **múltiplos prêmios** da Loteria Federal — qual usar é configurável por rifa

## Integração com Loteria Federal

- Já existe acesso a uma API de resultados da Loteria Federal
- A API será consultada para buscar resultados após cada sorteio
- Um job periódico verificará novos resultados e processará as rifas pendentes

## Arquitetura

```
app/
  controllers/api/v1/
  models/
  jobs/           # Solid Queue jobs
  services/       # Regras de negócio isoladas
  serializers/    # Respostas JSON
config/
  database.yml    # PostgreSQL
  queue.yml       # Solid Queue
  cache.yml       # Solid Cache
  cable.yml       # Solid Cable
```

## Passos e Decisões — Log

### [2026-03-11] Organization Model

**Implementado:** Model base do multi-tenancy — tenant raiz da aplicação.

**Decisões:**
- `slug` único globalmente (não por org) — identifica a organização no header `X-Organization-Id`
- `slug` normalizado (`downcase + strip`) via `before_validation` — aceita maiúsculas na entrada
- Status enum: `pending` (padrão), `active`, `suspended`
- `settings` como jsonb com índice GIN — campo livre para configurações futuras por organização
- `discarded_at` via discard gem (soft delete) adicionado em migration separada
- `has_one_attached :logo` — Active Storage para logo da organização
- Unicidade do slug enforçada no banco (índice único) além da validação na aplicação

**Arquivos criados:**
- `db/migrate/20260312002203_create_organizations.rb`
- `db/migrate/20260312005105_add_discarded_at_to_organizations.rb`
- `app/models/organization.rb`
- `spec/models/organization_spec.rb` (22 examples)
- `spec/factories/organizations.rb`

---

### [2026-03-11] Autenticação JWT

**Implementado:** `POST /api/v1/auth/register` e `POST /api/v1/auth/login`

**Decisões:**
- Email único por organização (índice composto `organization_id + email`)
- Organização identificada via header `X-Organization-Id` (front determina pelo hostname)
- JWT payload: `{ user_id:, organization_id: }` — ApplicationController resolve ambos do token
- `has_secure_password` + bcrypt (já no Gemfile)
- Role padrão no registro: `participant`
- Login rejeita usuários com soft delete (`kept` scope)
- Tenant isolation testado: usuário de org A não autentica em org B

**Arquivos criados:**
- `db/migrate/20260312030000_create_users.rb`
- `app/models/user.rb`
- `app/controllers/api/v1/auth_controller.rb`
- `app/services/auth/register_user_service.rb`
- `app/services/auth/login_user_service.rb`
- `app/serializers/user_serializer.rb`
- `spec/models/user_spec.rb` (18 examples)
- `spec/services/auth/register_user_service_spec.rb` (12 examples)
- `spec/services/auth/login_user_service_spec.rb` (10 examples)
- `spec/requests/api/v1/auth_spec.rb` (8 examples — rswag)
- `spec/swagger_helper.rb`
- `swagger/v1/swagger.yaml`

**Suite:** 70 examples, 0 failures

---

### [2026-03-12] Integração com API da Loteria Federal

**Implementado:** Modelos, cliente HTTP, services e jobs para consumir resultados da API externa.

**Decisões:**
- `LotteryApi::Client` usa `Net::HTTP` stdlib — sem gem extra (Faraday/HTTParty)
- Auth via header `APIKEY` (Bearer token da API externa)
- Resultado da API em português (`posicao`, `valor`, `grupo_valor`, `grupo_nome`) → normalizado para inglês ao persistir em `Draw#prizes` (jsonb)
- `Draw#prize_for(position)` → helper para buscar valor por posição
- `LotterySchedule#draw_time_passed_today?` → usado pelo job periódico para decidir se busca resultado
- `CheckPendingDrawsJob` como recurring task no `config/queue.yml` (a cada 5 minutos)
- Todos os services são idempotentes (upsert via `find_or_initialize_by`)
- `FetchDrawsService` aceita `date` como `Date` ou `String`

**Arquivos criados:**
- `config/initializers/lottery_api.rb` — módulo com `base_url` e `api_key` via ENV
- `app/services/lottery_api/client.rb` — cliente HTTP (lotteries, lottery_schedules, draws)
- `db/migrate/20260312031000_create_lotteries.rb`
- `db/migrate/20260312032000_create_lottery_schedules.rb`
- `db/migrate/20260312033000_create_draws.rb`
- `app/models/lottery.rb`
- `app/models/lottery_schedule.rb`
- `app/models/draw.rb`
- `app/services/lottery_api/sync_lotteries_service.rb`
- `app/services/lottery_api/fetch_draws_service.rb`
- `app/jobs/sync_lotteries_job.rb`
- `app/jobs/fetch_draws_job.rb`
- `app/jobs/check_pending_draws_job.rb`
- `spec/factories/lotteries.rb`, `spec/factories/lottery_schedules.rb`, `spec/factories/draws.rb`
- `spec/services/lottery_api/client_spec.rb` (13 examples — WebMock)
- `spec/services/lottery_api/sync_lotteries_service_spec.rb` (9 examples)
- `spec/services/lottery_api/fetch_draws_service_spec.rb` (9 examples)
- `spec/models/lottery_spec.rb`, `spec/models/lottery_schedule_spec.rb`, `spec/models/draw_spec.rb`
- `spec/jobs/check_pending_draws_job_spec.rb` (5 examples)

**Suite:** 123 examples, 0 failures

---

### [2026-03-12] Super Admin — Gerenciar Organizations

**Implementado:** CRUD de organizations via namespace `super_admin` + login cross-tenant para super_admin.

**Decisões:**
- `organization_id` nullable na tabela `users` — super_admin não pertence a nenhuma organização
- `belongs_to :organization, optional: true` — super_admin tem `organization_id: nil`
- Login sem `X-Organization-Id`: `LoginUserService` com `organization: nil` busca `User.super_admin.kept` globalmente
- JWT para super_admin: `{ user_id:, organization_id: nil }` — ApplicationController valida `super_admin?` quando org nil
- `AuthController#register` ainda exige org (novo `require_organization!` before_action)
- Endpoints `GET/POST /api/v1/super_admin/organizations` e `GET/PATCH/DELETE /api/v1/super_admin/organizations/:id`
- Todos os endpoints requerem `role: super_admin` (sem `X-Organization-Id`)
- `Organization.kept` nas queries do super_admin (respeita soft delete)

**Endpoints:**
```
GET    /api/v1/super_admin/organizations       # listar (paginado)
POST   /api/v1/super_admin/organizations       # criar
GET    /api/v1/super_admin/organizations/:id   # detalhe
PATCH  /api/v1/super_admin/organizations/:id   # atualizar
DELETE /api/v1/super_admin/organizations/:id   # soft delete
```

**Arquivos criados:**
- `db/migrate/20260312040000_allow_null_organization_for_super_admin.rb`
- `app/controllers/api/v1/super_admin/organizations_controller.rb`
- `app/services/super_admin/create_organization_service.rb`
- `app/serializers/organization_serializer.rb`
- `spec/requests/api/v1/super_admin/organizations_spec.rb` (22 examples)
- `spec/services/super_admin/create_organization_service_spec.rb` (7 examples)

**Arquivos modificados:**
- `app/models/user.rb` — `belongs_to :organization, optional: true`
- `app/controllers/application_controller.rb` — suporte a JWT com `organization_id: nil`
- `app/controllers/api/v1/auth_controller.rb` — login sem org + `require_organization!` para register
- `app/services/auth/login_user_service.rb` — organization opcional
- `config/routes.rb` — namespace `super_admin`
- `spec/factories/users.rb` — trait `super_admin` com `organization: nil`
- `spec/models/user_spec.rb` — association agora `optional`
- `spec/requests/api/v1/auth_spec.rb` — testes de login super_admin sem org

**Suite:** 157 examples, 0 failures | Coverage: 94.94%

---

### [2026-03-12] Raffle — CRUD completo

**Implementado:** Entidade central do negócio — Raffle, RafflePrize (aninhados), Ticket (stub), CRUD de rifas para admin com transições de status.

**Decisões:**
- `module Raffle` em `config/application.rb` renomeado para `module RaffleApp` — conflito de nome com o model `Raffle`
- `draw_mode` imutável após sair do draft — validado no model (`on: :update`) e filtrado no service antes de chegar ao model
- `UpdateRaffleService` bloqueia update em status `closed`, `drawn`, `cancelled` — `draft` e `open` permitidos
- `TransitionRaffleService` usa `ALLOWED_TRANSITIONS` hash para validar transições — idempotente e simples
- `accepts_nested_attributes_for :raffle_prizes, allow_destroy: true` — prizes gerenciados via nested attrs
- Ticket model apenas como stub (migration + model + factory) — sem CRUD nesta iteração
- Association cache do AR: ao fazer `raffle.reload` antes de passar para o service em specs de _destroy — evita falso RecordNotFound causado por cache vazio do has_many
- Admin e super_admin veem todos os status; participant vê apenas `for_participants` (kept.open) no index
- Soft delete: `DELETE` só permitido em riffas `draft`; transições de status via `POST /open` e `POST /close`

**Endpoints:**
```
GET    /api/v1/raffles              # admin: todos kept; participant: só open
POST   /api/v1/raffles              # admin only → CreateRaffleService
GET    /api/v1/raffles/:id          # qualquer autenticado, scoped to org
PATCH  /api/v1/raffles/:id          # admin only → UpdateRaffleService
DELETE /api/v1/raffles/:id          # admin only, somente draft → discard
POST   /api/v1/raffles/:id/open     # admin only → TransitionRaffleService(:open)
POST   /api/v1/raffles/:id/close    # admin only → TransitionRaffleService(:closed)
```

**Arquivos criados:**
- `db/migrate/20260312050000_create_raffles.rb`
- `db/migrate/20260312051000_create_raffle_prizes.rb`
- `db/migrate/20260312052000_create_tickets.rb`
- `app/models/raffle.rb`, `app/models/raffle_prize.rb`, `app/models/ticket.rb`
- `app/services/raffles/create_raffle_service.rb`
- `app/services/raffles/update_raffle_service.rb`
- `app/services/raffles/transition_raffle_service.rb`
- `app/controllers/api/v1/raffles_controller.rb`
- `app/serializers/raffle_serializer.rb`
- `spec/models/raffle_spec.rb` (37 examples), `spec/models/raffle_prize_spec.rb` (10 examples)
- `spec/services/raffles/create_raffle_service_spec.rb` (9 examples)
- `spec/services/raffles/update_raffle_service_spec.rb` (12 examples)
- `spec/services/raffles/transition_raffle_service_spec.rb` (15 examples)
- `spec/requests/api/v1/raffles_spec.rb` (30 examples — rswag)
- `spec/factories/raffles.rb`, `spec/factories/raffle_prizes.rb`, `spec/factories/tickets.rb`

**Arquivos modificados:**
- `config/application.rb` — `module Raffle` → `module RaffleApp` (conflito com model)
- `config/routes.rb` — `resources :raffles` com member actions `open` e `close`
- `spec/models/organization_spec.rb` — removido `xit` de `have_many(:raffles)`

**Suite:** 270 examples, 0 failures | Coverage: 96.31%

---

### [2026-03-11] Início do Projeto

**Decisão:** Usar Rails 8 API mode com PostgreSQL e adapters Solid para eliminar dependência de Redis/Sidekiq.

**Motivação:** Simplicidade operacional — menos serviços para manter em produção. O PostgreSQL já é necessário para o banco de dados principal, então reutilizá-lo para filas, cache e cable reduz a complexidade da infraestrutura.

**Próximos passos:**

### Infraestrutura e Setup ✅
1. [x] Rails 8 API mode + PostgreSQL (Docker)
2. [x] Solid Queue, Solid Cache, Solid Cable (sem Redis)
3. [x] RSpec, FactoryBot, Faker, WebMock, SimpleCov, rswag
4. [x] ApplicationController — JWT, multi-tenancy, paginação, Rack::Attack, CORS

### Autenticação e Organizations ✅
5. [x] Organization model — multi-tenancy root, slug, soft delete, logo
6. [x] Auth JWT — register + login (stateless, X-Organization-Id header)
7. [x] Super Admin — CRUD de organizations (cross-tenant, Motor Admin)

### Loteria Federal ✅
8. [x] LotteryApi::Client (Net::HTTP, sem gem extra)
9. [x] Sync de Lotteries e Schedules (SyncLotteriesJob)
10. [x] Fetch de Draws com resultado normalizado (CheckPendingDrawsJob — recurring 5 min)

### Rifas ✅
11. [x] Raffle CRUD (admin) — draft/open/closed/drawn/cancelled, prizes aninhados
12. [x] Ticket model stub — migration com UNIQUE (raffle_id, number), enum status

### Tickets — próximo
13. [ ] Reserva de bilhetes — POST /raffles/:id/tickets (participant)
        - Gerar número disponível dentro do draw_mode (centena/milhar/dezena_de_milhar)
        - reserved_until = 30 min; race condition via rescue RecordNotUnique
        - GET /raffles/:id/tickets (admin lista todos); GET /tickets/mine (participant)
14. [ ] Pagamento — dois fluxos:
        a. Gateway: POST /webhooks/payment → confirmar ticket automaticamente
        b. Manual: POST /tickets/:id/confirm_payment (admin only)
15. [ ] Expiração de reservas — ExpireTicketsJob (recurring, marca expired quando reserved_until < now)

### Sorteio e Notificações — depois
16. [ ] Draw — apuração de ganhadores
        - Vincular Draw da Loteria Federal à Raffle (closed → drawn)
        - Para cada RafflePrize: extrair dígitos do resultado conforme draw_mode → achar ticket vencedor
        - Criar DrawResult associando RafflePrize ao Ticket vencedor
17. [ ] Notificações WhatsApp — Meta Cloud API
        - Job assíncrono disparado após apuração do Draw
        - Envia mensagem ao participante vencedor com detalhes do prêmio
18. [ ] Endpoints de participant — histórico e perfil
        - GET /tickets/mine — todos os tickets do usuário com status
        - Filtros: rifa, status (reservado/pago/expirado)

## Skills Customizadas (Slash Commands)

| Comando | Quando usar |
|---|---|
| `/feature` | Ciclo completo TDD para nova feature: planejar → spec → implementar → lint → swagger → coverage → log |
| `/model` | Criar model com migration, factory e spec completo |
| `/spec` | Gerar e executar specs para um componente específico |
| `/lint` | Rodar RuboCop + Brakeman e corrigir issues |
| `/swagger` | Atualizar documentação Swagger a partir dos specs rswag |
| `/coverage` | Rodar suite completa com SimpleCov e reportar cobertura |

**Regra:** Toda implementação de endpoint começa com `/feature`. Use `/model`, `/spec`, `/lint` e `/swagger` individualmente quando precisar rodar uma etapa isolada.

## Comandos Úteis

```bash
# Criar projeto (quando executado)
rails new raffle --api --database=postgresql --skip-action-mailer --skip-action-text --skip-active-storage

# Rodar servidor
rails server

# Rodar jobs (Solid Queue)
bin/jobs
```

## Decisões de Design

| Decisão | Escolha | Data |
|---|---|---|
| Stack principal | Rails 8 API + PostgreSQL | 2026-03-11 |
| Jobs/Queue | Solid Queue (sem Redis) | 2026-03-11 |
| Cache | Solid Cache (sem Redis) | 2026-03-11 |
| Action Cable | Solid Cable (sem Redis) | 2026-03-11 |
| Loteria Federal | API externa já disponível | 2026-03-11 |
| Paginação | Manual (sem pagy — incompatível Ruby 4.0) | 2026-03-11 |
| Docker | PostgreSQL via docker-compose | 2026-03-11 |
| Organization slug | Normalizado (downcase+strip) antes da validação — aceita maiúsculas na entrada | 2026-03-12 |
| Faker::Internet.slug | Gera slugs com underscore — usar `"#{Faker::Lorem.word}-#{Faker::Lorem.word}"` em factories | 2026-03-12 |
| trait FactoryBot | Ruby 4.0: `trait :name { }` é syntax error — usar `trait(:name) { }` | 2026-03-12 |
| Auth — super_admin | Criado via Motor Admin (console do admin panel), não via endpoint público | 2026-03-11 |
| Super admin — org_id | `organization_id: nil` em users — super_admin é cross-tenant, não pertence a nenhuma org | 2026-03-12 |
| Super admin — login | Login sem `X-Organization-Id` header — `LoginUserService` busca globalmente `User.super_admin` | 2026-03-12 |
| Super admin — JWT | JWT com `organization_id: nil` — ApplicationController valida `super_admin?` quando org ausente | 2026-03-12 |
| Auth — email único por org | Email único por organização (índice composto org+email), não globalmente | 2026-03-11 |
| Auth — organização no header | Frontend envia `X-Organization-Id` (controlado pelo hostname) — sem precisar no body | 2026-03-11 |
| Auth — JWT payload | `{ user_id:, organization_id: }` — ApplicationController resolve ambos do token | 2026-03-11 |
| Faker::Name.full_name | Não existe nesta versão do Faker — usar `"#{Faker::Name.first_name} #{Faker::Name.last_name}"` | 2026-03-11 |
| App module name | `config/application.rb` usa `module RaffleApp` (não `module Raffle`) — conflito com model `Raffle` | 2026-03-12 |
| Raffle draw_mode | Imutável após sair do draft — validado no model e filtrado no service antes do update | 2026-03-12 |
| Raffle transitions | `ALLOWED_TRANSITIONS` hash no model — service consulta `may_transition_to?` antes de update | 2026-03-12 |
| Nested attrs AR cache | `raffle.reload` em specs de `_destroy` — evita RecordNotFound por cache stale do has_many | 2026-03-12 |
| Swagger (rswag) | Usar `RAILS_ENV=test bundle exec rake rswag:specs:swaggerize` — rake task só disponível em test env | 2026-03-11 |

## Notificações WhatsApp

- Disparadas automaticamente quando um sorteio é apurado
- Participante vencedor recebe mensagem com detalhes do prêmio
- Número de WhatsApp coletado no cadastro do participante
- Provider: **Meta Cloud API** (oficial) ou outro serviço de terceiros — volume pequeno, custo não é preocupação
- Envio via Solid Queue job (assíncrono, não bloqueia o fluxo de apuração)

## Pendências / Questões Abertas

- [x] Critério de correspondência: modalidades de 100, 1.000 ou 10.000 bilhetes baseadas nos dígitos do resultado
- [x] Notificações: WhatsApp automático ao apurar ganhadores
- [x] Provider WhatsApp: Meta Cloud API ou terceiros — volume pequeno, sem preocupação com custo
- [ ] Qual prêmio da Loteria Federal usar por padrão (1º prêmio)? Configurável por rifa?
- [x] Super_admin: `organization_id` nullable, login sem `X-Organization-Id`, ApplicationController trata org nil para super_admin.
- [x] Reserva de números: timed reservation (30 min) com UNIQUE constraint no banco + job de expiração
- [x] Múltiplos ganhadores: até 5 prêmios por sorteio, cada um vinculado a um prêmio diferente da Loteria Federal
- [x] Pagamento: modelo misto — gateway automático + confirmação manual por admin
- [x] Autenticação: JWT stateless
- [x] Multi-tenancy: Organization-scoped com roles (super_admin, admin, participant)
