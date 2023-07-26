# frozen_string_literal: true

module Segment
  class WebhooksController < ActionController::API
    def create
      webhook_payload = params.fetch('webhook')
      payload_batch = webhook_payload.fetch('_json', [webhook_payload])
      payload_batch.each do |payload|
        event = Event.new(payload:)
        Rails.configuration.statsd.increment(
          'segment.events',
          tags: [
            "utm_campaign:#{event.utm_campaign}",
            "utm_medium:#{event.utm_medium}",
            "utm_content:#{event.utm_content}",
            "utm_source:#{event.utm_source}",
            "utm_term:#{event.utm_term}",
            "user_id_format:#{event.user_id_format}",
            "anonymous_user_id_format:#{event.anonymous_id_format}"
          ]
        )

        unless event.user_id_invalid? || event.anonymous_id_invalid? || event.user_id_fake_guid? || event.anonymous_id_fake_guid?
          next
        end

        Rails.logger.warn(
          message: 'Segment event has incorrect user or anonymous ID',
          evt: {
            name: 'segment.event_validated',
            outcome: 'failure',
            errors: event.payload_errors,
            payload: payload
          },
          user_id_format: event.user_id_format,
          anonymous_user_id_format: event.anonymous_id_format
        )
      end

      Rails.configuration.statsd.flush(sync: true)

      render head: :ok
    end

    def valid_signature?
      signature = request.headers['x-signature']
      digest = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha1'),
        ENV['WEBHOOK_SECRET'],
        request.raw_post
      )
      digest == signature
    end
  end
end
