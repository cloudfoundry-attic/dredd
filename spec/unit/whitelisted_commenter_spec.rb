require 'dredd/whitelisted_commenter'

describe Dredd::WhitelistedCommenter do
  let(:commenter) { double('Commenter') }
  let(:whitelist) { double('Whitelist') }
  let(:pull_request) { double('Pull Request') }

  let(:whitelisted_commenter) { described_class.new(commenter, whitelist) }

  describe 'whitelisting when we should comment' do
    context 'when whitelist#should_whitelist? returns true' do
      before do
        whitelist.stub(whitelisted?: true)
      end

      it 'does not call through' do
        commenter.should_not_receive(:comment)

        whitelisted_commenter.comment(pull_request)
      end
    end

    context 'when the user is not in the whitelist list' do
      before do
        whitelist.stub(whitelisted?: false)
      end

      it 'calls through' do
        commenter.should_receive(:comment).with(pull_request)
        whitelisted_commenter.comment(pull_request)
      end
    end
  end
end
