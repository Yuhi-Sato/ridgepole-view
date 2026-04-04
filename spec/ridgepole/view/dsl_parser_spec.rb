# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ridgepole::View::DSLParser do
  before do
    Ridgepole::DSLParser::Context.prepend(Ridgepole::View::DSLParser::Context) unless Ridgepole::DSLParser::Context.ancestors.include?(Ridgepole::View::DSLParser::Context)
    Ridgepole::DSLParser.prepend(described_class) unless Ridgepole::DSLParser.ancestors.include?(described_class)
  end

  let(:parser) { Ridgepole::DSLParser.new({}) }

  describe "check_definition with views" do
    it "does not raise when definition contains :views key" do
      dsl = <<~DSL
        create_view "active_users", sql_definition: "SELECT * FROM users"
      DSL
      expect { parser.parse(dsl) }.not_to raise_error
    end

    it "preserves :views in the returned definition" do
      dsl = <<~DSL
        create_view "active_users", sql_definition: "SELECT * FROM users"
      DSL
      definition, = parser.parse(dsl)
      expect(definition[:views]["active_users"]).to eq(
        sql_definition: "SELECT * FROM users",
        materialized: false
      )
    end

    it "does not pass :views to check_orphan_index" do
      # Verify that :views is not iterated as a table in check_definition
      # by ensuring no orphan index error for a :views entry
      parser_instance = Ridgepole::DSLParser.new({})
      allow(parser_instance).to receive(:check_orphan_index).and_call_original
      dsl = 'create_view "v", sql_definition: "SELECT 1"'
      parser_instance.parse(dsl)
      # :views (Symbol) should never be passed as table_name to check_orphan_index
      expect(parser_instance).not_to have_received(:check_orphan_index).with(:views, anything)
    end
  end
end
