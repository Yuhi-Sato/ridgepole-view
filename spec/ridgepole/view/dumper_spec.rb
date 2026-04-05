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
      scenic_db = instance_double("Scenic::Adapters::Postgres")
      allow(scenic_db).to receive(:views).and_return(views)
      allow(Scenic).to receive(:database).and_return(scenic_db)
    end

    it "appends view definitions after table DSL" do
      allow(dumper).to receive(:dump).and_wrap_original do |_m, &block|
        view_dsl = dumper.send(:dump_views)
        [table_dsl, view_dsl].reject { |s| s.nil? || s.empty? }.join("\n\n")
      end

      result = dumper.dump
      expect(result).to include(table_dsl)
      expect(result).to include("active_users")
      expect(result).to include("user_stats")
    end

    it "includes materialized option for materialized views" do
      allow(dumper).to receive(:dump).and_wrap_original do |_m, &block|
        view_dsl = dumper.send(:dump_views)
        [table_dsl, view_dsl].reject { |s| s.nil? || s.empty? }.join("\n\n")
      end

      result = dumper.dump
      expect(result).to include("materialized: true")
    end

    it "returns only table DSL when no views exist" do
      scenic_db = instance_double("Scenic::Adapters::Postgres")
      allow(scenic_db).to receive(:views).and_return([])
      allow(Scenic).to receive(:database).and_return(scenic_db)

      allow(dumper).to receive(:dump).and_wrap_original do |_m, &block|
        view_dsl = dumper.send(:dump_views)
        [table_dsl, view_dsl].reject { |s| s.nil? || s.empty? }.join("\n\n")
      end

      result = dumper.dump
      expect(result).to eq(table_dsl)
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
