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
            "utms:c::#{event.utm_campaign}/m::#{event.utm_medium}/s::#{event.utm_source}/t::#{event.utm_term}/c::#{event.utm_content}"
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
