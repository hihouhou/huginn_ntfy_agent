module Agents
  class NtfyAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule 'every_1h'

    description <<-MD
      The Ntfy Agent interacts with a Ntfy server via its API can publish messages.

      The `type` can be like pubish.

      The `topic` is required to publish a message.

      The `message` is a Message body; set to triggered if empty or not passed

      The `title` is a Message title

      The `tags` is a list of tags that may or not map to emojis

      The `priority` (one of: 1, 2, 3, 4, or 5) Message priority with 1=min, 3=default and 5=max

      The `actions`is a JSON array 	(see action buttons) Custom user action buttons for notifications

      The `click` is an URL ,a Website opened when notification is clicked

      The `attach` is an URL of an attachment, see attach via URL

      The `delay` is Timestamp or duration for delayed delivery (30min, 9am).
      
      The `email` is an e-mail address for e-mail notifications


    MD

    event_description <<-MD
      Events look like this:

          {
            "id": "XXXXXXXXXXXX",
            "time": 1674661199,
            "event": "message",
            "topic": "test1",
            "message": "Backup successful part2"
          }
    MD

    def default_options
      {
        'debug' => 'false',
        'emit_events' => 'true',
        'changes_only' => 'true',
        'server' => 'https://ntfy.sh',
        'user' => '',
        'password' => '',
        'topic' => '',
        'message' => '',
        'title' => '',
        'tags' => '',
        'priority' => '3',
        'click' => '',
        'attach' => '',
        'delay' => '',
        'actions' => '',
        'expected_receive_period_in_days' => '2',
        'type' => 'publish'
      }
    end

    form_configurable :changes_only, type: :boolean
    form_configurable :emit_events, type: :boolean
    form_configurable :debug, type: :boolean
    form_configurable :server, type: :string
    form_configurable :user, type: :string
    form_configurable :password, type: :string
    form_configurable :topic, type: :string
    form_configurable :message, type: :string
    form_configurable :title, type: :string
    form_configurable :tags, type: :string
    form_configurable :priority, type: :string
    form_configurable :click, type: :string
    form_configurable :attach, type: :string
    form_configurable :delay, type: :string
    form_configurable :actions, type: :string
    form_configurable :expected_receive_period_in_days, type: :string
    form_configurable :type, type: :array, values: ['publish']
    def validate_options
      errors.add(:base, "type has invalid value: should be 'publish'") if interpolated['type'].present? && !%w(publish).include?(interpolated['type'])

      unless options['topic'].present? || !['publish'].include?(options['type'])
        errors.add(:base, "topic is a required field")
      end

      unless options['server'].present? || !['publish'].include?(options['type'])
        errors.add(:base, "server is a required field")
      end

      unless options['message'].present? || !['publish'].include?(options['type'])
        errors.add(:base, "message is a required field")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      if options.has_key?('emit_events') && boolify(options['emit_events']).nil?
        errors.add(:base, "if provided, emit_events must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          log event
          trigger_action
        end
      end
    end

    def check
      trigger_action
    end

    private

    def log_curl_output(code,body)

      log "request status : #{code}"

      if interpolated['debug'] == 'true'
        log "body"
        log body
      end

    end

    def publish

      data = {}
      data["topic"] = interpolated['topic'] if interpolated['topic'].present?
      data["message"] = interpolated['message'] if interpolated['message'].present?
      data["title"] = interpolated['title'] if interpolated['title'].present?
      data["tags"] = interpolated['tags'].split(" ") if interpolated['tags'].present?
      data["priority"] = interpolated['priority'].to_i if interpolated['priority'].present?
      data["attach"] = interpolated['attach'] if interpolated['attach'].present?
      data["delay"] = interpolated['delay'] if interpolated['delay'].present?
      data["click"] = interpolated['click'] if interpolated['click'].present?
      data["actions"] = interpolated['actions'] if interpolated['actions'].present?

      if interpolated['debug'] == 'true'
        log "data"
        log data
      end

      url = URI.encode(interpolated['server'])
      response = HTTParty.post(url, body: data.to_json)

      log_curl_output(response.code,response.body)

      if interpolated['emit_events'] == 'true'
        create_event payload: response.body
      end

    end

    def trigger_action

      case interpolated['type']
      when "publish"
        publish()
      else
        log "Error: type has an invalid value (#{type})"
      end
    end
  end
end
