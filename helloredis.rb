require './hiredis'

class Helloredis
  attr_accessor :context

  def initialize(host="127.0.0.1", port=6379)
    context_pointer = Hiredis.redisConnect(host, port)
    @context = Hiredis::Context.new(context_pointer)
    raise @context[:errstr] if 1 == @context[:err]
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

  def expire(key, seconds)
    1 == send_and_return("EXPIRE %s %s", :string, key.to_s, :string, seconds.to_s)
  end

  def expireat(key, timestamp)
    1 == send_and_return("EXPIRE %s %s", :string, key.to_s, :string, timestamp.to_i.to_s)
  end

  def keys(pattern)
    send_and_return("KEYS %s", :string, pattern.to_s)
  end

  def move(key, db)
    1 == send_and_return("MOVE %s %s", :string, key.to_s, :string, db.to_s)
  end

  def select(index)
    send_and_return("SELECT %s", :string, index.to_s)
  end

  def persist(key)
    1 == send_and_return("PERSIST %s", :string, key.to_s)
  end

  def info
    info = send_and_return("INFO")
    Hash[*info.split(/(?:\r\n|:)/)]
  end

  def randomkey
    send_and_return("RANDOMKEY")
  end

  def flushdb
    send_and_return("FLUSHDB")
  end

  def rename(key, newkey)
    send_and_return("RENAME %s %s", :string, key.to_s, :string, newkey.to_s)
  end

  def renamenx(key, newkey)
    1 == send_and_return("RENAMENX %s %s", :string, key.to_s, :string, newkey.to_s)
  end

  private

  def send_and_return(*args)
    process_reply(send_command(*args))
  end

  def send_command(*args)
    Hiredis.redisCommand(@context, *args)
  end

  # The "free" argument is for processing nested replies which do not need their
  # memory freed (as the root reply will take care of that).
  def process_reply(reply_pointer, free=true)
    reply = Hiredis::Reply.new(reply_pointer)
    case reply[:type]
    when Hiredis::Reply::STATUS, Hiredis::Reply::STRING
      reply[:str]
    when Hiredis::Reply::INTEGER
      reply[:integer]
    when Hiredis::Reply::NIL
      nil
    when Hiredis::Reply::ARRAY
      (0...reply[:elements]).map do |i|
        single_reply = reply[:element] + (i * FFI::Pointer.size)
        process_reply(single_reply.read_pointer, false)
      end
    when Hiredis::Reply::ERROR
      raise reply[:str]
    end
  ensure
    Hiredis.freeReplyObject(reply_pointer) if free
  end
end
