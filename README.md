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

### Ridgepole's architecture

Ridgepole applies schema changes through the following pipeline:

```
Schemafile (DSL)
    │
    ▼
DSLParser::Context  ─── Evaluates the Schemafile via instance_eval, converting
    │                    DSL methods (create_table, etc.) into a definition hash
    ▼
DSLParser           ─── Validates the definition hash (checks for orphan
    │                    indexes, foreign keys without tables, etc.)
    ▼
Dumper              ─── Reads the current DB state as a DSL string via
    │                    ActiveRecord::SchemaDumper (also used for export)
    ▼
Diff                ─── Compares the "current state" (from Dumper) with the
    │                    "desired state" (from DSLParser) and detects differences
    ▼
Delta               ─── Generates migration scripts (create_table, drop_table,
                         etc.) from the diff result and executes them
```

### What this plugin extends

This plugin injects view support into each component above via `prepend`:

| Component | Original responsibility | This plugin's extension |
|-----------|----------------------|------------------------|
| `DSLParser::Context` | Provides DSL methods like `create_table` | Adds `create_view` method, stores views under `:views` key |
| `DSLParser` | Validates the definition hash integrity | Excludes `:views` from table validation |
| `Dumper` | Converts current DB state to DSL string | Appends existing views via `Scenic.database.views` |
| `Diff` | Compares two definition hashes to detect changes | Detects view add/change/delete |
| `Delta` | Generates and executes migration scripts from diff | Generates `create_view` / `drop_view` scripts |

View changes are applied through Scenic's `Statements` module (`create_view`, `drop_view`), which delegates to `Scenic.database` (PostgreSQL adapter).

### Why `:views` is temporarily removed before `super`

Ridgepole's `Diff#diff` and `DSLParser#check_definition` iterate over all keys in the definition hash, treating each key as a table name and accessing table-specific attributes such as `:definition` and `:options`. Since the view data structure (`{ sql_definition:, materialized: }`) differs from the table structure, passing it through as-is would cause `NoMethodError` or false validation failures.

To avoid this, the plugin temporarily extracts the `:views` key before calling `super`, allowing Ridgepole's core table processing to run without interference. After `super` completes, the `:views` key is restored. View diffing is handled by a separate `diff_views` method.

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
