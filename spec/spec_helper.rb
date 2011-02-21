$:.unshift(File.expand_path("../../lib", __FILE__))
require "socket"
require "helloredis"

# Ensure that Redis is running when testing.
begin
  socket = TCPSocket.new("127.0.0.1", 6379)
  socket.close
rescue
  puts "Redis must be running locally on port 6379 to run the specs."
  exit 1
end

