# frozen_string_literal: true

module Ridgepole
  module View
    module DSLParser
      private

      def check_definition(definition)
        # Ridgepole::DSLParser#check_definition iterates all keys as table names and
        # validates table-specific attributes via check_orphan_index etc.
        # Temporarily remove :views to prevent false validation errors, then restore after super.
        had_views = definition.key?(:views)
        views = definition.delete(:views)
        super(definition)
      ensure
        if had_views
          definition[:views] = views
        else
          definition.delete(:views)
        end
      end
    end
  end
end
