# frozen_string_literal: true

module Ridgepole
  module View
    module DSLParser
      module Context
        def create_view(name, sql_definition:, materialized: false)
          name = name.to_s
          @__definition[:views] ||= {}

          raise "View `#{name}` already defined" if @__definition[:views][name]

          @__definition[:views][name] = {
            sql_definition: sql_definition,
            materialized: materialized,
          }
        end
      end
    end
  end
end
