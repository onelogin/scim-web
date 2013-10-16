module App
  extend self
  attr_accessor :log

  # init
  self.log = Logger.new('log/app.log', 10, 5242880)
  self.log.level = Logger::DEBUG  # could DEBUG, ERROR, FATAL, INFO, UNKNOWN, WARN

  self.log.formatter = proc { |severity, datetime, progname, msg|
                              "#{severity} :: #{datetime.strftime('%Y-%m-%d :: %H:%M:%S')} :: #{progname} :: #{msg}\n" }
end
