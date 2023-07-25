# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe 'Segment Webhooks', type: :request do
  before { Rails.configuration.statsd.clear }
  after { Rails.configuration.statsd.clear }

  it 'requires a signature' do
    post segment_webhooks_path, as: :json, params: {}
    expect(response).to have_http_status(:forbidden)
  end

  it 'does not accept invalid requests' do
    post segment_webhooks_url, as: :json, params: payload, headers: signature_header(payload, 'boom!')
    expect(response).to have_http_status(:forbidden)
  end

  it 'can receive and store a webhook' do
    payload = { foo: 'bar' }
    post segment_webhooks_url, as: :json, params: payload, headers: signature_header(payload)
    expect(response).to have_http_status(:success)
    expect(payload.stringify_keys).to eq(Event.last.payload)
  end

  it 'stores the UTMs of the Segment event in Datadog via Statsd' do
    payload_with_utms = payload.deep_merge(
      webhook: {
        context: {
          campaign: {
            name: 'campaign-name',
            medium: 'campaign-medium',
            source: 'campaign-source',
            term: 'campaign-term',
            content: 'campaign-content'
          }
        }
      }
    )

    post segment_webhooks_url, as: :json, params: payload_with_utms, headers: signature_header(payload_with_utms)

    events = Rails.configuration.statsd.events
    expect(events.size).to eq(1)
    expect(events.first.to_h).to eq(
      type: Datadog::Statsd::COUNTER_TYPE,
      stat: 'segment.events',
      delta: 1,
      opts: {
        tags: [
          'utm_campaign:campaign-name',
          'utm_medium:campaign-medium',
          'utm_source:campaign-source',
          'utm_term:campaign-term',
          'utm_content:campaign-content'
        ]
      }
    )
  end

  def payload
    {
      webhook: {
        _metadata: {
          bundled: [
            'Crazy Egg',
            'Google Tag Manager',
            'Parsely',
            'ProfitWell',
            'Segment.io'
          ],
          bundledIds: %w[
            5cf835671506090001f4640c
            K983FIJKOf
            5e9f21acf4e6e145d8640e89
            605e498a646cadfdbd2b937a
          ],
          unbundled: []
        },
        anonymousId: '97cfe16b-551a-4ddc-89d0-1c5b1ccb4ea0',
        channel: 'client',
        context: {
          ip: '107.200.241.225',
          library: {
            name: 'analytics.js',
            version: 'next-1.53.0'
          },
          locale: 'en-US',
          page: {
            path: '/forums',
            referrer: 'https://www.biggerpockets.com/forums',
            search: '',
            title: 'Real Estate Investing Forums, Tips & Advice | BiggerPockets',
            url: 'https://www.biggerpockets.com/forums'
          },
          userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
          userAgentData: {
            brands: [
              {
                brand: 'Not.A/Brand',
                version: '8'
              },
              {
                brand: 'Chromium',
                version: '114'
              },
              {
                brand: 'Google Chrome',
                version: '114'
              }
            ],
            mobile: false,
            platform: 'macOS'
          }
        },
        event: 'Navigation Menu Opened',
        integrations: {
          "Actions Amplitude": {
            session_id: 1_690_204_727_202
          },
          Parsely: false
        },
        messageId: 'ajs-next-6e24a56e8262bc1697fbf8cbc229ae6c',
        originalTimestamp: '2023-07-24T13:42:02.952Z',
        projectId: '9BsIBf5Kb7',
        properties: {
          current_url: 'https://www.biggerpockets.com/forums',
          elementId: 'desktop-main-/forums',
          plan_id: 'REGULAR',
          text: 'FORUMS'
        },
        receivedAt: '2023-07-24T13:42:04.109Z',
        sentAt: '2023-07-24T13:42:02.966Z',
        timestamp: '2023-07-24T13:42:04.095Z',
        type: 'track',
        userId: '2638327',
        version: 2
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
      "x-signature": OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha1'),
        secret,
        request.raw_post
      )
    }
  end
end

# rubocop:enable Metrics/BlockLength, Metrics/MethodLength
