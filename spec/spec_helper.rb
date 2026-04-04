# frozen_string_literal: true

require "tsort"
require "rspec"
require "ridgepole"
require "scenic"
require "ridgepole/view/version"
require "ridgepole/view/view_definition"
require "ridgepole/view/dsl_parser/context"
require "ridgepole/view/dsl_parser"
require "ridgepole/view/dumper"
require "ridgepole/view/diff"
require "ridgepole/view/delta"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
