# frozen_string_literal: true

module StructuredLogging
  module TestHelper
    class LogRepo
      include Enumerable
      extend Forwardable

      def_delegators :@logs, :each

      class LogEntry < Hash
      end

      class NotFound < StandardError; end

      def initialize(logs)
        @logs = logs.map { |log| LogEntry[log] }
      end

      def find_by!(attrs)
        attrs = attrs.symbolize_keys
        find! { |log| log.slice(*attrs.keys) == attrs }
      end

      def find! &block
        find(-> { raise NotFound.new("Cannot find log entry matching:\n\n#{block.source.strip}\n\n in logs:\n\n#{JSON.pretty_generate(to_a)}") }, &block)
      end
    end

    private

    def capture_json_logs(buffer: StringIO.new, formatter: SemanticLogger::Formatters::DatadogJson.new)
      appender = SemanticLogger.add_appender(io: buffer, formatter: formatter)
      yield
      SemanticLogger.flush
      SemanticLogger.remove_appender(appender)
      parsed(buffer)
    end

    def parsed(output)
      logs = output.string.split("\n").map do |line|
        JSON.parse(line, symbolize_names: true)
      end
      LogRepo.new(logs)
    end

    def with_message(message)
      ->(log) { log[:message] == message }
    end

    def enqueued?
      ->(log) { log.dig(:payload, :evt, :name) == "enqueue.sidekiq" }
    end

    def enqueued_at?
      ->(log) { log.dig(:payload, :evt, :name) == "enqueue_at.sidekiq" }
    end

    def performed?
      ->(log) { log.dig(:payload, :evt, :name) == "perform.sidekiq" }
    end

    def perform_started?
      ->(log) { log.dig(:payload, :evt, :name) == "perform_start.sidekiq" }
    end

    def from_sidekiq?
      ->(log) { log[:name] == "Sidekiq" }
    end

    def error?
      ->(log) { log[:level] == "error" }
    end

    def warn_log_level?
      ->(log) { log[:level] == "warn" }
    end

    def info_log_level?
      ->(log) { log[:level] == "info" }
    end

    def with_name?(name)
      ->(log) { log[:name] == name }
    end
  end
end
