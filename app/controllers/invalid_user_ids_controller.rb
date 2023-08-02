# frozen_string_literal: true

class InvalidUserIdsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def update
    InvalidUserId.find_by!(value: params[:id]).update!(aliased_to: params[:aliased_to])
    head :ok
  end

  def index
    render json: InvalidUserId.where(aliased_to: nil)
  end
end
