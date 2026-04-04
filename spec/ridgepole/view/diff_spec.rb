# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ridgepole::View::Diff do
  before do
    Ridgepole::Diff.prepend(described_class) unless Ridgepole::Diff.ancestors.include?(described_class)
    Ridgepole::Delta.prepend(Ridgepole::View::Delta) unless Ridgepole::Delta.ancestors.include?(Ridgepole::View::Delta)
  end

  let(:diff) { Ridgepole::Diff.new({}) }

  describe "#diff" do
    context "when a view is added" do
      it "detects the addition" do
        from = {}
        to = {
          views: {
            "active_users" => { sql_definition: "SELECT * FROM users", materialized: false },
          },
        }
        delta = diff.diff(from, to)
        views_delta = delta.instance_variable_get(:@delta)[:views]
        expect(views_delta[:add]).to eq(
          "active_users" => { sql_definition: "SELECT * FROM users", materialized: false }
        )
        expect(views_delta[:change]).to be_empty
        expect(views_delta[:delete]).to be_empty
      end
    end

    context "when a view is removed" do
      it "detects the deletion" do
        from = {
          views: {
            "active_users" => { sql_definition: "SELECT * FROM users", materialized: false },
          },
        }
        to = {}
        delta = diff.diff(from, to)
        views_delta = delta.instance_variable_get(:@delta)[:views]
        expect(views_delta[:delete]).to eq(
          "active_users" => { sql_definition: "SELECT * FROM users", materialized: false }
        )
        expect(views_delta[:add]).to be_empty
        expect(views_delta[:change]).to be_empty
      end
    end

    context "when a view SQL changes" do
      it "detects the change" do
        from = {
          views: {
            "active_users" => { sql_definition: "SELECT * FROM users", materialized: false },
          },
        }
        to = {
          views: {
            "active_users" => { sql_definition: "SELECT name FROM users", materialized: false },
          },
        }
        delta = diff.diff(from, to)
        views_delta = delta.instance_variable_get(:@delta)[:views]
        expect(views_delta[:change]).to eq(
          "active_users" => {
            from: { sql_definition: "SELECT * FROM users", materialized: false },
            to: { sql_definition: "SELECT name FROM users", materialized: false },
          }
        )
      end
    end

    context "when a view materialized flag changes" do
      it "detects the change" do
        from = {
          views: {
            "v" => { sql_definition: "SELECT 1", materialized: false },
          },
        }
        to = {
          views: {
            "v" => { sql_definition: "SELECT 1", materialized: true },
          },
        }
        delta = diff.diff(from, to)
        views_delta = delta.instance_variable_get(:@delta)[:views]
        expect(views_delta[:change]).to eq(
          "v" => {
            from: { sql_definition: "SELECT 1", materialized: false },
            to: { sql_definition: "SELECT 1", materialized: true },
          }
        )
      end
    end

    context "when views are identical" do
      it "does not include :views in delta" do
        from = {
          views: {
            "v" => { sql_definition: "SELECT 1", materialized: false },
          },
        }
        to = {
          views: {
            "v" => { sql_definition: "SELECT 1", materialized: false },
          },
        }
        delta = diff.diff(from, to)
        views_delta = delta.instance_variable_get(:@delta)[:views]
        expect(views_delta).to be_nil
      end
    end

    context "when no views exist in either definition" do
      it "does not include :views in delta" do
        from = {}
        to = {}
        delta = diff.diff(from, to)
        views_delta = delta.instance_variable_get(:@delta)[:views]
        expect(views_delta).to be_nil
      end
    end
  end
end
