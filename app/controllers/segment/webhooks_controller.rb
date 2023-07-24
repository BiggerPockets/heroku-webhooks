# frozen_string_literal: true

module Segment
  class WebhooksController < ActionController::API
    def create
      if valid_signature?
        event = Event.create(payload: params['webhook'])
        event.reload
        render head: :ok
      else
        render json: { 'error' => 'signature_mismatch' }, status: 403
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
