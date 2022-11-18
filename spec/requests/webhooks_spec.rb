require 'rails_helper'

RSpec.describe 'Webhooks', type: :request do
  include StructuredLogging::TestHelper

  it 'requires a signature' do
    post webhooks_path, as: :json, params: {}
    expect(response).to have_http_status(:forbidden)
  end

  it 'does not accept invalid requests' do
    payload = { 'foo' => 'bar' }
    post webhooks_url, as: :json, params: payload, headers: signature_header(payload, 'boom!')
    expect(response).to have_http_status(:forbidden)
  end

  it 'can receive and store a webhook' do
    payload = { 'foo' => 'bar' }
    post webhooks_url, as: :json, params: payload, headers: signature_header(payload)
    expect(response).to have_http_status(:success)
    expect(payload).to eq(Event.last.payload)
  end

  it 'logs the details of the payload to Datadog' do
    payload = {
      'action' => 'create',
      'actor' => {
        'email' => 'actor@example.org',
        'id' => 'guid'
      },
      'resource' => 'release',
      'created_at' => '2022-11-02T12:14:20.166370Z',
      'data' => {
        'app' => {
          'id' => 'abcd-efgh-ijkl-mnop',
          'name' => 'biggerpockets'
        },
        'slug' => {
          'id' => 'd167531c-38e5-4c20-a7b1-d0581665a03d',
          'commit' => '851867bea056cdb2462ea416ab80ab49eeecea8b',
          'commit_description' => '  * Joe Bloggs => [COMMIT]'
        }
      }
    }
    logs = capture_json_logs do
      post webhooks_url, as: :json, params: payload, headers: signature_header(payload)
    end
    event_log_entry = logs.find_by!(level: 'info', application: 'biggerpockets')
    expect(event_log_entry).to include(
      usr: {
        email: 'actor@example.org',
        id: 'guid'
      },
      evt: {
        name: 'app.release.created',
        payload: {
          action: 'create',
          actor: {
            email: 'actor@example.org',
            id: 'guid'
          },
          resource: 'release',
          created_at: '2022-11-02T12:14:20.166370Z',
          data: {
            app: {
              id: 'abcd-efgh-ijkl-mnop',
              name: 'biggerpockets'
            },
            slug: {
              id: 'd167531c-38e5-4c20-a7b1-d0581665a03d',
              commit: '851867bea056cdb2462ea416ab80ab49eeecea8b',
              commit_description: '  * Joe Bloggs => [COMMIT]'
            }
          }
        }
      }
    )
  end

  def signature_header(payload, secret = ENV['WEBHOOK_SECRET'])
    signature = Base64.encode64(OpenSSL::HMAC.digest(
                                  OpenSSL::Digest.new('sha256'),
                                  secret,
                                  payload.to_json
                                )).strip

    {
      'Heroku-Webhook-Hmac-SHA256' => signature
    }
  end
end
