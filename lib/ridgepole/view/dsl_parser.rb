# frozen_string_literal: true

module Ridgepole
  module View
    module DSLParser
      private

      def check_definition(definition)
        views = definition.delete(:views)
        super(definition)
      ensure
        definition[:views] = views if views
      end
    end
  end
end
