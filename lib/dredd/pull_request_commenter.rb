require 'erb'

module Dredd
  class PullRequestCommenter
    def initialize(client, logger)
      @client = client
      @logger = logger
    end

    def comment(pull_request, template)
      username = pull_request.author
      id = pull_request.id
      repository = pull_request.repository

      @logger.info("commenting on #{repository}##{id}")
      comment_text = render_comment(username, ERB.new(template))
      @client.add_comment(repository, id, comment_text)
    end

    private

    def render_comment(username, template)
      context = RenderingContext.new(username)
      template.result(context.get_binding)
    end

    class RenderingContext
      attr_reader :username

      def initialize(username)
        @username = username
      end

      def get_binding
        binding
      end
    end
  end
end
