# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ridgepole::View::DSLParser::Context do
  before do
    Ridgepole::DSLParser::Context.prepend(described_class) unless Ridgepole::DSLParser::Context.ancestors.include?(described_class)
  end

  def eval_dsl(dsl)
    Ridgepole::DSLParser::Context.eval(dsl)
  end

  describe "create_view" do
    it "stores view definition under :views key" do
      definition, = eval_dsl('create_view "active_users", sql_definition: "SELECT * FROM users"')
      expect(definition[:views]).to eq(
        "active_users" => { sql_definition: "SELECT * FROM users", materialized: false }
      )
    end

    it "defaults materialized to false" do
      definition, = eval_dsl('create_view "my_view", sql_definition: "SELECT 1"')
      expect(definition[:views]["my_view"][:materialized]).to be false
    end

    it "supports materialized: true" do
      definition, = eval_dsl('create_view "my_view", sql_definition: "SELECT 1", materialized: true')
      expect(definition[:views]["my_view"][:materialized]).to be true
    end

    it "raises on duplicate view name" do
      dsl = <<~DSL
        create_view "my_view", sql_definition: "SELECT 1"
        create_view "my_view", sql_definition: "SELECT 2"
      DSL
      expect { eval_dsl(dsl) }.to raise_error(RuntimeError, /already defined/)
    end

    it "converts symbol name to string" do
      definition, = eval_dsl('create_view :my_view, sql_definition: "SELECT 1"')
      expect(definition[:views].keys).to eq(["my_view"])
    end

    it "coexists with create_table" do
      dsl = <<~DSL
        create_table "users" do |t|
          t.column "name", :string
        end
        create_view "active_users", sql_definition: "SELECT * FROM users"
      DSL
      definition, = eval_dsl(dsl)
      expect(definition.keys).to include("users", :views)
      expect(definition[:views].keys).to eq(["active_users"])
    end
  end
end
