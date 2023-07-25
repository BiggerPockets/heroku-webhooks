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
            "utms:#{event.compressed_utms}",
            "user_id_format:#{event.user_id_format}",
            "anonymous_user_id_format:#{event.anonymous_id_format}"
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
