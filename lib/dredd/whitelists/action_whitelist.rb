require 'dredd/pull_request'

module Dredd
  class ActionWhitelist
    def initialize(client, logger, enabled_actions)
      @client = client
      @logger = logger
      @enabled_actions = enabled_actions
    end

    def whitelisted?(pull_request)
      action = pull_request.action
      whitelisted = ! (@enabled_actions.empty? ||
         @enabled_actions.include?(action))

      if whitelisted
        @logger.info "allow: action '#{action}' not in enabled actions list"
      else
        @logger.info "deny: action '#{action}' in enabled actions list"
      end

      whitelisted
    end
  end
end
