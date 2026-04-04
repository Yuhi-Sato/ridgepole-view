# frozen_string_literal: true

module Ridgepole
  module View
    module ViewDefinition
      module_function

      # Normalize SQL for comparison so that semantically identical definitions
      # written differently in the Schemafile vs dumped from PostgreSQL are not
      # treated as changes (which would cause unnecessary drop_view + create_view).
      #
      # e.g. Schemafile:  "SELECT  name\n  FROM  users;"
      #      PG dump:     "select name from users"
      def normalize(sql)
        sql.to_s
           .gsub(/\s+/, " ")       # collapse newlines, tabs, multiple spaces into single space
           .gsub(/;\s*\z/, "")     # strip trailing semicolons
           .strip                  # remove leading/trailing whitespace
           .downcase               # PG may dump keywords in lowercase
      end

      def changed?(from, to)
        from[:materialized] != to[:materialized] ||
          normalize(from[:sql_definition]) != normalize(to[:sql_definition])
      end
    end
  end
end
