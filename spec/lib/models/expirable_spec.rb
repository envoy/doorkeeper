# frozen_string_literal: true

require "spec_helper"

RSpec.describe Doorkeeper::Models::Expirable do
  subject do
    Class.new do
      include Doorkeeper::Models::Expirable
    end.new
  end

  before do
    allow(subject).to receive(:created_at).and_return(1.minute.ago)
  end

  describe "#expired?" do
    it "is not expired if time has not passed" do
      allow(subject).to receive(:expires_in).and_return(2.minutes)
      expect(subject).not_to be_expired
    end

    it "is expired if time has passed" do
      allow(subject).to receive(:expires_in).and_return(10.seconds)
      expect(subject).to be_expired
    end

    it "is not expired if expires_in is not set" do
      allow(subject).to receive(:expires_in).and_return(nil)
      expect(subject).not_to be_expired
    end
  end

  describe "#expires_in_seconds" do
    it "returns the amount of time remaining until the token is expired" do
      allow(subject).to receive(:expires_in).and_return(2.minutes)
      expect(subject.expires_in_seconds).to eq(60)
    end

    it "returns 0 when expired" do
      allow(subject).to receive(:expires_in).and_return(30.seconds)
      expect(subject.expires_in_seconds).to eq(0)
    end

    it "returns nil when expires_in is nil" do
      allow(subject).to receive(:expires_in).and_return(nil)
      expect(subject.expires_in_seconds).to be_nil
    end
  end

  describe "#expires_at" do
    it "returns the expiration time of the token" do
      allow(subject).to receive(:expires_in).and_return(2.minutes)
      expect(subject.expires_at).to be_a(Time)
    end

    it "returns nil when expires_in is nil" do
      allow(subject).to receive(:expires_in).and_return(nil)
      expect(subject.expires_at).to be_nil
    end
  end
end
