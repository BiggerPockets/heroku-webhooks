# frozen_string_literal: true

module SemanticLogger
  module Formatters
    class DatadogJson < ::SemanticLogger::Formatters::Json
      def application
        super if hash.exclude?(:application)
      end

      def duration
        return unless log.duration

        hash[:duration] = (log.duration * 1000 * 1000).round(2)
      end

      def payload
        return if log.payload.to_h.empty?

        hash.deep_merge!(log.payload.then(&nest_http_attributes).then(&nest_db_statement))
      end

      def named_tags
        return if log.named_tags.to_h.empty?

        hash.deep_merge!(log.named_tags)
      end

      def exception
        return unless log.exception

        root = hash
        log.each_exception do |exception, i|
          name       = i.zero? ? :exception : :cause
          root[name] = {
            name: exception.class.name,
            message: exception.message,
            stack_trace: exception.backtrace
          }.merge(context: log.exception.respond_to?(:context) ? log.exception.context : {})
          root = root[name]
        end
      end

      private

      module HTTPAttributes
        BASE = [:format, :method, :params, :status, :status_message, :url].freeze
        RAILS = [:action, :controller].freeze
        ALL = BASE + RAILS
      end

      def nest_http_attributes
        lambda do |payload|
          http = payload.
                 slice(*HTTPAttributes::BASE).
                 then { |attrs| attrs.merge(rails: payload.slice(*HTTPAttributes::RAILS)) }.
                 transform_keys(&rename_status_to_status_code)
          payload.
            except(*HTTPAttributes::ALL).
            deep_merge(http: http)
        end
      end

      def nest_db_statement
        lambda do |payload|
          return payload.except(:sql) if payload.exclude?(:sql) || payload[:sql].blank?

          payload.
            except(:sql).
            deep_merge(
              db: {
                statement: payload.fetch(:sql).to_s,
                operation: payload.fetch(:sql).to_s.split.first,
              },
            )
        end
      end

      def rename_status_to_status_code
        ->(key) { key == :status ? :status_code : key }
      end
    end
  end
end
