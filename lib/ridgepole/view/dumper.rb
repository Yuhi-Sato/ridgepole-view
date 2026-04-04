# frozen_string_literal: true

module Ridgepole
  module View
    module Dumper
      def dump(&block)
        result = super(&block)
        view_dsl = dump_views
        view_dsl.empty? ? result : [result, view_dsl].join("\n\n")
      end

      private

      def dump_views
        views = Scenic.database.views
        views = views.reject { |v| ignored_view?(v.name) }
        views.map(&:to_schema).join("\n")
      end

      def ignored_view?(name)
        return false unless @options[:ignore_tables]

        @options[:ignore_tables].any? { |pattern| pattern =~ name }
      end
    end
  end
end
