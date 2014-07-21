require 'octokit'
require 'logging'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'dredd'

config = Dredd::Config.from_file('config/config.yml')
template = File.read('config/template.md.erb')

github_client = Octokit::Client.new(login: config.username,
    oauth_token: config.token)

logger = Logging.logger('dredd')
logger.level = :all
logger.add_appenders(
    Logging.appenders.stdout,
)

callback = Dredd::Callback.new(config.callback_url, config.callback_secret)
bootstrapper = Dredd::HookBootstrapper.new(github_client,
                                           logger,
                                           callback,
                                           config.skip_bootstrap)
config.repositories.each do |repo|
  bootstrapper.bootstrap_repository(repo)
end

composite_whitelist = Dredd::CompositeWhitelist.new(logger, [
    Dredd::EmailWhitelist.new(github_client, logger, config.allowed_emails),
    Dredd::UsernameWhitelist.new(logger, config.allowed_usernames),
    Dredd::DomainWhitelist.new(github_client, logger, config.allowed_domains),
    Dredd::OrganizationWhitelist.new(github_client, logger, config.allowed_organizations),
    Dredd::ActionWhitelist.new(github_client, logger, config.enabled_actions)
])

commenter = Dredd::PullRequestCommenter.new(github_client, logger, template)
whitelisted_commenter = Dredd::WhitelistedCommenter.new(commenter, composite_whitelist)

Dredd::DreddApp.set :commenter, whitelisted_commenter
Dredd::DreddApp.set :secret, config.callback_secret

run Dredd::DreddApp
