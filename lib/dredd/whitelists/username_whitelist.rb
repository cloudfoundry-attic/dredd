require 'dredd/pull_request'

module Dredd
  class UsernameWhitelist
    def initialize(logger, allowed_usernames)
      @logger = logger
      @allowed_usernames = allowed_usernames
    end

    def whitelisted?(pull_request)
      username = pull_request.author

      if (whitelisted = @allowed_usernames.include?(username))
        @logger.info("allow: user '#{username}' in allowed users list")
      else
        @logger.info("deny: user '#{username}' not in allowed users list")
      end

      whitelisted
    end
  end
end
