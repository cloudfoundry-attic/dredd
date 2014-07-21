require 'spec_helper'

require 'dredd/whitelists/username_whitelist'

describe Dredd::UsernameWhitelist do
  let(:logger) { double('Logger').as_null_object }
  let(:whitelist) { described_class.new(logger, allowed_usernames) }

  let(:author) { 'xoebus' }
  let(:pull_request) do
    Dredd::PullRequest.new(1, 'xoebus/dredd', author, 'opened')
  end

  describe '#whitelisted?' do
    context 'when the pull request author is in the allowed usernames' do
      let(:allowed_usernames) { [author] }

      it 'is true' do
        expect(whitelist.whitelisted?(pull_request)).to be_true
      end

      it 'logs that the pull request is being whitelisted' do
        logger.should_receive(:info)
          .with("allow: user '#{author}' in allowed users list")

        whitelist.whitelisted?(pull_request)
      end
    end

    context 'when the pull request author is in the allowed usernames' do
      let(:allowed_usernames) { %w(seadowg tissarah) }

      it 'is false' do
        expect(whitelist.whitelisted?(pull_request)).to be_false
      end

      it 'logs that the pull request is not being whitelisted' do
        logger.should_receive(:info)
          .with("deny: user '#{author}' not in allowed users list")

        whitelist.whitelisted?(pull_request)
      end
    end
  end
end
