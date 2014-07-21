require 'spec_helper'

require 'hashie/mash'
require 'dredd/whitelists/organization_whitelist'

describe Dredd::OrganizationWhitelist do
  let(:client) { double('GitHub Client').as_null_object }
  let(:logger) { double('Logger').as_null_object }
  let(:allowed_organizations) { [] }
  let(:whitelist) { described_class.new(client, logger, allowed_organizations) }
  let(:user_organizations) { [Hashie::Mash.new(login: 'cloudfoundry')] }

  let(:author) { 'xoebus' }
  let(:pull_request) do
    Dredd::PullRequest.new(1, 'xoebus/dredd', author, 'opened')
  end

  describe '#whitelisted?' do
    before do
      client.should_receive(:user).with(author) do
        user = double('user')
        user.stub(:organizations_url) { 'organization_url' }
        user
      end

      client.should_receive(:get).with('organization_url') do
        user_organizations
      end
    end

    context 'when allowed organizations list is empty' do
      it 'is false' do
        expect(whitelist.whitelisted?(pull_request)).to be_false
      end
    end

    context 'when user has organizations' do
      context 'when user is member of an allowed organization' do
        let(:allowed_organizations) { %w{cloudfoundry pivotal} }

        it 'is true' do
          expect(whitelist.whitelisted?(pull_request)).to be_true
        end

        it 'logs that the pull request is not being whitelisted' do
          logger.should_receive(:info)
          .with('allow: user orgs [cloudfoundry] in allowed orgs list')

          whitelist.whitelisted?(pull_request)
        end

        context 'but the organization is in a different case' do
          let(:user_organizations) do
            [Hashie::Mash.new(login: 'CloudFoundry')]
          end

          it 'is true' do
            expect(whitelist.whitelisted?(pull_request)).to be_true
          end

          it 'logs that the pull request is being whitelisted' do
            logger.should_receive(:info)
              .with('allow: user orgs [cloudfoundry] in allowed orgs list')

            whitelist.whitelisted?(pull_request)
          end
        end
      end

      context 'when user is not a member of an allowed organization' do
        let(:allowed_organizations) { %w{facebook} }

        it 'is false' do
          expect(whitelist.whitelisted?(pull_request)).to be_false
        end

        it 'logs that the pull request is not being whitelisted' do
          logger.should_receive(:info)
            .with('deny: no user orgs [cloudfoundry] in allowed orgs list')

          whitelist.whitelisted?(pull_request)
        end
      end
    end

    context 'when user has no organizations' do
      let(:user_organizations) { [] }

      it 'is false' do
        expect(whitelist.whitelisted?(pull_request)).to be_false
      end
    end
  end
end
