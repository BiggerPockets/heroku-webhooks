class WebhooksController < ActionController::API
  def create
    if valid_signature?
      event = Event.create(payload: params['webhook'])
      event.reload # reload for predictable payload key ordering

      serialized_event = ActiveModelSerializers::SerializableResource.new(event, {serializer: EventSerializer})
      ActionCable.server.broadcast 'events', serialized_event

      Rails.logger.info(
        message: "Heroku triggered resource: #{event.resource} action: #{event.action}",
        application: event.application,
        evt: { name: event.name_in_past_tense }.merge(payload: event.payload),
        usr: event.user
      )
      # TODO ensure transaction around request?
      Event.truncate_to_recent!
    else
      render json: {'error' => 'signature_mismatch'}, status: 403
    end
  end

  private
  def valid_signature?
    calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(
      OpenSSL::Digest.new('sha256'),
      ENV['WEBHOOK_SECRET'],
      request.raw_post
    )).strip
    heroku_hmac = request.headers['Heroku-Webhook-Hmac-SHA256']

    heroku_hmac && Rack::Utils.secure_compare(calculated_hmac, heroku_hmac)
  end
end
