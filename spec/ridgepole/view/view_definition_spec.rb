# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ridgepole::View::ViewDefinition do
  describe ".normalize" do
    it "collapses whitespace" do
      sql = "SELECT  name,\n  email\n  FROM  users"
      expect(described_class.normalize(sql)).to eq("select name, email from users")
    end

    it "strips trailing semicolons" do
      sql = "SELECT * FROM users;"
      expect(described_class.normalize(sql)).to eq("select * from users")
    end

    it "downcases SQL" do
      sql = "SELECT Name FROM Users"
      expect(described_class.normalize(sql)).to eq("select name from users")
    end

    it "strips leading and trailing whitespace" do
      sql = "  SELECT * FROM users  "
      expect(described_class.normalize(sql)).to eq("select * from users")
    end

    it "handles nil" do
      expect(described_class.normalize(nil)).to eq("")
    end
  end

  describe ".changed?" do
    it "returns false when SQL and materialized are identical" do
      from = { sql_definition: "SELECT * FROM users", materialized: false }
      to = { sql_definition: "SELECT * FROM users", materialized: false }
      expect(described_class.changed?(from, to)).to be false
    end

    it "returns false when SQL differs only by whitespace" do
      from = { sql_definition: "SELECT *  FROM  users", materialized: false }
      to = { sql_definition: "SELECT * FROM users", materialized: false }
      expect(described_class.changed?(from, to)).to be false
    end

    it "returns true when SQL content differs" do
      from = { sql_definition: "SELECT * FROM users", materialized: false }
      to = { sql_definition: "SELECT name FROM users", materialized: false }
      expect(described_class.changed?(from, to)).to be true
    end

    it "returns true when materialized flag differs" do
      from = { sql_definition: "SELECT * FROM users", materialized: false }
      to = { sql_definition: "SELECT * FROM users", materialized: true }
      expect(described_class.changed?(from, to)).to be true
    end
  end
end
