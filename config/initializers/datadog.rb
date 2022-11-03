# frozen_string_literal: true

require 'net/tcp_client'
require_relative '../../lib/semantic_logger/formatters/datadog_json'

if Rails.env.review? || Rails.env.production? || ENV["LOG_TO_TCP_COLLECTOR"]
  Rails.application.config.after_initialize do
    Rails.application.configure do
      config.semantic_logger.add_appender(
        appender: :tcp,
        server: "127.0.0.1:10518",
        formatter: SemanticLogger::Formatters::DatadogJson.new,
      )
    end
  rescue Net::TCPClient::ConnectionFailure => exception
    Rails.logger.warn(exception)
  end
end
