require "json"
require "logger"
require "time"
require "forwardable"

class Log16
  attr_reader :logger, :context, :options
  extend Forwardable
  def_delegators :logger, :formatter, :formatter=, :level, :level=, :debug?, :info?, :warn?, :error?, :fatal?

  DEFAULT_OPTIONS = {
    timestamp_key: :t,
    message_key: :msg,
  }

  def initialize(logger, context: {}, options: {})
    if !logger.respond_to?(:add)
      raise ArgumentError, "#{logger.inspect} must respond to :add"
    end
    @options = DEFAULT_OPTIONS.merge(options)
    @logger = logger
    @logger.formatter = proc do |severity, time, progname, msg|
      JSON.dump(msg.merge(@options[:timestamp_key] => time.iso8601(3))) + "\n"
    end
    @message_key = @options[:message_key]
    @context = sanitize(context)
  end

  def debug(message = nil, **context)
    _log(message: message, severity: Logger::DEBUG, context: {log_level: "debug"}.merge(context))
  end

  def info(message = nil, **context)
    _log(message: message, severity: Logger::INFO, context: {log_level: "info"}.merge(context))
  end

  def warn(message = nil, **context)
    _log(message: message, severity: Logger::WARN, context: {log_level: "warn"}.merge(context))
  end

  def error(message = nil, **context)
    _log(message: message, severity: Logger::ERROR, context: {log_level: "error"}.merge(context))
  end

  def fatal(message = nil, **context)
    _log(message: message, severity: Logger::FATAL, context: {log_level: "fatal"}.merge(context))
  end

  def notice(message = nil, **context)
    _log(message: message, severity: Logger::UNKNOWN, context: {log_level: "notice"}.merge(context))
  end

  def log(message = nil, **context)
    _log(message: message, severity: Logger::UNKNOWN, context: context)
  end

  def new_context(context = {})
    self.class.new(@logger, context: @context.merge(context), options: @options)
  end

  def merge_context!(context)
    @context.merge!(context)
    self
  end

  protected

  def _log(message:, severity:, context:)
    @logger.add(severity_override || severity) do
      message ||= context.delete(@message_key)
      @context.merge(sanitize(context)).merge(@message_key => sanitize(message))
    end
  end

  def severity_override
    @options[:severity]
  end

  def sanitize(obj)
    case obj
    when Hash
      Hash[obj.map do |k, v|
        [sanitize(k), sanitize(v)]
      end]
    when String
      obj.encode('utf-8', fallback: -> (chr) { chr.inspect.gsub(/"(.*)"/, "[\\1]") })
    else
      obj
    end
  end
end
