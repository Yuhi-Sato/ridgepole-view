# ridgepole-view

[Ridgepole](https://github.com/ridgepole/ridgepole) plugin that adds database view management using [Scenic](https://github.com/scenic-views/scenic).

## Overview

Ridgepole manages database schema declaratively via a Schemafile, but does not support database views. This plugin bridges Ridgepole and Scenic, enabling you to define views in your Schemafile and manage them with the same `ridgepole --apply` workflow.

## Installation

Add to your Gemfile:

```ruby
gem "ridgepole-view", require: "ridgepole-view"
```

Or use Ridgepole's `-r` flag:

```bash
ridgepole -r ridgepole-view -a -c config.yml -f Schemafile
```

## Requirements

- Ruby >= 2.7
- Ridgepole >= 1.0
- Scenic >= 1.5
- PostgreSQL

## Usage

### Defining views in Schemafile

```ruby
create_table "users", force: :cascade do |t|
  t.column "name", :string
  t.column "email", :string
  t.column "active", :boolean, default: true
end

create_view "active_users", sql_definition: <<-SQL
  SELECT users.name, users.email
  FROM users
  WHERE users.active = true
SQL
```

### Materialized views

```ruby
create_view "user_stats", materialized: true, sql_definition: <<-SQL
  SELECT count(*) AS total_users,
         count(*) FILTER (WHERE active) AS active_users
  FROM users
SQL
```

### Apply changes

```bash
# Apply schema (including views)
ridgepole -r ridgepole-view -a -c config.yml -f Schemafile

# Dry run
ridgepole -r ridgepole-view -a --dry-run -c config.yml -f Schemafile

# Export current schema (including views)
ridgepole -r ridgepole-view -e -c config.yml -o Schemafile
```

## How it works

The plugin extends Ridgepole's core components via `prepend`:

| Component | Extension |
|-----------|-----------|
| `DSLParser::Context` | Adds `create_view` DSL method |
| `DSLParser` | Excludes `:views` from table validation |
| `Dumper` | Appends existing views to schema dump via `Scenic.database.views` |
| `Diff` | Detects view additions, changes, and deletions |
| `Delta` | Generates `create_view` / `drop_view` migration scripts |

View changes are applied through Scenic's `Statements` module (`create_view`, `drop_view`), which delegates to `Scenic.database` (PostgreSQL adapter).

### Diff behavior

- **Added view**: `create_view` is generated
- **Removed view**: `drop_view` is generated
- **Changed view** (SQL or materialized flag): `drop_view` (old) then `create_view` (new)
- **Unchanged view**: No action
- SQL comparison normalizes whitespace and case

## Development

```bash
bundle install
bundle exec rspec
```

## Known limitations

- Views referencing other views are not topologically sorted. Define them in dependency order in the Schemafile.
- SQL normalization downcases the entire definition, including string literals.
- `--merge` mode (add-only) does not prevent view deletion. Views follow the same diff logic regardless.

## License

MIT
