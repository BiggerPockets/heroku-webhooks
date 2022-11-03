require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WebhooksConsumerDemo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore

    # Omniauth:
    config.middleware.use OmniAuth::Builder do
      provider :heroku, ENV['HEROKU_OAUTH_ID'], ENV['HEROKU_OAUTH_SECRET'],
      scope: 'read identity',
      fetch_info: true
    end

    config.rails_semantic_logger.semantic   = true
    config.rails_semantic_logger.started    = true
    config.rails_semantic_logger.processing = true
    config.rails_semantic_logger.rendered   = true

    config.log_tags = {
      http: lambda do |request|
        {
          headers: {
            accept: request.accept,
          },
          ip: request.remote_ip,
          request_id: request.request_id,
          url: request.original_url,
          referer: request.referer,
          useragent: request.user_agent,
          queue_time: request.env["queue_time"],
        }
      end,
      network: lambda do |request|
        {
          bytes_written: request.content_length,
        }
      end,
      dd: lambda do |_request|
        correlation = Datadog::Tracing.correlation
        {
          # To preserve precision during JSON serialization, use strings for large numbers
          trace_id: correlation.trace_id.to_s,
          span_id: correlation.span_id.to_s,
          env: correlation.env.to_s,
          service: correlation.service.to_s,
          version: correlation.version.to_s,
        }
      end,
    }
  end
end
