# frozen_string_literal: true

require 'active_support'
require 'csv'
require_relative 'concerns/slack_interaction_params'

module EzcaterSlack
  class BaseInteraction
    include ::SlackInteractionParams

    class << self
      attr_reader :interaction_config, :interaction_channels

      # EXAMPLE
      #
      # interaction_options can_interact: { only: ['micah.bowie'] }, channels: []
      def interaction_options(options = {})
        set_interaction_config(options[:can_interact])
        @interaction_channels = options[:channels].empty? ? :all : options[:channels]
      end

      private

      def set_interaction_config(options)
        @interaction_config ||= { all: [], only: [], except: [] }
        return unless options.present?

        if options == :all
          @interaction_config[:all] << :all
          return
        end

        if options[:only] && options.is_a?(Array)
          @interaction_config[:only] += Array(options[:only])
        end

        if options[:except] && options.is_a?(Array)
          @interaction_config[:except] += Array(options[:except])
        end
      end
    end

    attr_reader :interaction_params
    def initialize(webhook_params = {})
      @interaction_params = webhook_params
    end

    def call
      unless can_interact?
        message_not_permitted
        return
      end
      execute
    end

    def execute
      puts "Method not reimplemented by child"
    end

    private

    def direct_message?
      slack_channel_name == ::SlackInteractionParams::DIRECT_MESSAGE_CHANNEL
    end

    def can_user_interact?
      # If not configuration is set then we allow any user to interact
      return true if self.class.interaction_config.nil?

      all_conditions = self.class.interaction_config[:all]
      only_conditions = self.class.interaction_config[:only]
      except_conditions = self.class.interaction_config[:except]

      return true if all_conditions.empty? && only_conditions.empty? && except_conditions.empty?
      return true if all_conditions.include?(:all)
      return true if only_conditions.include?(slack_user_name)
      return true if except_conditions.exclude?(slack_user_name)

      false
    end

    def interactive_channel?
      # If not configuration is set then we allow any user to interact
      return true if self.class.interaction_channels.nil?

      interaction_channels = self.class.interaction_channels

      return true if interaction_channels == :all
      return true if interaction_channels == :direct_message && direct_message?
      return true if interaction_channels.include?(slack_channel_name)

      false
    end

    def can_interact?
      can_user_interact? && interactive_channel?
    end

    def send_message(message)
      ::EzcaterSlack::Client.send_message(message, slack_channel_id)
    end

    def send_csv(csv_data)
      csv_content ||= CSV.generate do |csv|
        csv << csv_data.dig(:headers)
        csv_data.dig(:rows).each { |row| csv << row }
      end
      csv_data[:content] = csv_content

      ::EzcaterSlack::Client.send_csv(csv_data, slack_channel_id)
    end

    def send_message_with_template(template, args)
      ::EzcaterSlack::Client.send_message_with_template(template_name, args.merge(channel: slack_channel_id))
    end
  end
end
