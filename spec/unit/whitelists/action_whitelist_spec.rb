require 'spec_helper'

require 'hashie/mash'
require 'dredd/whitelists/action_whitelist'

describe Dredd::ActionWhitelist do
  let(:client) { double('GitHub Client').as_null_object }
  let(:logger) { double('Logger').as_null_object }
  let(:enabled_actions) { [] }
  let(:whitelist) { described_class.new(client, logger, enabled_actions) }
  let(:pull_request_action) { 'opened' }

  let(:author) { 'xoebus' }
  let(:pull_request) do
    Dredd::PullRequest.new(1, 'xoebus/dredd', author, pull_request_action)
  end

  describe '#whitelisted?' do
    context 'when enabled actions list is empty' do
      it 'is false on any action' do
        expect(whitelist.whitelisted?(pull_request)).to be_false
      end
    end

    context 'when enabled actions are specified' do
      let(:enabled_actions) { %w{opened reopened} }

      context 'when action is not in the list' do
        let(:pull_request_action) { 'closed' }

        it 'is true' do
          expect(whitelist.whitelisted?(pull_request)).to be_true
        end

        it 'logs that the pull request is being whitelisted' do
          logger.should_receive(:info)
            .with("allow: action 'closed' not in enabled actions list")

          whitelist.whitelisted?(pull_request)
        end
      end

      context 'when action is in the list' do
        let(:pull_request_action) { 'opened' }

        it 'is false' do
          expect(whitelist.whitelisted?(pull_request)).to be_false
        end

        it 'logs that the pull request is not being whitelisted' do
          logger.should_receive(:info)
            .with("deny: action 'opened' in enabled actions list")

          whitelist.whitelisted?(pull_request)
        end
      end
    end
  end
end
