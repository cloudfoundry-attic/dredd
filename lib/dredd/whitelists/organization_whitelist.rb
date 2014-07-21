require 'dredd/pull_request'

module Dredd
  class OrganizationWhitelist
    def initialize(client, logger, allowed_organizations)
      @client = client
      @logger = logger
      @allowed_organizations = allowed_organizations
    end

    def whitelisted?(pull_request)
      username = pull_request.author
      organizations = organizations_for_user(username)
      intersection = (organizations & allowed_organizations)
      whitelisted = !intersection.empty?

      log_messages(whitelisted, intersection, organizations)

      whitelisted
    end

    private

    def allowed_organizations
      @allowed_organizations.map(&:downcase)
    end

    def log_messages(whitelisted, intersection, organizations)
      if whitelisted
        orgs = intersection.join(', ')
        @logger.info "allow: user orgs [#{orgs}] in allowed orgs list"
      else
        orgs = organizations.join(', ')
        @logger.info "deny: no user orgs [#{orgs}] in allowed orgs list"
      end
    end

    def organizations_for_user(username)
      user = @client.user(username)
      return [] unless user.organizations_url

      @client.get(user.organizations_url)
        .map(&:login)
        .map(&:downcase)
    end
  end
end
