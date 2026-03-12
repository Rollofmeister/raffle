# /review — Revisão de boas práticas do projeto

Audita o código do projeto verificando conformidade com as decisões de design e padrões definidos no CLAUDE.md.

**Argumento:** $ARGUMENTS (opcional — escopo da revisão, ex: "app/controllers" ou "feature tickets". Sem argumento revisa o projeto inteiro.)

## Objetivo

Verificar se o código implementado segue as decisões de design, padrões de qualidade e convenções definidas para o projeto Raffle. Não é um lint de estilo — é uma revisão de conformidade arquitetural e de domínio.

---

## Checklist de revisão

Execute cada verificação abaixo. Para cada item, reporte: ✅ OK, ⚠️ Atenção ou ❌ Violação.

---

### 1. MULTI-TENANCY — Isolamento por organização

Verifique em controllers e services:

- Toda query usa `.where(organization: current_organization)` ou escopo equivalente
- Nenhum `find(id)` sem escopo — sempre `current_organization.records.find(id)`
- Nenhum endpoint retorna dados cross-tenant
- Specs incluem casos de isolamento (org A não acessa dados de org B)

```bash
# Buscar find sem escopo de tenant
grep -rn "\.find(" app/controllers/ app/services/ --include="*.rb"
grep -rn "\.find_by(" app/controllers/ app/services/ --include="*.rb"
```

Analise cada ocorrência e confirme que está escopada por `current_organization` ou equivalente.

---

### 2. CONTROLLERS — Thin controllers

Verifique em `app/controllers/api/v1/`:

- Controllers não contêm lógica de negócio — apenas: autenticar, autorizar, chamar service, serializar, responder
- Regras de negócio estão em `app/services/`
- Nenhum `before_action` com lógica de negócio complexa

```bash
# Verificar tamanho dos controllers (controllers magros têm < ~50 linhas)
wc -l app/controllers/api/v1/*.rb
```

---

### 3. AUTENTICAÇÃO E AUTORIZAÇÃO JWT

Verifique:

- `ApplicationController` extrai `user_id` e `organization_id` do JWT
- Nenhum endpoint público que deveria ser protegido está desprotegido
- Role-based access: admin não acessa recursos de super_admin e vice-versa
- Header `X-Organization-Id` é respeitado corretamente
- Login rejeita usuários com soft delete

```bash
grep -rn "skip_before_action\|before_action :authenticate" app/controllers/ --include="*.rb"
```

---

### 4. SOLID-FIRST — Sem Redis/Sidekiq

Verifique no Gemfile e código:

- Nenhuma gem `redis`, `sidekiq`, `hiredis`, `redis-actionpack` no Gemfile
- Jobs herdam de `ApplicationJob` (Solid Queue)
- Cache usa `Rails.cache` (Solid Cache) — sem `Redis.new` no código
- Action Cable configurado com Solid Cable

```bash
grep -n "redis\|sidekiq" Gemfile
grep -rn "Redis\.new\|Sidekiq" app/ --include="*.rb"
```

---

### 5. JOBS — Solid Queue

Verifique em `app/jobs/`:

- Jobs herdam de `ApplicationJob`
- Jobs são idempotentes (podem ser re-executados sem efeitos colaterais)
- Recurring jobs configurados em `config/queue.yml`
- Jobs complexos delegam para services

```bash
grep -rn "class.*Job" app/jobs/ --include="*.rb"
cat config/queue.yml
```

---

### 6. UNICIDADE DE BILHETES — UNIQUE constraint no banco

Verifique:

- Migration de `tickets` tem `unique index on (raffle_id, number)`
- Aplicação usa `rescue ActiveRecord::RecordNotUnique` — não valida unicidade só no Rails
- `reserved_until` é definido no momento da reserva

```bash
grep -rn "unique\|index.*raffle_id.*number" db/schema.rb db/migrate/ --include="*.rb"
```

---

### 7. MODELOS E FACTORIES

Verifique:

- Specs usam factories (FactoryBot) — nunca fixtures
- Factories não usam `Faker::Name.full_name` (não existe nesta versão) — usar `"#{Faker::Name.first_name} #{Faker::Name.last_name}"`
- Factories não usam `Faker::Internet.slug` (gera underscores) — usar `"#{Faker::Lorem.word}-#{Faker::Lorem.word}"`
- Traits de factory usam sintaxe `trait(:name) { }` (Ruby 4.0 — `trait :name { }` é syntax error)
- Organization slug é normalizado (downcase + strip) antes da validação

```bash
grep -rn "Faker::Name.full_name\|Faker::Internet.slug\|trait :" spec/factories/ --include="*.rb"
```

---

### 8. SERIALIZERS — Sem IDs internos

Verifique em `app/serializers/`:

- Respostas JSON não expõem `id` numérico interno — usar UUID ou token público
- Serializers usam apenas atributos públicos seguros

```bash
grep -rn '"id":\|:id,' app/serializers/ --include="*.rb"
```

---

### 9. TESTES — Cobertura e qualidade

Verifique:

- Cada model tem `spec/models/`
- Cada service tem `spec/services/`
- Cada endpoint tem `spec/requests/api/v1/` no formato rswag
- Specs de request incluem casos de: sucesso, erro de validação, não autorizado (401), proibido (403), não encontrado (404)
- Specs de isolamento de tenant existem

```bash
bundle exec rspec --dry-run 2>&1 | tail -5
```

Execute a suite e verifique se há falhas:

```bash
bundle exec rspec
```

---

### 10. SWAGGER — Documentação atualizada

Verifique:

- `swagger/v1/swagger.yaml` existe e está atualizado
- Todos os endpoints implementados estão documentados
- Regenere e confirme que não há diff inesperado:

```bash
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
```

---

### 11. LOTERIA FEDERAL — Integração

Verifique:

- `LotteryApi::Client` usa `Net::HTTP` stdlib (sem Faraday/HTTParty)
- Auth via header `APIKEY` (Bearer token)
- Resultados normalizados de português para inglês ao persistir
- Services são idempotentes (`find_or_initialize_by`)
- `CheckPendingDrawsJob` configurado como recurring task

```bash
grep -rn "require.*faraday\|require.*httparty\|gem.*faraday" Gemfile app/ --include="*.rb"
```

---

### 12. CLAUDE.md — Documentação atualizada

Verifique:

- Toda feature implementada está registrada na seção "Passos e Decisões — Log"
- Decisões de design relevantes estão documentadas
- Próximos passos estão atualizados (itens concluídos marcados com [x])

Leia o CLAUDE.md e compare com o código existente em `app/`.

---

## Relatório final

Ao concluir todas as verificações, gere um relatório estruturado:

```
## Relatório de Revisão — [data]
Escopo: [arquivos/feature auditados]

### Resumo
- ✅ Conformes: N
- ⚠️  Atenção: N
- ❌ Violações: N

### Detalhes

#### ✅ OK
- [item]: [breve descrição]

#### ⚠️ Atenção
- [item]: [o que foi encontrado e por que merece atenção]

#### ❌ Violações
- [item]: [o que foi encontrado, arquivo:linha, e como corrigir]

### Próximos passos recomendados
[Liste as correções prioritárias]
```

Se houver violações críticas (multi-tenancy, segurança, testes faltando), ofereça corrigir imediatamente.
