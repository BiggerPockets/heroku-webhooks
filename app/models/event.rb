class Event < ApplicationRecord
  def application
    payload.dig("data", "app", "name") || "<unknown>"
  end

  def name
    "heroku.#{resource}.#{action}"
  end

  def resource
    payload["resource"] || "<unknown>"
  end

  def action
    payload["action"] || "<unknown>"
  end
end
