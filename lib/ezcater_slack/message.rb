# frozen_string_literal: true

require 'csv'
require 'slack-ruby-client'
require_relative './message/compilation'

module EzcaterSlack
  class Message
    class << self
      def define(&block)
        @templates ||= {}
        instance_exec(&block)
      end

      def compile(template_name, args = {})
        template = @templates.fetch(template_name) do
          raise ArgumentError, "Template #{template_name} not defined"
        end
        template.reset_message_blocks
        template.compile(args)
      end

      def template(name, &block)
        instance = new
        instance.instance_eval(&block)
        @templates[name] = instance
      end
    end

    attr_reader :name, :blocks, :environment, :channels, :tagged_users

    def initialize
      @blocks = []
      @environment = nil
      @channels = []
      @tagged_users = []
      @csv_data_block = []
    end

    def template(name, &block)
      @name = name
      instance_eval(&block) if block_given?
    end

    def text(text = nil , &block)
      @text_block = text.nil? ? block : Proc.new {|x| text  }
    end

    def title(title = nil , &block)
      @title_block = title.nil? ? block : Proc.new {|x| title  }
    end

    def markdown_section(markdown = nil, &block)
      @markdown_block = markdown.nil? ? block : Proc.new {|x| markdown  }
    end

    # def list_section(&block)
    #   @markdown_block = markdown.nil? ? block : Proc.new {|x| markdown  }
    # end

    def environment(env)
      @environment = env
    end

    def channel(channel)
      @channels << channel
    end

    def mention(*users)
      # Format the user mention strings
      @tagged_users = users.flatten
      @user_mentions = users.flatten.join(' ')
    end

    def csv_data(bool = false)
      @include_csv_data = bool
    end

    def compile(args = {})
      construct_environment_block if @environment
      construct_title_block(args) if @title_block
      construct_text_block(args) if @text_block
      construct_markdown_block(args) if @markdown_block
      construct_csv(args) if @include_csv_data
      add_user_mentions if @tagged_users.any?

      message_payload = {
        blocks: @blocks,
        channel: args[:channel] || @channels,
      }

      ::EzcaterSlack::Message::Compilation.new(
        message_payload,
        @include_csv_data,
        @csv_data
      )
    end

    def reset_message_blocks
      @blocks = []
    end

    private

    def construct_environment_block
      env = @environment.upcase
      add_block(type: 'section', text: { type: 'mrkdwn', text: "Environment: [#{env}] \n" })
    end

    def construct_title_block(args)
      text_content = @title_block.call(args)
      add_block(type: 'header', text: { type: 'plain_text', text: text_content })
    end

    def construct_text_block(args)
      text_content = @text_block.call(args)
      add_block(type: 'rich_text', elements: [ type: 'rich_text_section', elements: [ { type: 'text', text: text_content } ] ])
    end

    def construct_markdown_block(args)
      markdown_content = @markdown_block.call(args)
      add_block(type: 'section', text: { type: 'mrkdwn', text: "```#{markdown_content}```" })
    end

    def add_user_mentions
      unless @tagged_users.empty?
        # Format a string that includes all user mentions with Slack mention syntax
        user_mentions = @tagged_users.map { |user| "<#{user}>" }.join(' ')

        # Create a context block with all user mentions in one line
        add_block({
          type: 'context',
          elements: [{ type: 'mrkdwn', text: "CC: #{user_mentions}" }]
        })
      end
    end

    def construct_csv(args)
      return unless @include_csv_data

      data = args.slice(:csv)
      @csv_content ||= CSV.generate do |csv|
        csv << args.dig(:csv, :headers)
        args.dig(:csv, :rows).each { |row| csv << row }
      end
      data[:csv][:content] = @csv_content
      @csv_data = data
    end

    def add_block(block)
      @blocks << block
    end
  end
end
