# frozen_string_literal: true

module Ridgepole
  module View
    module ViewDefinition
      module_function

      def normalize(sql)
        sql.to_s
           .gsub(/\s+/, " ")
           .gsub(/;\s*\z/, "")
           .strip
           .downcase
      end

      def changed?(from, to)
        from[:materialized] != to[:materialized] ||
          normalize(from[:sql_definition]) != normalize(to[:sql_definition])
      end
    end
  end
end
