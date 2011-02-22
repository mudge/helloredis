$:.unshift(File.expand_path("../../lib", __FILE__))
require "helloredis"

# Ensure that Redis is running when testing.
begin
  test = Helloredis.new
  REDIS_VERSION = test.version
rescue
  puts "Redis must be running locally on port 6379 to run the specs."
  exit 1
end

