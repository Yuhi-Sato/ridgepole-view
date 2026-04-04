# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ridgepole::View::Delta do
  before do
    Ridgepole::Delta.prepend(described_class) unless Ridgepole::Delta.ancestors.include?(described_class)
  end

  describe "#script" do
    context "when adding a view" do
      it "generates create_view statement" do
        delta_hash = {
          views: {
            add: { "active_users" => { sql_definition: "SELECT * FROM users", materialized: false } },
            change: {},
            delete: {},
          },
        }
        delta = Ridgepole::Delta.new(delta_hash, {})
        expect(delta.script).to include('create_view "active_users"')
        expect(delta.script).to include("SELECT * FROM users")
      end
    end

    context "when adding a materialized view" do
      it "includes materialized: true" do
        delta_hash = {
          views: {
            add: { "stats" => { sql_definition: "SELECT 1", materialized: true } },
            change: {},
            delete: {},
          },
        }
        delta = Ridgepole::Delta.new(delta_hash, {})
        expect(delta.script).to include("materialized: true")
      end
    end

    context "when deleting a view" do
      it "generates drop_view statement" do
        delta_hash = {
          views: {
            add: {},
            change: {},
            delete: { "old_view" => { sql_definition: "SELECT 1", materialized: false } },
          },
        }
        delta = Ridgepole::Delta.new(delta_hash, {})
        expect(delta.script).to include('drop_view "old_view"')
      end
    end

    context "when deleting a materialized view" do
      it "includes materialized: true in drop" do
        delta_hash = {
          views: {
            add: {},
            change: {},
            delete: { "old_mat" => { sql_definition: "SELECT 1", materialized: true } },
          },
        }
        delta = Ridgepole::Delta.new(delta_hash, {})
        expect(delta.script).to include('drop_view "old_mat", materialized: true')
      end
    end

    context "when changing a view" do
      it "generates drop then create" do
        delta_hash = {
          views: {
            add: {},
            change: {
              "v" => {
                from: { sql_definition: "SELECT 1", materialized: false },
                to: { sql_definition: "SELECT 2", materialized: false },
              },
            },
            delete: {},
          },
        }
        delta = Ridgepole::Delta.new(delta_hash, {})
        script = delta.script
        drop_pos = script.index('drop_view "v"')
        create_pos = script.index('create_view "v"')
        expect(drop_pos).not_to be_nil
        expect(create_pos).not_to be_nil
        expect(drop_pos).to be < create_pos
      end
    end

    context "when changing materialized flag" do
      it "uses old materialized flag for drop and new for create" do
        delta_hash = {
          views: {
            add: {},
            change: {
              "v" => {
                from: { sql_definition: "SELECT 1", materialized: true },
                to: { sql_definition: "SELECT 1", materialized: false },
              },
            },
            delete: {},
          },
        }
        delta = Ridgepole::Delta.new(delta_hash, {})
        script = delta.script
        expect(script).to include('drop_view "v", materialized: true')
        expect(script).to include('create_view "v", sql_definition: "SELECT 1"')
        expect(script).not_to include('create_view "v", sql_definition: "SELECT 1", materialized: true')
      end
    end

    context "when no views change" do
      it "returns empty script" do
        delta_hash = {}
        delta = Ridgepole::Delta.new(delta_hash, {})
        expect(delta.script).to eq("")
      end
    end
  end

  describe "#differ?" do
    it "returns true when views have changes" do
      delta_hash = {
        views: {
          add: { "v" => { sql_definition: "SELECT 1", materialized: false } },
          change: {},
          delete: {},
        },
      }
      delta = Ridgepole::Delta.new(delta_hash, {})
      expect(delta.differ?).to be true
    end

    it "returns false when no changes at all" do
      delta_hash = {}
      delta = Ridgepole::Delta.new(delta_hash, {})
      expect(delta.differ?).to be false
    end
  end
end
