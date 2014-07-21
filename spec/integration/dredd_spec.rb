require 'integration_spec_helper'

require 'octokit'
require 'dredd'

describe 'dredd application lifecycle' do
  include Rack::Test::Methods

  before(:all) do
    WebMock.disable_net_connect!
  end

  after(:all) do
    WebMock.allow_net_connect!
  end

  let(:github_client) do
    Octokit::Client.new(
        login: config.username,
        oauth_token: config.token
    )
  end

  let(:allowed_usernames) { [] }
  let(:allowed_domains) { [] }
  let(:allowed_emails) { [] }
  let(:allowed_organizations) { [] }
  let(:enabled_actions) { [] }

  let(:config_hash) do
    {
        'credentials' => {
            'username' => 'github-username',
            'token' => 'github-token'
        },
        'callback_url' => 'http://example.com/callback_url',
        'callback_secret' => 'asdfasdfasdf',
        'allowed_usernames' => allowed_usernames,
        'allowed_emails' => allowed_emails,
        'allowed_domains' => allowed_domains,
        'allowed_organizations' => allowed_organizations,
        'enabled_actions' => enabled_actions,
        'repositories' => %w(username/repository 'username/other-repository'),
        'whitelisted_template' => 'whitelisted_template.md',
        'non_whitelisted_template' => 'non_whitelisted_template.md',
    }
  end
  let(:config) { Dredd::Config.new(config_hash) }
  let(:logger) { double('Logger').as_null_object }
  let(:commenter) do
    Dredd::PullRequestCommenter.new(github_client, logger)
  end
  let(:whitelist) do
    Dredd::CompositeWhitelist.new(logger, [
        Dredd::UsernameWhitelist.new(logger, config.allowed_usernames),
        Dredd::EmailWhitelist.new(github_client, logger, config.allowed_emails),
        Dredd::DomainWhitelist.new(github_client, logger, config.allowed_domains),
        Dredd::OrganizationWhitelist.new(github_client, logger, config.allowed_organizations),
        Dredd::ActionWhitelist.new(github_client, logger, config.enabled_actions)
    ])
  end
  let(:templates) do
    {
      whitelisted_template: nil,
      non_whitelisted_template: config.non_whitelisted_template,
    }
  end
  let(:whitelisted_commenter) { Dredd::WhitelistedCommenter.new(commenter, whitelist, templates) }

  let(:secret) { config.callback_secret }
  let(:payload) { asset_contents('pull_request_opened.json') }
  let(:digest) { OpenSSL::Digest::Digest.new('sha1') }
  let(:hmac) { OpenSSL::HMAC.hexdigest(digest, secret, payload) }
  let(:organizations_url) { 'https://api.github.com/users/xoebus/orgs' }

  def app
    Dredd::DreddApp
  end

  def github_calls_callback
    post '/', payload, 'HTTP_X_HUB_SIGNATURE' => "sha1=#{hmac}"
  end

  def assert_comment_was_not_made
    assert_not_requested(
        :post,
        'https://api.github.com/repos/xoebus/dredd/issues/10/comments'
    )
  end

  def assert_comment_was_made
    assert_requested(
        :post,
        'https://api.github.com/repos/xoebus/dredd/issues/10/comments'
    )
  end

  def stub_comment_creation
    stub_request(
        :post,
        'https://api.github.com/repos/xoebus/dredd/issues/10/comments'
    ).to_return(status: 201, body: '', headers: {})
  end

  def stub_email_fetching
    stub_request(:get, 'https://api.github.com/users/xoebus').to_return(
        body: JSON.dump(email: 'xoebus@xoeb.us', organizations_url: organizations_url),
        headers: { 'Content-Type' => 'application/json' }
    )
  end

  def stub_organizations_fetching
    stub_request(:get, organizations_url).to_return(
      body: JSON.dump([{ login: 'cloudfoundry' }, { login: 'pivotal' }]),
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  describe 'commenting on pull requests' do
    before do
      app.set :commenter, whitelisted_commenter
      app.set :secret, secret

      stub_email_fetching
      stub_comment_creation
      stub_organizations_fetching
    end

    describe 'allowed usernames' do
      context 'when the user is in the allowed usernames' do
        let(:allowed_usernames) { %w(xoebus) }

        it 'does not make a comment' do
          github_calls_callback
          assert_comment_was_not_made
        end
      end

      context 'when the user is not in the allowed usernames' do
        let(:allowed_usernames) { %w(seadowg tissarah) }

        it 'makes a comment' do
          github_calls_callback
          assert_comment_was_made
        end
      end
    end

    describe 'allowed emails' do
      context 'when the user email is in the allowed emails' do
        let(:allowed_emails) { %w(xoebus@xoeb.us) }

        it 'does not make a comment' do
          github_calls_callback
          assert_comment_was_not_made
        end
      end

      context 'when the user email is not in the allowed emails' do
        let(:allowed_emails) { %w(random@xoeb.us) }

        it 'makes a comment' do
          github_calls_callback
          assert_comment_was_made
        end
      end
    end

    describe 'allowed domains' do
      context 'when the user email domain is in the allowed domains' do
        let(:allowed_domains) { %w(xoeb.us) }

        it 'does not make a comment' do
          github_calls_callback
          assert_comment_was_not_made
        end
      end

      context 'when the user email domain is not in the allowed domains' do
        let(:allowed_domains) { %w(google.com) }

        it 'makes a comment' do
          github_calls_callback
          assert_comment_was_made
        end
      end
    end

    describe 'enabled actions' do
      context 'when pull request action is in the list of enabled actions' do
        let(:enabled_actions) { %w{opened reopened} }

        it 'makes a comment' do
          github_calls_callback
          assert_comment_was_made
        end
      end

      context 'when pull request action is NOT in the enabled actions list' do
        let(:enabled_actions) { %w{reopened} }

        it 'does not make a comment' do
          github_calls_callback
          assert_comment_was_not_made
        end
      end

      context 'when enabled actions is empty list' do
        let(:enabled_actions) { [] }

        it 'makes a comment' do
          github_calls_callback
          assert_comment_was_made
        end
      end
    end

    describe 'allowed organizations' do
      context 'when the user organization is in the allowed organizations' do
        let(:allowed_organizations) { %w(cloudfoundry) }

        it 'does not make a comment' do
          github_calls_callback
          assert_comment_was_not_made
        end
      end

      context 'when the user org is not in the allowed organizations' do
        let(:allowed_emails) { %w(google) }

        it 'makes a comment' do
          github_calls_callback
          assert_comment_was_made
        end
      end
    end
  end
end
