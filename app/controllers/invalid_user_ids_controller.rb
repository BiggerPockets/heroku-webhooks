# frozen_string_literal: true

class InvalidUserIdsController < ApplicationController
  def update
    InvalidUserId.find_by!(value: params[:id]).update!(aliased_to: params[:aliased_to])
  end
end
