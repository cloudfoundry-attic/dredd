require 'dredd/whitelists/composite_whitelist'

require 'dredd/pull_request'

describe Dredd::CompositeWhitelist do
  let(:logger) { double('Logger').as_null_object }
  let(:false_whitelist) { double(whitelisted?: false) }
  let(:true_whitelist) { double(whitelisted?: true) }

  let(:whitelist) { described_class.new(logger, whitelists) }

  let(:pull_request) do
    Dredd::PullRequest.new(1, 'xoebus/dredd', 'xoebus', 'opened')
  end

  describe '#whitelisted?' do
    let(:whitelists) { [false_whitelist, true_whitelist] }

    context 'when none of the sub-whitelists say we should whitelist' do
      let(:whitelists) { [false_whitelist, false_whitelist, false_whitelist] }

      it 'does not think we should whitelist' do
        expect(whitelist.whitelisted?(pull_request)).to be_false
      end

      it 'logs that the pull request is not being whitelisted' do
        logger.should_receive(:info)
          .with('deny: none of the above whitelists matched')

        whitelist.whitelisted?(pull_request)
      end
    end

    context 'when at least one of the sub-whitelists say we should whitelist' do
      let(:whitelists) { [false_whitelist, true_whitelist, false_whitelist] }

      it 'does think we should whitelist' do
        expect(whitelist.whitelisted?(pull_request)).to be_true
      end

      it 'logs that the pull request is being whitelisted' do
        logger.should_receive(:info)
          .with('allow: at least one of the above whitelists matched')

        whitelist.whitelisted?(pull_request)
      end
    end
  end
end
