# frozen_string_literal: true

module Segment
  class WebhooksController < ActionController::API
    def create
      if valid_signature?
        event = Event.create(payload: params['webhook'])
        event.reload
        Rails.configuration.statsd.increment(
          'segment.events',
          tags: [
            "utm_campaign:#{event.utm_campaign}",
            "utm_medium:#{event.utm_medium}",
            "utm_source:#{event.utm_source}",
            "utm_term:#{event.utm_term}",
            "utm_content:#{event.utm_content}"
          ]
        )
        Rails.configuration.statsd.flush(sync: true)
        render head: :ok
      else
        render json: { error: 'signature_mismatch' }, status: 403
      end
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
