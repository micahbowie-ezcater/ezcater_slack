# frozen_string_literal: true

require 'httparty'
require 'ezcater_slack'

module EzcaterSlack
  class WebhooksController < ApplicationController
    include ::SlackWebhooks

    def create
      require_post_method
      log_request

      interaction_class = ::EzcaterSlack::Bot.interactions[slack_command]
      puts '======== Headers =========='
      puts request.headers['X-Slack-Signature']
      puts request.headers['X-Slack-Request-Timestamp']
      puts params
      if interaction_class.nil?
        ::EzcaterSlack::UnknownCommandInteraction.new(params).call
      else
        ::Object.const_get(interaction_class.to_s).new(params).call
      end
    end

    private

    # def validate_slack_request
    #   signature = request.headers['X-Slack-Signature']

    #   OpenSSL::HMAC.hexdigest("SHA256", key, data)

    # end

    def log_request
      puts '====== received a webhook ========'
      puts params
    end

    def response_url
      params[:response_url]
    end

    def require_post_method
      head :unauthorized unless request.post?
    end
  end
end
