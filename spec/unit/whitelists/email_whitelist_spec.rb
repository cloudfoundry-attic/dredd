require 'spec_helper'

require 'hashie/mash'
require 'dredd/whitelists/email_whitelist'

describe Dredd::EmailWhitelist do
  let(:client) { double('GitHub Client').as_null_object }
  let(:logger) { double('Logger').as_null_object }
  let(:whitelist) { described_class.new(client, logger, allowed_emails) }

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

      context 'when the pull request email is in the allowed emails' do
        let(:allowed_emails) { %w(xoebus@xoeb.us) }

        it 'is true' do
          expect(whitelist.whitelisted?(pull_request)).to be_true
        end

        it 'logs that the pull request is being whitelisted' do
          logger.should_receive(:info)
            .with("allow: email '#{email}' in allowed emails list")

          whitelist.whitelisted?(pull_request)
        end
      end

      context 'when the pull request email is not in the allowed emails' do
        let(:allowed_emails) { %w(random@xoeb.us) }

        it 'is false' do
          expect(whitelist.whitelisted?(pull_request)).to be_false
        end

        it 'logs that the pull request is not being whitelisted' do
          logger.should_receive(:info)
            .with("deny: email '#{email}' not in allowed emails list")

          whitelist.whitelisted?(pull_request)
        end
      end
    end

    context 'when the user does not have an email set' do
      let(:email) { nil }
      let(:allowed_emails) { %w(xoebus@xoeb.us) }

      it 'does not whitelist the user (since we can not tell if valid user)' do
        expect(whitelist.whitelisted?(pull_request)).to be_false
      end
    end
  end
end
