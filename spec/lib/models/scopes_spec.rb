# frozen_string_literal: true

require "spec_helper"

RSpec.describe Doorkeeper::Models::Scopes do
  subject do
    Class.new(Struct.new(:scopes)) do
      include Doorkeeper::Models::Scopes
    end.new
  end

  before do
    subject[:scopes] = "public admin"
  end

  describe "#scopes" do
    it "is a `Scopes` class" do
      expect(subject.scopes).to be_a(Doorkeeper::OAuth::Scopes)
    end

    it "includes scopes" do
      expect(subject.scopes).to include("public")
    end
  end

  describe "#scopes=" do
    it "accepts String" do
      subject.scopes = "private admin"
      expect(subject.scopes_string).to eq("private admin")
    end

    it "accepts Array" do
      subject.scopes = %w[private admin]
      expect(subject.scopes_string).to eq("private admin")
    end

    it "ignores duplicated scopes" do
      subject.scopes = %w[private admin admin]
      expect(subject.scopes_string).to eq("private admin")

      subject.scopes = "private admin admin"
      expect(subject.scopes_string).to eq("private admin")
    end
  end

  describe "#scopes_string" do
    it "is a `Scopes` class" do
      expect(subject.scopes_string).to eq("public admin")
    end
  end

  describe "#includes_scope?" do
    it "returns true if at least one scope is included" do
      expect(subject.includes_scope?("public", "private")).to be true
    end

    it "returns false if no scopes are included" do
      expect(subject.includes_scope?("teacher", "student")).to be false
    end
  end
end
