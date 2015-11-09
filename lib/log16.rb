require "json"
require "logger"
require "time"
require "forwardable"

class Log16
  attr_reader :logger, :context
  extend Forwardable
  def_delegators :logger, :level, :level=

  def initialize(logger, context: {})
    if !logger.respond_to?(:add)
      raise ArgumentError, "#{logger.inspect} must respond to :add"
    end
    @logger = logger
    @logger.formatter = proc do |severity, time, progname, msg|
      JSON.dump(msg.merge(t: time.iso8601(3))) + "\n"
    end
    @context = sanitize(context)
  end

  def debug(message = nil, **context)
    log(message: message, severity: Logger::DEBUG, context: context.merge(lvl: "debug"))
  end

  def info(message = nil, **context)
    log(message: message, severity: Logger::INFO, context: context.merge(lvl: "info"))
  end

  def warn(message = nil, **context)
    log(message: message, severity: Logger::WARN, context: context.merge(lvl: "warn"))
  end

  def error(message = nil, **context)
    log(message: message, severity: Logger::ERROR, context: context.merge(lvl: "error"))
  end

  def fatal(message = nil, **context)
    log(message: message, severity: Logger::FATAL, context: context.merge(lvl: "fatal"))
  end

  def notice(message = nil, **context)
    log(message: message, severity: Logger::UNKNOWN, context: context.merge(lvl: "notice"))
  end

  def new_context(context = {})
    self.class.new(@logger, context: @context.merge(context))
  end

  protected

  def log(message:, severity:, context:)
    @logger.add(severity) do
      message ||= context.delete(:msg)
      @context.merge(sanitize(context)).merge(msg: sanitize(message))
    end
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
