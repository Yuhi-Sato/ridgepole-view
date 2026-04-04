# frozen_string_literal: true

module Ridgepole
  module View
    module Delta
      def script
        table_script = super
        view_script = generate_view_script
        [table_script, view_script].map(&:strip).reject(&:empty?).join("\n\n")
      end

      def differ?
        !!(super || view_delta_present?)
      end

      private

      def view_delta_present?
        vd = @delta[:views]
        vd && (vd[:add]&.any? || vd[:change]&.any? || vd[:delete]&.any?)
      end

      def generate_view_script
        buf = StringIO.new
        views = @delta[:views] || {}

        (views[:delete] || {}).each do |name, attrs|
          append_drop_view(name, attrs, buf)
        end

        (views[:change] || {}).each do |name, change_attrs|
          append_drop_view(name, change_attrs[:from], buf)
        end

        (views[:add] || {}).each do |name, attrs|
          append_create_view(name, attrs, buf)
        end

        (views[:change] || {}).each do |name, change_attrs|
          append_create_view(name, change_attrs[:to], buf)
        end

        buf.string
      end

      def append_create_view(name, attrs, buf)
        mat = attrs[:materialized] ? ", materialized: true" : ""
        sql = attrs[:sql_definition]
        buf.puts "create_view #{name.inspect}, sql_definition: #{sql.inspect}#{mat}"
      end

      def append_drop_view(name, attrs, buf)
        mat = attrs[:materialized] ? ", materialized: true" : ""
        buf.puts "drop_view #{name.inspect}#{mat}"
      end
    end
  end
end
