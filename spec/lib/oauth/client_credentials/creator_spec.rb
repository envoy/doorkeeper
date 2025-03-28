# frozen_string_literal: true

require "spec_helper"

RSpec.describe Doorkeeper::OAuth::ClientCredentials::Creator do
  let(:client) { FactoryBot.create :application }
  let(:scopes) { Doorkeeper::OAuth::Scopes.from_string("public") }

  before do
    default_scopes_exist :public
  end

  it "creates a new token" do
    expect do
      subject.call(client, scopes)
    end.to change { Doorkeeper::AccessToken.count }.by(1)
  end

  context "when reuse_access_token is true" do
    before do
      allow(Doorkeeper.config).to receive(:reuse_access_token).and_return(true)
    end

    context "when expiration is disabled" do
      it "returns the existing valid token" do
        existing_token = subject.call(client, scopes)

        result = subject.call(client, scopes)

        expect(Doorkeeper::AccessToken.count).to eq(1)
        expect(result).to eq(existing_token)
      end
    end

    context "when existing token has not crossed token_reuse_limit" do
      let!(:existing_token) { subject.call(client, scopes, expires_in: 1000) }

      before do
        allow(Doorkeeper.config).to receive(:token_reuse_limit).and_return(50)
        allow_any_instance_of(Doorkeeper::AccessToken).to receive(:expires_in_seconds).and_return(600)
      end

      it "returns the existing valid token" do
        result = subject.call(client, scopes, expires_in: 1000)

        expect(Doorkeeper::AccessToken.count).to eq(1)
        expect(result).to eq(existing_token)
      end

      context "when revoke_previous_client_credentials_token is false" do
        before do
          allow(Doorkeeper.config).to receive(:revoke_previous_client_credentials_token).and_return(false)
        end

        it "does not revoke the existing valid token" do
          subject.call(client, scopes, expires_in: 1000)
          expect(existing_token.reload).not_to be_revoked
        end
      end
    end

    context "when existing token has crossed token_reuse_limit" do
      it "returns a new token" do
        allow(Doorkeeper.config).to receive(:token_reuse_limit).and_return(50)
        existing_token = subject.call(client, scopes, expires_in: 1000)

        allow_any_instance_of(Doorkeeper::AccessToken).to receive(:expires_in_seconds).and_return(400)
        result = subject.call(client, scopes, expires_in: 1000)

        expect(Doorkeeper::AccessToken.count).to eq(2)
        expect(result).not_to eq(existing_token)
      end
    end

    context "when existing token has been expired" do
      it "returns a new token" do
        allow(Doorkeeper.configuration).to receive(:token_reuse_limit).and_return(50)
        existing_token = subject.call(client, scopes, expires_in: 1000)

        allow_any_instance_of(Doorkeeper::AccessToken).to receive(:expired?).and_return(true)
        result = subject.call(client, scopes, expires_in: 1000)

        expect(Doorkeeper::AccessToken.count).to eq(2)
        expect(result).not_to eq(existing_token)
      end
    end
  end

  context "when reuse_access_token is false" do
    before do
      allow(Doorkeeper.config).to receive(:reuse_access_token).and_return(false)
    end

    it "returns a new token" do
      existing_token = subject.call(client, scopes)

      result = subject.call(client, scopes)

      expect(Doorkeeper::AccessToken.count).to eq(2)
      expect(result).not_to eq(existing_token)
    end
  end

  context "when revoke_previous_client_credentials_token is true" do
    let!(:existing_token) { subject.call(client, scopes, expires_in: 1000) }

    before do
      allow(Doorkeeper.configuration).to receive(:revoke_previous_client_credentials_token?).and_return(true)
    end

    it "revokes the existing token" do
      subject.call(client, scopes, expires_in: 1000)
      expect(existing_token.reload).to be_revoked
    end
  end

  context "when revoke_previous_client_credentials_token is false" do
    let!(:existing_token) { subject.call(client, scopes, expires_in: 1000) }

    before do
      allow(Doorkeeper.configuration).to receive(:revoke_previous_client_credentials_token?).and_return(false)
    end

    it "does not revoke the existing token" do
      subject.call(client, scopes, expires_in: 1000)
      expect(existing_token.reload).not_to be_revoked
    end
  end

  it "returns false if creation fails" do
    expect(Doorkeeper::AccessToken).to receive(:find_or_create_for).and_return(false)
    created = subject.call(client, scopes)
    expect(created).to be_falsey
  end
end
