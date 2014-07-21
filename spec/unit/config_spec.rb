require 'spec_helper'
require 'dredd/config'

describe Dredd::Config do
  shared_examples_for 'a configuration file' do
    describe 'reading configuration values' do
      it 'allows you to read the username' do
        expect(config.username).to eq('config-username')
      end

      it 'allows you to read the token' do
        expect(config.token).to eq('config-token')
      end

      it 'allows you to read the callback url' do
        expect(config.callback_url).to eq('http://example.com/callback')
      end

      it 'allows you to read the callback secret' do
        expect(config.callback_secret).to eq('asdfasdfasdf')
      end

      it 'allows you to read the list of repositories' do
        expect(config.repositories).to eq(
            %w(username/repository
               username/other-repository
               other-username/repository)
        )
      end

      it 'allows you to read the list of allowed usernames' do
        expect(config.allowed_usernames).to eq(%w(allowed-username))
      end

      it 'allows you to read the list of allowed emails' do
        expect(config.allowed_emails).to eq(%w(allowed-email@example.com))
      end

      it 'allows you to read the list of allowed domains' do
        expect(config.allowed_domains).to eq(%w(example.com))
      end

      it 'allows you to read the list of allowed organizations' do
        expect(config.allowed_organizations).to eq(%w(organization))
      end

      it 'allows you to read the list of enabled actions' do
        expect(config.enabled_actions).to eq(%w(opened))
      end

      it 'allows you to read the skip bootstrap' do
        expect(config.skip_bootstrap).to be_false
      end

      it 'allows you to read the whitelisted_template' do
        expect(config.whitelisted_template).to eq('config/template_2')
      end

      it 'allows you to read the non_whitelisted_template' do
        expect(config.non_whitelisted_template).to eq('config/template_1')
      end
    end
  end

  shared_examples_for 'it has a key which is a durable array' do |key|
    context "if #{key} is not specified" do
      it 'returns an empty array for that value' do
        config_hash.delete(key)
        expect(config.send(key.to_sym)).to eq []
      end
    end

    context "if #{key} is nil (key with no value in YAML)" do
      it 'returns an empty array for that value' do
        config_hash[key] = nil
        expect(config.send(key.to_sym)).to eq []
      end
    end
  end

  describe 'reading from a hash' do
    let(:config_hash) { Psych.load(asset_contents('config.yml')) }
    let(:config) { described_class.new(config_hash) }

    it_behaves_like 'a configuration file'

    it_behaves_like 'it has a key which is a durable array',
                    'allowed_usernames'
    it_behaves_like 'it has a key which is a durable array', 'allowed_emails'
    it_behaves_like 'it has a key which is a durable array', 'allowed_domains'
  end

  describe 'reading from a file' do
    let(:config) { described_class.from_file(asset('config.yml')) }

    it_behaves_like 'a configuration file'
  end
end
