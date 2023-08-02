# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Invalid user IDs', type: :request do
  describe '#update' do
    it 'records when an invalid user ID has been aliased to another ID' do
      invalid_user_id = InvalidUserId.create(value: '123-456')
      payload = { aliased_to: 1234 }
      put invalid_user_id_path('123-456'), as: :json, params: payload
      expect(invalid_user_id.reload.aliased_to).to eq(1234)
    end
  end

  describe '#index' do
    it 'returns a list of invalid user IDs' do
      InvalidUserId.create(value: '123-456', aliased_to: 1234)
      InvalidUserId.create(value: '789-012', aliased_to: nil)
      get invalid_user_ids_path
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |invalid_user_id| invalid_user_id.slice('value', 'aliased_to') }).to eq([{ 'value' => '789-012', 'aliased_to' => nil }])
    end
  end
end
