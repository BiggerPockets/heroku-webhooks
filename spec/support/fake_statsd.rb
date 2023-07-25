class FakeStatsd
  def initialize
    @unflushed_events = []
    @events = []
  end

  def events
    raise UnflushedEventsPresent, @unflushed_events if @unflushed_events.any?

    @events
  end

  # Sends an increment (count = 1) for the given stat to the statsd server.
  #
  # @param [String] stat stat name
  # @param [Hash] opts the options to create the metric with
  # @option opts [Numeric] :sample_rate sample rate, 1 for always
  # @option opts [Boolean] :pre_sampled If true, the client assumes the caller has already sampled metrics at :sample_rate, and doesn't perform sampling.
  # @option opts [Array<String>] :tags An array of tags
  # @option opts [Numeric] :by increment value, default 1
  # @see #count
  def increment(stat, opts = Datadog::Statsd::EMPTY_OPTIONS)
    opts = { sample_rate: opts } if opts.is_a?(Numeric)
    incr_value = opts.fetch(:by, 1)
    count(stat, incr_value, opts)
  end

  # Sends a decrement (count = -1) for the given stat to the statsd server.
  #
  # @param [String] stat stat name
  # @param [Hash] opts the options to create the metric with
  # @option opts [Numeric] :sample_rate sample rate, 1 for always
  # @option opts [Boolean] :pre_sampled If true, the client assumes the caller has already sampled metrics at :sample_rate, and doesn't perform sampling.
  # @option opts [Array<String>] :tags An array of tags
  # @option opts [Numeric] :by decrement value, default 1
  # @see #count
  def decrement(stat, opts = Datadog::Statsd::EMPTY_OPTIONS)
    opts = { sample_rate: opts } if opts.is_a?(Numeric)
    decr_value = - opts.fetch(:by, 1)
    count(stat, decr_value, opts)
  end

  # Sends an arbitrary count for the given stat to the statsd server.
  #
  # @param [String] stat stat name
  # @param [Integer] count count
  # @param [Hash] opts the options to create the metric with
  # @option opts [Numeric] :sample_rate sample rate, 1 for always
  # @option opts [Boolean] :pre_sampled If true, the client assumes the caller has already sampled metrics at :sample_rate, and doesn't perform sampling.
  # @option opts [Array<String>] :tags An array of tags
  def count(stat, count, opts = Datadog::Statsd::EMPTY_OPTIONS)
    opts = { sample_rate: opts } if opts.is_a?(Numeric)
    send_stats(stat, count, Datadog::Statsd::COUNTER_TYPE, opts)
  end

  def flush(flush_telemetry: false, sync: false)
    @events += @unflushed_events
    @unflushed_events = []
  end

  Event = Struct.new(:stat, :delta, :type, :opts, keyword_init: true)

  def send_stats(stat, delta, type, opts = Datadog::Statsd::EMPTY_OPTIONS)
    @unflushed_events << Event.new(stat:, delta:, type:, opts:)
  end

  def clear
    @events = []
    @unflushed_events = []
  end

  class UnflushedEventsPresent < StandardError
    def initialize(unflushed_events)
      @unflushed_events = unflushed_events
      super
    end

    def message
      "#{@unflushed_events.count} unflushed events. Ensure you call #flush(sync: true) before checking events."
    end
  end
end
