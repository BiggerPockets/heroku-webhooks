# frozen_string_literal: true

class InvalidUserId < ApplicationRecord
  def aliased?
    aliased_to.present?
  end
end