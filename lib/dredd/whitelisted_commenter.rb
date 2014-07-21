module Dredd
  class WhitelistedCommenter
    def initialize(commenter, whitelist)
      @commenter = commenter
      @whitelist = whitelist
    end

    def comment(pull_request)
      return if whitelisted?(pull_request)
      @commenter.comment(pull_request)
    end

    private

    def whitelisted?(pull_request)
      @whitelist.whitelisted?(pull_request)
    end
  end
end
