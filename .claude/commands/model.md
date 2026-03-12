# /model — Criar model com spec completo

Cria um novo model Rails seguindo o padrão do projeto, com migration, spec e factory.

**Argumento:** $ARGUMENTS (ex: "Raffle organization:references title:string modal:integer status:integer")

## Passos

### 1. Planejar
Antes de criar:
- O model pertence a uma Organization? Se sim, incluir `organization:references`
- Quais atributos precisam de índice de banco?
- Há UNIQUE constraints necessárias? (ex: raffle_id + number em Ticket)
- Quais atributos são enums?

### 2. Gerar migration e model
```bash
bundle exec rails generate model $ARGUMENTS
```

### 3. Ajustar a migration
Edite o arquivo de migration para adicionar:
- `null: false` nos campos obrigatórios
- `default:` nos campos com valor padrão
- Índices necessários (`add_index`)
- UNIQUE constraints quando aplicável

### 4. Criar factory
Em `spec/factories/`, crie a factory com FactoryBot:
- Use `Faker` para dados realistas
- Crie traits para os estados mais comuns (ex: `trait :paid`, `trait :expired`)
- Garanta que a factory é válida por padrão

### 5. Escrever spec do model
Em `spec/models/`:
- Validações com shoulda-matchers
- Associations
- Enums
- Scopes
- Métodos de instância relevantes
- Callbacks importantes

### 6. Rodar migration e specs
```bash
bundle exec rails db:migrate
bundle exec rails db:migrate RAILS_ENV=test
bundle exec rspec spec/models/[nome]_spec.rb --format documentation
```

### 7. Lint
```bash
bundle exec rubocop app/models/[nome].rb spec/models/[nome]_spec.rb spec/factories/[nome]s.rb --autocorrect
```

### 8. Atualizar CLAUDE.md
Registre o model criado no log de decisões.
