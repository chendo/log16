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
    @context = context.dup
  end

  def debug(message, **context)
    log(message: message, severity: Logger::DEBUG, context: context.merge(lvl: "debug"))
  end

  def info(message, **context)
    log(message: message, severity: Logger::INFO, context: context.merge(lvl: "info"))
  end

  def warn(message, **context)
    log(message: message, severity: Logger::WARN, context: context.merge(lvl: "warn"))
  end

  def error(message, **context)
    log(message: message, severity: Logger::ERROR, context: context.merge(lvl: "error"))
  end

  def fatal(message, **context)
    log(message: message, severity: Logger::FATAL, context: context.merge(lvl: "fatal"))
  end

  def notice(message, **context)
    log(message: message, severity: Logger::UNKNOWN, context: context.merge(lvl: "notice"))
  end

  def new_context(context = {})
    self.class.new(@logger, context: @context.merge(context))
  end

  protected

  def log(message:, severity:, context:)
    @logger.add(severity) do
      @context.merge(context).merge(msg: message)
    end
  end
end
