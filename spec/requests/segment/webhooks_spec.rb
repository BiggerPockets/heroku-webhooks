# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength, Metrics/MethodLength

require 'rails_helper'

RSpec.describe 'Segment Webhooks', type: :request do
  include StructuredLogging::TestHelper

  it 'requires a signature' do
    post segment_webhooks_path, as: :json, params: {}
    expect(response).to have_http_status(:forbidden)
  end

  xit 'does not accept invalid requests' do
    post segment_webhooks_url, as: :json, params: payload, headers: signature_header(payload, 'boom!')
    expect(response).to have_http_status(:forbidden)
  end

  it 'can receive and store a webhook' do
    payload = { 'foo' => 'bar' }
    post segment_webhooks_url, as: :json, params: payload, headers: signature_header(payload)
    expect(response).to have_http_status(:success)
    expect(payload).to eq(Event.last.payload)
  end

  xit 'logs the details of the payload to Datadog' do
    logs = capture_json_logs do
      post segment_webhooks_url, as: :json, params: payload, headers: signature_header(payload)
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

  def payload
    {
      "_metadata": {
        "bundled": [
          'Crazy Egg',
          'Google Tag Manager',
          'Parsely',
          'ProfitWell',
          'Segment.io'
        ],
        "bundledIds": %w[
          5cf835671506090001f4640c
          K983FIJKOf
          5e9f21acf4e6e145d8640e89
          605e498a646cadfdbd2b937a
        ],
        "unbundled": []
      },
      "anonymousId": '97cfe16b-551a-4ddc-89d0-1c5b1ccb4ea0',
      "channel": 'client',
      "context": {
        "ip": '107.200.241.225',
        "library": {
          "name": 'analytics.js',
          "version": 'next-1.53.0'
        },
        "locale": 'en-US',
        "page": {
          "path": '/forums',
          "referrer": 'https://www.biggerpockets.com/forums',
          "search": '',
          "title": 'Real Estate Investing Forums, Tips & Advice | BiggerPockets',
          "url": 'https://www.biggerpockets.com/forums'
        },
        "userAgent": 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
        "userAgentData": {
          "brands": [
            {
              "brand": 'Not.A/Brand',
              "version": '8'
            },
            {
              "brand": 'Chromium',
              "version": '114'
            },
            {
              "brand": 'Google Chrome',
              "version": '114'
            }
          ],
          "mobile": false,
          "platform": 'macOS'
        }
      },
      "event": 'Navigation Menu Opened',
      "integrations": {
        "Actions Amplitude": {
          "session_id": 1_690_204_727_202
        },
        "Parsely": false
      },
      "messageId": 'ajs-next-6e24a56e8262bc1697fbf8cbc229ae6c',
      "originalTimestamp": '2023-07-24T13:42:02.952Z',
      "projectId": '9BsIBf5Kb7',
      "properties": {
        "current_url": 'https://www.biggerpockets.com/forums',
        "elementId": 'desktop-main-/forums',
        "plan_id": 'REGULAR',
        "text": 'FORUMS'
      },
      "receivedAt": '2023-07-24T13:42:04.109Z',
      "sentAt": '2023-07-24T13:42:02.966Z',
      "timestamp": '2023-07-24T13:42:04.095Z',
      "type": 'track',
      "userId": '2638327',
      "version": 2,
      "webhook": {
        "_metadata": {
          "bundled": [
            'Crazy Egg',
            'Google Tag Manager',
            'Parsely',
            'ProfitWell',
            'Segment.io'
          ],
          "bundledIds": %w[
            5cf835671506090001f4640c
            K983FIJKOf
            5e9f21acf4e6e145d8640e89
            605e498a646cadfdbd2b937a
          ],
          "unbundled": []
        },
        "anonymousId": '97cfe16b-551a-4ddc-89d0-1c5b1ccb4ea0',
        "channel": 'client',
        "context": {
          "ip": '107.200.241.225',
          "library": {
            "name": 'analytics.js',
            "version": 'next-1.53.0'
          },
          "locale": 'en-US',
          "page": {
            "path": '/forums',
            "referrer": 'https://www.biggerpockets.com/forums',
            "search": '',
            "title": 'Real Estate Investing Forums, Tips & Advice | BiggerPockets',
            "url": 'https://www.biggerpockets.com/forums'
          },
          "userAgent": 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
          "userAgentData": {
            "brands": [
              {
                "brand": 'Not.A/Brand',
                "version": '8'
              },
              {
                "brand": 'Chromium',
                "version": '114'
              },
              {
                "brand": 'Google Chrome',
                "version": '114'
              }
            ],
            "mobile": false,
            "platform": 'macOS'
          }
        },
        "event": 'Navigation Menu Opened',
        "integrations": {
          "Actions Amplitude": {
            "session_id": 1_690_204_727_202
          },
          "Parsely": false
        },
        "messageId": 'ajs-next-6e24a56e8262bc1697fbf8cbc229ae6c',
        "originalTimestamp": '2023-07-24T13:42:02.952Z',
        "projectId": '9BsIBf5Kb7',
        "properties": {
          "current_url": 'https://www.biggerpockets.com/forums',
          "elementId": 'desktop-main-/forums',
          "plan_id": 'REGULAR',
          "text": 'FORUMS'
        },
        "receivedAt": '2023-07-24T13:42:04.109Z',
        "sentAt": '2023-07-24T13:42:02.966Z',
        "timestamp": '2023-07-24T13:42:04.095Z',
        "type": 'track',
        "userId": '2638327',
        "version": 2
      }
    }
  end

  def signature_header(payload, secret = ENV['WEBHOOK_SECRET'])
    request = ActionDispatch::Request.new(
      Rack::MockRequest.env_for(
        '/',
        method: 'POST',
        input: payload.to_json
      )
    )
    {
      'x-signature' => OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha1'),
        secret,
        request.raw_post
      )
    }
  end
end

# rubocop:enable Metrics/BlockLength, Metrics/MethodLength
