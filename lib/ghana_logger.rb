# Custom Logger class.
# Features:
#   Writing to multiple Loggers
#   Logging out the time it took to run something
#   Logging detailed information about an Exception
#
# Why is it called GhanaLogger? Because it was created in Ghana!
class GhanaLogger
  attr_reader :targets

  DEFAULT_FORMATTER = proc { |sev, time, prog, msg|
    line = "#{time} [#{sev}] "
    line << "[#{prog}] " if prog
    line << "#{msg}\n"
  }

  # Initialize this logger just like the standard Logger.
  def initialize(logdev, shift_age=0, shift_size=0)
    @default_shift_age = shift_age
    @default_shift_size = shift_size
    target = ::Logger.new(logdev, shift_age, shift_size)
    target.formatter = DEFAULT_FORMATTER
    @targets = [target]
  end

  # Multi-Logger functionality
 
  # Attach a Logger.
  # You can pass one of:
  #   Logger - Will be attached as is.
  #   Arguments for Logger.new - A new Logger instance will be created.
  def attach(o, shift_age=nil, shift_size=nil)
    if o.is_a? ::Logger
      @targets << logger
    else
      shift_age ||= @default_shift_age
      shift_size ||= @default_shift_size
      @targets << ::Logger.new(o, shift_age, shift_size)
    end
  end

  # Try to find an attached Logger that matches some kind of key, and detach it.
  def detach(key)
    @targets = @targets - find_targets(key)
  end

  # Try to find an attached Logger that matches some kind of key.
  # You can pass IO objects like STDOUT, Strings to match filenames, or Regexps to match filenames.
  def find_targets(key)
    case key
    when STDOUT, STDERR
      @targets.select { |t| t.instance_variable_get(:@logdev).dev == key}
    when String
      @targets.select { |t| t.instance_variable_get(:@logdev).filename == key }
    when Regexp
      @targets.select { |t| t.instance_variable_get(:@logdev).filename =~ key }
    end
  end


  # Enables timer and exception logging for the block.
  def monitor
    time do
      log_exceptions do
        yield
      end
    end
  end


  # Enable timer for the block.
  def time
    @began = Time.now
    yield
  ensure
    self.info "Finished in %.1f sec." % (Time.now - @began)
  end


  # Enable exception logging for the block.
  def log_exceptions
    yield
  rescue Exception => e
    self.exception e
    raise e
  end


  # Log an exception in detail
  def exception(e)
    self.error "#{e.class}: #{e.message}" << ("\n#{e.backtrace.join("\n")}" unless e.backtrace.nil?)
  end


  # Route unknown methods to log targets
  def method_missing(meth, *args, &block)
    for_all_loggers(meth, *args, &block)
  end


  private
  def for_all_loggers(method, *args)
    @targets.map { |logger| logger.send(method, *args) }
  end

end
