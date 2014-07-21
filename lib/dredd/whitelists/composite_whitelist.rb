module Dredd
  class CompositeWhitelist
    def initialize(logger, whitelists)
      @logger = logger
      @whitelists = whitelists
    end

    def whitelisted?(pull_request)
      whitelisted = @whitelists.any? do |whitelist|
        whitelist.whitelisted?(pull_request)
      end

      if whitelisted
        @logger.info 'allow: at least one of the above whitelists matched'
      else
        @logger.info 'deny: none of the above whitelists matched'
      end

      whitelisted
    end
  end
end
