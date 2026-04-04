# frozen_string_literal: true

module Ridgepole
  module View
    module DSLParser
      private

      def check_definition(definition)
        # Ridgepole::DSLParser#check_definition iterates all keys as table names and
        # validates table-specific attributes via check_orphan_index etc.
        # Temporarily remove :views to prevent false validation errors, then restore after super.
        views = definition.delete(:views)
        super(definition)
      ensure
        definition[:views] = views if views
      end
    end
  end
end
