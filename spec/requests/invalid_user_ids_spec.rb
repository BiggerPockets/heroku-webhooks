# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Invalid user IDs', type: :request do
  it 'records when an invalid user ID has been aliased to another ID' do
    invalid_user_id = InvalidUserId.create(value: '123-456')
    payload = { aliased_to: 1234 }
    put invalid_user_id_path('123-456'), as: :json, params: payload
    expect(invalid_user_id.reload.aliased_to).to eq(1234)
  end
end
