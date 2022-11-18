class Event < ApplicationRecord
  def application
    payload.dig("data", "app", "name") || "<unknown>"
  end

  def name
    "app.#{resource}.#{action}"
  end

  def name_in_past_tense
    "#{name}d"
  end

  def resource
    payload["resource"] || "<unknown>"
  end

  def action
    payload["action"] || "<unknown>"
  end
end
