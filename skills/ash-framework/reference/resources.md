# Resources Reference

**Deep dive into Ash Resource patterns and design**

Resources are the foundation of Ash Framework - declarative domain models that
define the structure and behavior of your application's data.

## Table of Contents

- [What are Resources?](#what-are-resources)
- [Resource Structure](#resource-structure)
- [Attributes and Types](#attributes-and-types)
- [Relationships](#relationships)
- [Actions](#actions)
- [Embedded Resources](#embedded-resources)
- [Best Practices](#best-practices)
- [Related Resources](#related-resources)

## What are Resources?

Resources represent domain entities with complete behavior definitions:

- **Attributes**: Data fields with types and constraints
- **Relationships**: Connections to other resources
- **Actions**: Operations (CRUD + custom) with validations
- **Policies**: Authorization rules
- **Calculations**: Derived values
- **Aggregates**: Summaries from related data

### Resource-Oriented Design

The core principle: **Model your domain declaratively, derive the rest**.

Resources define the structure, Ash provides:

- Database persistence (via AshPostgres)
- JSON APIs (via AshJsonApi)
- GraphQL APIs (via AshGraphql)
- Authorization enforcement (via policies)
- Validation and error handling

**See**:
[DESIGN/concepts/resources.md](../../../../DESIGN/concepts/resources.md) for
architecture

## Resource Structure

### Basic Resource

```elixir
defmodule MyApp.BasicResource do
  use Ash.Resource,
    domain: MyApp.MyDomain,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "basic_resources"
    repo MyApp.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    timestamps()
  end

  actions do
    defaults [:read]
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end
  end
end
```

**Components**:

- `use Ash.Resource` - Declares resource with domain and data layer
- `postgres` - Database configuration
- `attributes` - Data fields
- `actions` - Available operations
- `policies` - Authorization rules

**See**: [examples/resources.ex](../examples/resources.ex#L18-L44) for basic
resource example

### Multi-Tenant Resource

```elixir
defmodule MyApp.Item do
  use Ash.Resource,
    domain: MyApp.MyDomain,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "items"
    repo MyApp.Repo

    references do
      reference :organization, on_delete: :delete
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :status, :atom, default: :active
    timestamps()
  end

  relationships do
    belongs_to :organization, MyApp.Organization do
      allow_nil?: false
      attribute_writable? true
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if expr(organization_id == ^actor(:organization_id))
    end
  end

  identities do
    identity :unique_name_per_org, [:name, :organization_id]
  end
end
```

**Multi-tenant features**:

- `belongs_to :organization` - Organization relationship
- `on_delete: :delete` - Cascade deletion
- Organization-scoped policies
- Composite uniqueness (name + organization_id)

**See**:

- [examples/resources.ex](../examples/resources.ex#L61-L136) for multi-tenant
  example
- [DESIGN/concepts/resources.md](../../../../DESIGN/concepts/resources.md#multi-tenancy-by-design)
  for multi-tenancy architecture

## Attributes and Types

### Common Attribute Types

```elixir
attributes do
  uuid_primary_key :id

  # Text types
  attribute :name, :string, allow_nil?: false
  attribute :email, :ci_string  # Case-insensitive
  attribute :description, :string

  # Numeric types
  attribute :count, :integer
  attribute :price, :decimal
  attribute :rating, :float

  # Boolean
  attribute :active, :boolean, default: false

  # Date/Time
  attribute :created_at, :utc_datetime
  attribute :published_on, :date

  # Structured
  attribute :metadata, :map, default: %{}
  attribute :tags, {:array, :string}, default: []

  # Enum
  attribute :status, :atom do
    constraints one_of: [:draft, :published, :archived]
    default :draft
  end

  timestamps()  # Adds inserted_at and updated_at
end
```

**See**: [examples/resources.ex](../examples/resources.ex) throughout for
attribute examples

### Attribute Options

- `allow_nil?` - Can field be nil?
- `default` - Default value
- `public?` - Exposed in public API
- `sensitive?` - Hidden in logs (passwords, etc.)
- `constraints` - Validation constraints

## Relationships

### Relationship Types

```elixir
relationships do
  # Parent reference (foreign key in this table)
  belongs_to :organization, MyApp.Organization do
    allow_nil?: false
    attribute_writable? true
  end

  # Children reference (foreign key in their table)
  has_many :items, MyApp.Item do
    destination_attribute :parent_id
  end

  # One-to-one
  has_one :active_version, MyApp.Version

  # Many-to-many (through join table)
  many_to_many :tags, MyApp.Tag do
    through MyApp.ItemTag
    source_attribute_on_join_resource :item_id
    destination_attribute_on_join_resource :tag_id
  end
end
```

**See**: [examples/resources.ex](../examples/resources.ex#L110-L130) for
relationship examples

### Relationship Configuration

```elixir
postgres do
  references do
    reference :organization, on_delete: :delete      # Cascade delete
    reference :parent, on_delete: :nilify           # Set to null
    reference :user, on_delete: :restrict           # Prevent delete
  end
end
```

## Actions

### Default Actions

```elixir
actions do
  defaults [:read, :create, :update, :destroy]
end
```

Provides standard CRUD with minimal configuration.

### Custom Actions

```elixir
actions do
  # Custom create with specific logic
  create :invite do
    description "Invite a new user (admin only)"
    accept [:email, :name, :organization_id]
    argument :role, :atom, allow_nil?: false

    validate present(:email)
    validate match(:email, ~r/@/)

    change after_action(fn changeset, user, context ->
      send_invitation_email(user)
      {:ok, user}
    end)
  end

  # Custom update
  update :update_last_seen do
    accept []
    change set_attribute(:last_seen_at, &DateTime.utc_now/0)
  end

  # Generic action returning custom data
  action :get_statistics, :map do
    argument :user_id, :uuid, allow_nil?: false

    run fn input, context ->
      {:ok, %{total_logins: 42, last_login: DateTime.utc_now()}}
    end
  end
end
```

**See**: [examples/resources.ex](../examples/resources.ex#L153-L211) for custom
action examples

### Validations

```elixir
create :create do
  accept [:name, :email]

  # Built-in validations
  validate present(:name)
  validate present(:email)

  # Regex validation
  validate match(:email, ~r/@/) do
    message "must be a valid email"
  end

  # Custom validation function
  validate fn changeset, _context ->
    name = Ash.Changeset.get_attribute(changeset, :name)

    if String.length(name) < 3 do
      {:error, field: :name, message: "must be at least 3 characters"}
    else
      :ok
    end
  end
end
```

**See**:

- [examples/resources.ex](../examples/resources.ex#L228-L261) for validation
  examples
- [examples/changesets.ex](../examples/changesets.ex) for changeset patterns

### Changes

Changes transform data during action processing:

```elixir
create :create do
  change fn changeset, context ->
    actor = Map.get(context, :actor)

    changeset
    |> Ash.Changeset.change_attribute(:created_by_id, actor.id)
    |> Ash.Changeset.change_attribute(:status, :active)
  end

  change after_action(fn changeset, resource, context ->
    # Create audit log after resource created
    create_audit_log(resource, context)
    {:ok, resource}
  end)
end
```

**See**: [examples/resources.ex](../examples/resources.ex#L278-L320) for change
examples

## Embedded Resources

Embedded resources are stored as JSON in parent resource:

```elixir
# Embedded resource definition
defmodule MyApp.Metadata do
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :type, :atom, allow_nil?: false
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end
end

# Parent resource
defmodule MyApp.Item do
  attributes do
    uuid_primary_key :id
    attribute :metadata, {:array, MyApp.Metadata}, default: []
  end
end
```

**CRITICAL**: Always validate embedded data before creating struct:

```elixir
change fn changeset, context ->
  metadata_data = Ash.Changeset.get_argument(changeset, :metadata)

  # ✅ CORRECT: Validate before struct creation
  case MyApp.Metadata
       |> Ash.Changeset.for_create(:create, metadata_data) do
    %{valid?: true} ->
      # Safe to create struct
      metadata = struct(MyApp.Metadata, metadata_data)
      metadata_list = [metadata | changeset.data.metadata]
      Ash.Changeset.change_attribute(changeset, :metadata, metadata_list)

    %{valid?: false} = metadata_changeset ->
      # Add validation errors
      Enum.reduce(metadata_changeset.errors, changeset, fn error, acc ->
        Ash.Changeset.add_error(acc, error)
      end)
  end
end
```

**See**: [examples/resources.ex](../examples/resources.ex#L337-L390) for
embedded resource patterns

## Best Practices

### Pattern #1: UUID Identity vs Name Description

✅ Use UUIDs as immutable identifiers:

- Primary keys are UUIDs
- Foreign keys use UUIDs
- Tool parameters use UUIDs

✅ Names are descriptive, mutable labels:

- Can be duplicated (no unique constraint on name alone)
- User-friendly
- Can be changed without breaking references

```elixir
identities do
  # ✅ Unique within organization (UUID + name)
  identity :unique_name_per_org, [:name, :organization_id]
end
```

**See**: [examples/resources.ex](../examples/resources.ex#L556-L576) for
identity patterns

### Pattern #2: Immutability for Core Data

✅ Core data can be immutable (versioned):

- Version records are never updated
- Edits create new versions
- Sessions lock to specific versions

✅ Draft resources are temporary workspaces:

- Mutable until saved
- Publishing creates immutable version

**See**: [examples/resources.ex](../examples/resources.ex#L578-L594) for
immutability pattern

### Pattern #3: Context Setting

✅ CRITICAL: Set context during changeset creation:

```elixir
# ✅ CORRECT
Resource
|> Ash.Changeset.for_create(
  :create,
  attrs,
  actor: actor,
  context: %{skip_validation: true}  # Set here
)
|> Ash.create()

# ❌ WRONG - May be lost
Resource
|> Ash.Changeset.for_create(:create, attrs, actor: actor)
|> Ash.Changeset.set_context(%{skip_validation: true})  # Too late
|> Ash.create()
```

**See**: [examples/resources.ex](../examples/resources.ex#L596-L621) for context
patterns

### Pattern #4: Relationship Configuration

```elixir
relationships do
  belongs_to :organization, MyApp.Organization do
    allow_nil?: false           # Required
    attribute_writable? true    # Can set via attributes
  end
end

postgres do
  references do
    reference :organization, on_delete: :delete  # Cascade
  end
end
```

**See**: [examples/resources.ex](../examples/resources.ex#L623-L643) for
relationship configuration

### Pattern #5: Action Atomicity

```elixir
action :complex_operation, :map do
  transaction? true  # Ensures atomicity

  run fn input, context ->
    # All operations succeed or all rollback
  end
end

update :update do
  require_atomic? false  # Can't be done in single SQL
end
```

**See**:

- [examples/resources.ex](../examples/resources.ex#L645-L672) for atomicity
  patterns
- [reference/transactions.md](./transactions.md) for transaction details

## Calculations and Aggregates

### Calculations

Derived values computed on read:

```elixir
calculations do
  # Simple expression
  calculate :prompt_count, :integer, expr(count(prompts))

  # Custom function
  calculate :last_activity, :utc_datetime do
    calculation fn records, _context ->
      Enum.map(records, fn chat ->
        last = Enum.max_by(chat.prompts || [], & &1.inserted_at, fn -> nil end)
        {:ok, last && last.inserted_at}
      end)
    end
  end
end
```

**See**: [examples/resources.ex](../examples/resources.ex#L407-L428) for
calculation examples

### Aggregates

Summaries from related data:

```elixir
aggregates do
  # Count related records
  count :user_count, :users

  # Max value
  max :last_user_login, :users, :last_seen_at

  # Collect unique values
  list :user_roles, :users, :role do
    uniq? true
  end

  # Sum numeric values
  sum :total_storage_bytes, :uploads, :size_bytes
end
```

**See**: [examples/resources.ex](../examples/resources.ex#L445-L464) for
aggregate examples

## Identities (Uniqueness)

```elixir
identities do
  # Composite uniqueness within organization
  identity :unique_name_per_org, [:name, :organization_id]

  # Conditional uniqueness (partial index)
  identity :unique_active_per_version, [:version_id] do
    where expr(status == :active)
  end
end

postgres do
  # Map identity to SQL for partial index
  identity_wheres_to_sql unique_active_per_version: "status = 'active'"
end
```

**See**: [examples/resources.ex](../examples/resources.ex#L481-L507) for
identity examples

## Error Handling

Custom error handlers transform database errors:

```elixir
create :create do
  error_handler fn changeset, error ->
    case error do
      %Ecto.ConstraintError{constraint: "unique_constraint_name"} ->
        Ash.Changeset.add_error(
          changeset,
          field: :field_name,
          message: "friendly error message"
        )

      _ ->
        error
    end
  end
end
```

**See**: [examples/resources.ex](../examples/resources.ex#L524-L554) for error
handling

## Related Resources

### Examples

- [examples/resources.ex](../examples/resources.ex) - Complete resource examples
- [examples/changesets.ex](../examples/changesets.ex) - Changeset patterns
- [examples/policies.ex](../examples/policies.ex) - Policies in resources

### Reference Docs

- [reference/actor-context.md](./actor-context.md) - Actor in resource actions
- [reference/policies.md](./policies.md) - Resource authorization
- [reference/transactions.md](./transactions.md) - Resource transactions

### Project Documentation

- {project_root}/DESIGN/concepts/resources.md - Resource architecture
- {project_root}/DESIGN/concepts/actions.md - Action patterns
- {project*root}/lib/my_app/*/resources/\_.ex - Real resource examples

### External Resources

- [Ash Resources](https://hexdocs.pm/ash/resources.html) - Official resource
  documentation
- [Ash Actions](https://hexdocs.pm/ash/actions.html) - Action configuration
- [Ash Postgres](https://hexdocs.pm/ash_postgres/) - PostgreSQL data layer

---

**Next Steps**:

- Study [examples/resources.ex](../examples/resources.ex) for resource patterns
- Read [reference/policies.md](./policies.md) for authorization
- Review
  [DESIGN/concepts/resources.md](../../../../DESIGN/concepts/resources.md) for
  architecture
