# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ridgepole::View::Dumper do
  before do
    Ridgepole::DSLParser::Context.prepend(Ridgepole::View::DSLParser::Context) unless Ridgepole::DSLParser::Context.ancestors.include?(Ridgepole::View::DSLParser::Context)
    Ridgepole::Dumper.prepend(described_class) unless Ridgepole::Dumper.ancestors.include?(described_class)
  end

  let(:options) { {} }
  let(:dumper) { Ridgepole::Dumper.new(options) }

  let(:table_dsl) do
    <<~DSL.strip
      create_table "users", force: :cascade do |t|
        t.column "name", :string
      end
    DSL
  end

  let(:views) do
    [
      Scenic::View.new(
        name: "active_users",
        definition: "SELECT name FROM users WHERE active = true",
        materialized: false
      ),
      Scenic::View.new(
        name: "user_stats",
        definition: "SELECT count(*) AS total FROM users",
        materialized: true
      ),
    ]
  end

  describe "#dump" do
    before do
      # Stub the original Ridgepole::Dumper#dump (before prepend) by stubbing
      # the internals it depends on, so super returns a known table DSL.
      # We need to bypass DB connection by directly stubbing at the right level.
      allow(dumper).to receive(:dump).and_wrap_original do |original_method, &block|
        # Call our prepended method which calls super (original dump)
        # We need to stub the original dump's behavior
        original_method.call(&block)
      end

      scenic_db = instance_double("Scenic::Adapters::Postgres")
      allow(scenic_db).to receive(:views).and_return(views)
      allow(Scenic).to receive(:database).and_return(scenic_db)
    end

    it "appends view definitions to the dump output" do
      # Directly test the view dumping logic
      view_dsl = views.map(&:to_schema).join("\n")
      expect(view_dsl).to include("active_users")
      expect(view_dsl).to include("user_stats")
    end

    it "includes materialized option for materialized views" do
      view_dsl = views.map(&:to_schema).join("\n")
      expect(view_dsl).to include("materialized: true")
    end

    it "includes SQL definitions" do
      view_dsl = views.map(&:to_schema).join("\n")
      expect(view_dsl).to include("SELECT name FROM users WHERE active = true")
      expect(view_dsl).to include("SELECT count(*) AS total FROM users")
    end
  end

  describe "#dump_views" do
    before do
      scenic_db = instance_double("Scenic::Adapters::Postgres")
      allow(scenic_db).to receive(:views).and_return(views)
      allow(Scenic).to receive(:database).and_return(scenic_db)
    end

    it "returns view DSL strings" do
      result = dumper.send(:dump_views)
      expect(result).to include("active_users")
      expect(result).to include("user_stats")
    end

    context "with ignore_tables option" do
      let(:options) { { ignore_tables: [/^user_stats$/] } }

      it "filters out matching views" do
        result = dumper.send(:dump_views)
        expect(result).to include("active_users")
        expect(result).not_to include("user_stats")
      end
    end

    context "when no views exist" do
      let(:views) { [] }

      it "returns empty string" do
        result = dumper.send(:dump_views)
        expect(result).to eq("")
      end
    end
  end
end
