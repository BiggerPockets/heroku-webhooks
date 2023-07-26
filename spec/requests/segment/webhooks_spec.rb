# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe 'Segment Webhooks', type: :request do
  include StructuredLogging::TestHelper

  before { Rails.configuration.statsd.clear }
  after { Rails.configuration.statsd.clear }

  def deep_merge_with_utm_properties(payload)
    payload.deep_merge(
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
  end

  context 'with batches of events' do
    it 'sends the events to Datadog in batches' do
      batch_payload = {
        _json: [
          payload,
          deep_merge_with_utm_properties(payload)
        ]
      }

      post segment_webhooks_url, as: :json, params: batch_payload, headers: signature_header(batch_payload)

      events = Rails.configuration.statsd.events
      expect(events.size).to eq(2)
      expect(events.first.to_h).to eq(
        type: Datadog::Statsd::COUNTER_TYPE,
        stat: 'segment.events',
        delta: 1,
        opts: {
          tags: [
            'utms:c::/m::/s::/t::/c::',
            'user_id_format:social_user',
            'anonymous_user_id_format:guid'
          ]
        }
      )
      expect(events.second.to_h).to eq(
        type: Datadog::Statsd::COUNTER_TYPE,
        stat: 'segment.events',
        delta: 1,
        opts: {
          tags: [
            'utms:c::campaign-name/m::campaign-medium/s::campaign-source/t::campaign-term/c::campaign-content',
            'user_id_format:social_user',
            'anonymous_user_id_format:guid'
          ]
        }
      )
    end
  end

  it 'stores the UTMs of the Segment event in Datadog via Statsd' do
    payload_with_utms = payload.deep_merge(
      webhook: {
        anonymousId: '97cfe16b-551a-4ddc-89d0-1c5b1ccb4ea0',
        userId: '2638327',
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
          'utms:c::campaign-name/m::campaign-medium/s::campaign-source/t::campaign-term/c::campaign-content',
          'user_id_format:social_user',
          'anonymous_user_id_format:guid'
        ]
      }
    )
  end

  it "labels the user IDs as blank when they're missing " \
     'so we can detect when users are incorrectly identified in Segment' do
    payload_without_user_ids = payload.deep_merge(
      webhook: {
        userId: nil,
        anonymousId: nil
      }
    )
    post segment_webhooks_url,
         as: :json,
         params: payload_without_user_ids,
         headers: signature_header(payload_without_user_ids)

    events = Rails.configuration.statsd.events
    expect(events.size).to eq(1)
    expect(events.first.to_h).to eq(
      type: Datadog::Statsd::COUNTER_TYPE,
      stat: 'segment.events',
      delta: 1,
      opts: {
        tags: [
          'utms:c::/m::/s::/t::/c::',
          'user_id_format:blank',
          'anonymous_user_id_format:blank'
        ]
      }
    )
  end

  it 'labels the user IDs as fake guid when the ID has groups of four characters split by - ' \
     'so we can detect when users are incorrectly identified in Segment' do
    payload_without_user_ids = payload.deep_merge(
      webhook: {
        userId: 'abcd-efgh-efgh-ijkl-mnop',
        anonymousId: 'abcd-efgh-efgh-ijkl-mnop'
      }
    )
    post segment_webhooks_url,
         as: :json,
         params: payload_without_user_ids,
         headers: signature_header(payload_without_user_ids)

    events = Rails.configuration.statsd.events
    expect(events.size).to eq(1)
    expect(events.first.to_h).to eq(
      type: Datadog::Statsd::COUNTER_TYPE,
      stat: 'segment.events',
      delta: 1,
      opts: {
        tags: [
          'utms:c::/m::/s::/t::/c::',
          'user_id_format:fake_guid',
          'anonymous_user_id_format:fake_guid'
        ]
      }
    )
  end

  it 'labels the user IDs as fake guid when the ID has groups of four characters split by - ' \
     'so we can detect when users are incorrectly identified in Segment' do
    payload_without_user_ids = payload.deep_merge(
      webhook: {
        userId: '17553f63-c18b-4173-9a10-2355ec3bd25f',
        anonymousId: '4913ae7e-5b71-41ac-975c-985e9ac40eb7'
      }
    )
    post segment_webhooks_url,
         as: :json,
         params: payload_without_user_ids,
         headers: signature_header(payload_without_user_ids)

    events = Rails.configuration.statsd.events
    expect(events.size).to eq(1)
    expect(events.first.to_h).to eq(
      type: Datadog::Statsd::COUNTER_TYPE,
      stat: 'segment.events',
      delta: 1,
      opts: {
        tags: [
          'utms:c::/m::/s::/t::/c::',
          'user_id_format:guid',
          'anonymous_user_id_format:guid'
        ]
      }
    )
  end

  it 'labels the user IDs as invalid when they do not match any known format ' \
     'so we can detect when users are incorrectly identified in Segment' do
    payload_without_user_ids = payload.deep_merge(
      webhook: {
        userId: 'invalid-format',
        anonymousId: 'invalid-format'
      }
    )
    post segment_webhooks_url,
         as: :json,
         params: payload_without_user_ids,
         headers: signature_header(payload_without_user_ids)

    events = Rails.configuration.statsd.events
    expect(events.size).to eq(1)
    expect(events.first.to_h).to eq(
      type: Datadog::Statsd::COUNTER_TYPE,
      stat: 'segment.events',
      delta: 1,
      opts: {
        tags: [
          'utms:c::/m::/s::/t::/c::',
          'user_id_format:invalid',
          'anonymous_user_id_format:invalid'
        ]
      }
    )
  end

  it 'logs a warning to Datadog when user IDs are anonymous ' \
     'so we can detect when users are incorrectly identified in Segment' do
    adjusted_payload = payload.deep_merge(
      webhook: {
        userId: 'invalid-format'
      }
    )
    logs = capture_json_logs do
      post segment_webhooks_url,
           as: :json,
           params: adjusted_payload,
           headers: signature_header(adjusted_payload)
    end

    event_log_entry = logs.find_by!(level: 'warn', application: 'segment')
    expect(event_log_entry.slice(:evt, :message)).to eq(
      message: 'Segment event has incorrect user or anonymous ID',
      evt: {
        name: 'segment.event_validated',
        outcome: 'failure',
        errors: [{ code: 'event.user_id.invalid' }],
        payload: adjusted_payload.fetch(:webhook)
      }
    )
  end

  it 'allows guids for anonymous users starting with e: ' \
     'so that we do not get false positives in Datadog when the ID has been generated from an email' do
    adjusted_payload = payload.deep_merge(
      webhook: {
        anonymousId: 'e:17553f63c18b41739a10'
      }
    )
    logs = capture_json_logs do
      post segment_webhooks_url,
           as: :json,
           params: adjusted_payload,
           headers: signature_header(adjusted_payload)
    end

    expect(logs.count { |log| log[:level] == 'warn' && log[:application] == 'segment' }).to eq(0)
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
