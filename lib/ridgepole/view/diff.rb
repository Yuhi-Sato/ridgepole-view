# frozen_string_literal: true

require "ridgepole/view/view_definition"

module Ridgepole
  module View
    module Diff
      def diff(from, to, options = {})
        from = (from || {}).deep_dup
        to = (to || {}).deep_dup

        from_views = from.delete(:views) || {}
        to_views = to.delete(:views) || {}

        delta = super(from, to, options)

        view_delta = diff_views(from_views, to_views)
        unless view_delta.values.all?(&:empty?)
          delta.instance_variable_get(:@delta)[:views] = view_delta
        end

        delta
      end

      private

      def diff_views(from_views, to_views)
        result = { add: {}, change: {}, delete: {} }
        all_names = (from_views.keys + to_views.keys).uniq

        all_names.each do |name|
          from = from_views[name]
          to = to_views[name]

          if from.nil? && to
            result[:add][name] = to
          elsif from && to.nil?
            result[:delete][name] = from
          elsif ViewDefinition.changed?(from, to)
            result[:change][name] = { from: from, to: to }
          end
        end

        result
      end
    end
  end
end
