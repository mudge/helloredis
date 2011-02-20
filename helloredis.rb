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

  def lpush(key, value)
    send_and_return("LPUSH %s %s", :string, key.to_s, :string, value.to_s)
  end

  def sort(key, options={})
    command = "SORT %s"
    arguments = [:string, key.to_s]

    if options[:by]
      command << " BY %s"
      arguments += [:string, options[:by].to_s]
    end

    if options[:count]
      command << " LIMIT %s %s"
      arguments += [:string, (options[:offset] || 0).to_i.to_s, :string, options[:count].to_i.to_s]
    end

    if options[:get]
      Array(options[:get]).each do |get|
        command << " GET %s"
        arguments += [:string, get.to_s]
      end
    end

    case options[:order]
    when :asc
      command << " ASC"
    when :desc
      command << " DESC"
    end

    if options[:alpha]
      command << " ALPHA"
    end

    if options[:store]
      command << " STORE %s"
      arguments += [:string, options[:store].to_s]
    end

    send_and_return(command, *arguments)
  end

  def lrange(key, start, stop)
    send_and_return("LRANGE %s %s %s", :string, key.to_s, :string, start.to_i.to_s, :string, stop.to_i.to_s)
  end

  def ttl(key)
    send_and_return("TTL %s", :string, key.to_s)
  end

  def type(key)
    send_and_return("TYPE %s", :string, key.to_s)
  end

  def decr(key)
    send_and_return("DECR %s", :string, key.to_s)
  end

  def decrby(key, decrement)
    send_and_return("DECRBY %s %s", :string, key.to_s, :string, decrement.to_s)
  end

  def substr(key, start, stop)
    send_and_return("SUBSTR %s %s %s", :string, key.to_s, :string, start.to_i.to_s, :string, stop.to_i.to_s)
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
