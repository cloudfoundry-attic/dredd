require 'dredd/pull_request'
require 'dredd/pull_request_commenter'

describe Dredd::PullRequestCommenter do
  let(:client) { double('GitHub Client').as_null_object }
  let(:logger) { double('Logger').as_null_object }
  let(:template) { 'hello <%= username %>' }
  let(:commenter) { described_class.new(client, logger) }

  let(:repository) { 'xoebus/test-repo' }
  let(:id) { 55 }
  let(:username) { 'seadowg' }
  let(:action) { 'opened' }

  let(:pull_request) do
    Dredd::PullRequest.new(id, repository, username, action)
  end

  describe 'making a comment' do
    it 'makes a comment with a template' do
      client.should_receive(:add_comment).with(
          repository,
          id,
          'hello seadowg'
      )
      commenter.comment(pull_request, template)
    end

    it 'logs that it is making a comment' do
      logger.should_receive(:info)
        .with('commenting on xoebus/test-repo#55')
      commenter.comment(pull_request, template)
    end
  end
end
