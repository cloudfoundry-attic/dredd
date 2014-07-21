module Dredd
  class WhitelistedCommenter
    def initialize(commenter, whitelist, templates)
      @commenter = commenter
      @whitelist = whitelist
      @whitelisted_template = templates[:whitelisted_template]
      @non_whitelisted_template = templates[:non_whitelisted_template]
    end

    def comment(pull_request)
      if whitelisted?(pull_request)
        @commenter.comment(pull_request, @whitelisted_template) if @whitelisted_template
      else
        @commenter.comment(pull_request, @non_whitelisted_template)
      end
    end

    private

    def whitelisted?(pull_request)
      @whitelist.whitelisted?(pull_request)
    end
  end
end
