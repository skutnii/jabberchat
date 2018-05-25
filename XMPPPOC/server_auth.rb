#!/usr/bin/env ruby

require 'logger'
require 'net/http'

$stdout.sync = true
$stdin.sync = true

log_path = File.join(File.dirname(__FILE__), "auth.log")
log_file = File.open(log_path, File::WRONLY | File::APPEND | File::CREAT)
log_file.sync = true
logger = Logger.new(log_file)
logger.level = Logger::DEBUG

def auth(username, password, logger)
  auth_link = "https://news.staging.ptu.aero/wp-json/jwt-auth/v1/token"
  headers = {"Content-Type" => "application/x-www-form-urlencoded"}

  response = Net::HTTP.post_form(URI(auth_link), :username => username, :password => password)
  logger.info response
  if response.code == '200' then
    logger.info "Auth successful for #{username}"
    return true
  else
    logger.error "Auth failed for #{username}"
    logger.info "Response: #{response.body}"
    return false
  end
rescue Exception => e
  logger.error e.message
  return false
end

logger.info "Starting ejabberd authentication service"

loop do
  begin
    $stdin.eof? # wait for input
    start = Time.now

    msg = $stdin.read(2)
    length = msg.unpack('n').first

    msg = $stdin.read(length)
    cmd, *data = msg.split(":")

    logger.info "Incoming Request: '#{cmd}'"
    success = case cmd
    when "auth"
      logger.info "Authenticating #{data[0]}@#{data[1]}"
      auth(data[0], data[2], logger)
    else
      false
    end

    bool = success ? 1 : 0
    $stdout.write [2, bool].pack("nn")
    logger.info "Response: #{success ? "success" : "failure"}"
  rescue => e
    logger.error "#{e.class.name}: #{e.message}"
    logger.error e.backtrace.join("\n\t")
  end
end