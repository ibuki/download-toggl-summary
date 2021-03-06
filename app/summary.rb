# frozen_string_literal: true

class Summary
  attr_reader :beginning_date, :end_date

  def initialize(beginning_date, end_date)
    @beginning_date = beginning_date
    @end_date = end_date
  end

  def client_times
    summaries.flat_map do |summary|
      summary[:data]
        .each_with_object(Hash.new(0)) { |project, obj| obj[project[:title][:client].tr(' ', '').downcase] += project[:time] }
        .sort_by(&:last)
        .reverse
    end
  end

  def total_grand
    summaries.map do |summary|
      summary[:total_grand]
    end.compact.sum
  end

  def summaries
    Settings.workspaces.map do |workspace|
      JSON.parse(conn.get(endpoint, params_for_workspace(workspace.workspace_id)).body).with_indifferent_access
    end
  end

  def endpoint
    '/reports/api/v2/summary'
  end

  def conn
    @conn ||= Faraday.new('https://toggl.com') do |faraday|
      faraday.adapter Faraday.default_adapter
      faraday.basic_auth(Settings.toggl_api_token, 'api_token')
    end
  end

  def params_for_workspace(workspace_id)
    {
      workspace_id: workspace_id,
      user_ids: Settings.user_id,
      user_agent: 'chrome',
      since: beginning_date_str,
      until: end_date_str,
    }
  end

  def beginning_date_str
    beginning_date.strftime('%Y-%m-%d')
  end

  def end_date_str
    end_date.strftime('%Y-%m-%d')
  end

  def decorate
    SummaryDecorator.new(self)
  end
end
