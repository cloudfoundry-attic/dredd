require 'spec_helper'

require 'hashie/mash'
require 'dredd/whitelists/domain_whitelist'

describe Dredd::DomainWhitelist do
  let(:client) { double('GitHub Client').as_null_object }
  let(:logger) { double('Logger').as_null_object }
  let(:whitelist) { described_class.new(client, logger, allowed_domains) }

  let(:author) { 'xoebus' }
  let(:pull_request) do
    Dredd::PullRequest.new(1, 'xoebus/dredd', author, 'opened')
  end

  describe '#whitelisted?' do
    before do
      client.should_receive(:user).with(author).and_return(
          Hashie::Mash.new(email: email)
      )
    end

    context 'when the user does have an email set' do
      let(:email) { 'xoebus@xoeb.us' }

      context 'when the pull request domain is in the allowed domains' do
        let(:allowed_domains) { %w(xoeb.us) }

        it 'is true' do
          expect(whitelist.whitelisted?(pull_request)).to be_true
        end

        it 'logs that the pull request is being whitelisted' do
          logger.should_receive(:info)
            .with("allow: domain 'xoeb.us' in allowed domains list")

          whitelist.whitelisted?(pull_request)
        end
      end

      context 'when the pull request domain is not in the allowed domains' do
        let(:allowed_domains) { %w(google.com) }

        it 'is false' do
          expect(whitelist.whitelisted?(pull_request)).to be_false
        end

        it 'logs that the pull request is not being whitelisted' do
          logger.should_receive(:info)
            .with("deny: domain 'xoeb.us' not in allowed domains list")

          whitelist.whitelisted?(pull_request)
        end
      end
    end

    context 'when the user does not have an email set' do
      let(:email) { nil }
      let(:allowed_domains) { %w(xoeb.us) }

      it 'does not whitelist the user (since we can not tell if valid user)' do
        expect(whitelist.whitelisted?(pull_request)).to be_false
      end
    end
  end
end
