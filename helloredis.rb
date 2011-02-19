require './hiredis'

class Helloredis
  attr_accessor :context

  def initialize(host="127.0.0.1", port=6379)
    context_pointer = Hiredis.redisConnect(host, port)
    @context = Hiredis::Context.new(context_pointer)
  end

  def set(key, value)
    send_and_return("SET %s %s", :string, key.to_s, :string, value.to_s)
  end

  alias_method :[]=, :set

  def get(key)
    send_and_return("GET %s", :string, key.to_s)
  end

  alias_method :[], :get

  def del(*keys)
    command = "DEL "
    arguments = []
    keys.each do |key|
      command << " %s"
      arguments += [:string, key.to_s]
    end
    send_and_return(command, *arguments)
  end

  def append(key, value)
    send_and_return("APPEND %s %s", :string, key.to_s, :string, value.to_s)
  end

  alias_method :<<, :append

  def ping
    send_and_return("PING")
  end

  def exists(key)
    1 == send_and_return("EXISTS %s", :string, key.to_s)
  end

  alias_method :exists?, :exists

  private

  def send_and_return(*args)
    process_reply(send_command(*args))
  end

  def send_command(*args)
    Hiredis.redisCommand(@context, *args)
  end

  def process_reply(reply_pointer)
    reply = Hiredis::Reply.new(reply_pointer)
    case reply[:type]
    when Hiredis::Reply::STATUS, Hiredis::Reply::STRING
      reply[:str]
    when Hiredis::Reply::INTEGER
      reply[:integer]
    when Hiredis::Reply::ERROR
      raise reply[:str]
    end
  end
end
