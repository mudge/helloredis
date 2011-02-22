require 'rubygems/version'
require 'hiredis'

class Helloredis
  attr_accessor :context

  def initialize(options={})
    options[:host] ||= "127.0.0.1"
    options[:port] ||= 6379
    context_pointer = if options[:path]
      Hiredis.redisConnectUnix(options[:path])
    else
      Hiredis.redisConnect(options[:host], options[:port])
    end
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

  def lpushx(key, value)
    send_and_return("LPUSHX %s %s", :string, key.to_s, :string, value.to_s)
  end

  def rpushx(key, value)
    send_and_return("RPUSHX %s %s", :string, key.to_s, :string, value.to_s)
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

  def getbit(key, offset)
    send_and_return("GETBIT %s %s", :string, key.to_s, :string, offset.to_i.to_s)
  end

  def setbit(key, offset, value)
    send_and_return("SETBIT %s %s %s", :string, key.to_s, :string, offset.to_i.to_s, :string, value.to_i.to_s)
  end

  def substr(key, start, stop)
    send_and_return("SUBSTR %s %s %s", :string, key.to_s, :string, start.to_i.to_s, :string, stop.to_i.to_s)
  end

  def getrange(key, start, stop)
    send_and_return("GETRANGE %s %s %s", :string, key.to_s, :string, start.to_i.to_s, :string, stop.to_i.to_s)
  end

  def setrange(key, offset, value)
    send_and_return("SETRANGE %s %s %s", :string, key.to_s, :string, offset.to_i.to_s, :string, value.to_s)
  end

  def strlen(key)
    send_and_return("STRLEN %s", :string, key.to_s)
  end

  def getset(key, value)
    send_and_return("GETSET %s %s", :string, key.to_s, :string, value.to_s)
  end

  def incr(key)
    send_and_return("INCR %s", :string, key.to_s)
  end

  def incrby(key, increment)
    send_and_return("INCRBY %s %s", :string, key.to_s, :string, increment.to_s)
  end

  def mget(key, *keys)
    command = "MGET %s"
    arguments = [:string, key.to_s]

    keys.each do |key|
      command << " %s"
      arguments += [:string, key.to_s]
    end

    send_and_return(command, *arguments)
  end

  def mset(keys_and_values)
    command = "MSET"
    arguments = []
    keys_and_values.each do |key, value|
      command << " %s %s"
      arguments += [:string, key.to_s, :string, value.to_s]
    end

    send_and_return(command, *arguments)
  end

  def msetnx(values)
    command = "MSETNX"
    arguments = []
    values.to_a.flatten.each do |value|
      command << " %s"
      arguments += [:string, value.to_s]
    end

    1 == send_and_return(command, *arguments)
  end

  def setex(key, seconds, value)
    send_and_return("SETEX %s %s %s", :string, key.to_s, :string, seconds.to_i.to_s, :string, value.to_s)
  end

  def setnx(key, value)
    1 == send_and_return("SETNX %s %s", :string, key.to_s, :string, value.to_s)
  end

  def hset(key, field, value)
    1 == send_and_return("HSET %s %s %s", :string, key.to_s, :string, field.to_s, :string, value.to_s)
  end

  def hget(key, field)
    send_and_return("HGET %s %s", :string, key.to_s, :string, field.to_s)
  end

  def hdel(key, field)
    1 == send_and_return("HDEL %s %s", :string, key.to_s, :string, field.to_s)
  end

  def hexists(key, field)
    1 == send_and_return("HEXISTS %s %s", :string, key.to_s, :string, field.to_s)
  end

  def hgetall(key)
    values = send_and_return("HGETALL %s", :string, key.to_s)
    Hash[*values]
  end

  def hincrby(key, field, increment)
    send_and_return("HINCRBY %s %s %s", :string, key.to_s, :string, field.to_s, :string, increment.to_i.to_s)
  end

  def hkeys(key)
    send_and_return("HKEYS %s", :string, key.to_s)
  end

  def hlen(key)
    send_and_return("HLEN %s", :string, key.to_s)
  end

  def hmget(key, field, *fields)
    command = "HMGET %s %s"
    arguments = [:string, key.to_s, :string, field.to_s]

    fields.each do |field|
      command << " %s"
      arguments += [:string, field.to_s]
    end

    send_and_return(command, *arguments)
  end

  def hmset(key, fields_and_values)
    command = "HMSET %s"
    arguments = [:string, key.to_s]
    fields_and_values.each do |field, value|
      command << " %s %s"
      arguments += [:string, field.to_s, :string, value.to_s]
    end
    send_and_return(command, *arguments)
  end

  def hsetnx(key, field, value)
    1 == send_and_return("HSETNX %s %s %s", :string, key.to_s, :string, field.to_s, :string, value.to_s)
  end

  def hvals(key)
    send_and_return("HVALS %s", :string, key.to_s)
  end

  def rpush(key, value)
    send_and_return("RPUSH %s %s", :string, key.to_s, :string, value.to_s)
  end

  def blpop(key, *keys_and_timeout)
    timeout = keys_and_timeout.pop
    command = "BLPOP %s"
    arguments = [:string, key.to_s]
    keys_and_timeout.each do |key|
      command << " %s"
      arguments += [:string, key.to_s]
    end
    command << " %s"
    arguments += [:string, timeout.to_i.to_s]
    send_and_return(command, *arguments)
  end

  def brpop(key, *keys_and_timeout)
    timeout = keys_and_timeout.pop
    command = "BRPOP %s"
    arguments = [:string, key.to_s]
    keys_and_timeout.each do |key|
      command << " %s"
      arguments += [:string, key.to_s]
    end
    command << " %s"
    arguments += [:string, timeout.to_i.to_s]
    send_and_return(command, *arguments)
  end

  def lindex(key, index)
    send_and_return("LINDEX %s %s", :string, key.to_s, :string, index.to_i.to_s)
  end

  def linsert(key, value, position_and_pivot)
    if position_and_pivot[:before]
      position = "BEFORE"
      pivot = position_and_pivot[:before]
    elsif position_and_pivot[:after]
      position = "AFTER"
      pivot = position_and_pivot[:after]
    else
      raise "pivot must either be :before or :after"
    end

    send_and_return("LINSERT %s #{position} %s %s", :string, key.to_s, :string, pivot.to_s, :string, value.to_s)
  end

  def llen(key)
    send_and_return("LLEN %s", :string, key.to_s)
  end

  def lpop(key)
    send_and_return("LPOP %s", :string, key.to_s)
  end

  def lrem(key, count, value)
    send_and_return("LREM %s %s %s", :string, key.to_s, :string, count.to_s, :string, value.to_s)
  end

  def lset(key, index, value)
    send_and_return("LSET %s %s %s", :string, key.to_s, :string, index.to_i.to_s, :string, value.to_s)
  end

  def ltrim(key, start, stop)
    send_and_return("LTRIM %s %s %s", :string, key.to_s, :string, start.to_i.to_s, :string, stop.to_i.to_s)
  end

  def rpop(key)
    send_and_return("RPOP %s", :string, key.to_s)
  end

  def rpoplpush(source, destination)
    send_and_return("RPOPLPUSH %s %s", :string, source.to_s, :string, destination.to_s)
  end

  def brpoplpush(source, destination, timeout)
    send_and_return("BRPOPLPUSH %s %s %s", :string, source.to_s, :string, destination.to_s, :string, timeout.to_s)
  end

  def sadd(key, member)
    1 == send_and_return("SADD %s %s", :string, key.to_s, :string, member.to_s)
  end

  def scard(key)
    send_and_return("SCARD %s", :string, key.to_s)
  end

  def sdiff(key, *keys)
    command = "SDIFF %s"
    arguments = [:string, key.to_s]
    keys.each do |key|
      command << " %s"
      arguments += [:string, key.to_s]
    end
    send_and_return(command, *arguments)
  end

  def sdiffstore(destination, key, *keys)
    command = "SDIFFSTORE %s %s"
    arguments = [:string, destination.to_s, :string, key.to_s]
    keys.each do |key|
      command << " %s"
      arguments += [:string, key.to_s]
    end
    send_and_return(command, *arguments)
  end

  def smembers(key)
    send_and_return("SMEMBERS %s", :string, key.to_s)
  end

  def sinter(key, *keys)
    command = "SINTER %s"
    arguments = [:string, key.to_s]
    keys.each do |key|
      command << " %s"
      arguments += [:string, key.to_s]
    end
    send_and_return(command, *arguments)
  end

  def sinterstore(destination, key, *keys)
    command = "SINTERSTORE %s %s"
    arguments = [:string, destination.to_s, :string, key.to_s]
    keys.each do |key|
      command << " %s"
      arguments += [:string, key.to_s]
    end
    send_and_return(command, *arguments)
  end

  def sismember(key, member)
    1 == send_and_return("SISMEMBER %s %s", :string, key.to_s, :string, member.to_s)
  end

  def smove(source, destination, member)
    1 == send_and_return("SMOVE %s %s %s", :string, source.to_s, :string, destination.to_s, :string, member.to_s)
  end

  def spop(key)
    send_and_return("SPOP %s", :string, key.to_s)
  end

  def srandmember(key)
    send_and_return("SRANDMEMBER %s", :string, key.to_s)
  end

  def srem(key, member)
    1 == send_and_return("SREM %s %s", :string, key.to_s, :string, member.to_s)
  end

  def sunion(key, *keys)
    command = "SUNION %s"
    arguments = [:string, key.to_s]
    keys.each do |key|
      command << " %s"
      arguments += [:string, key.to_s]
    end
    send_and_return(command, *arguments)
  end

  def sunionstore(destination, key, *keys)
    command = "SUNIONSTORE %s %s"
    arguments = [:string, destination.to_s, :string, key.to_s]
    keys.each do |key|
      command << " %s"
      arguments += [:string, key.to_s]
    end
    send_and_return(command, *arguments)
  end

  def zadd(key, score, member)
    1 == send_and_return("ZADD %s %s %s", :string, key.to_s, :string, score.to_s, :string, member.to_s)
  end

  def zcard(key)
    send_and_return("ZCARD %s", :string, key.to_s)
  end

  def zcount(key, min, max)
    send_and_return("ZCOUNT %s %s %s", :string, key.to_s, :string, min.to_s, :string, max.to_s)
  end

  def zincrby(key, increment, member)
    send_and_return("ZINCRBY %s %s %s", :string, key.to_s, :string, increment.to_s, :string, member.to_s)
  end

  def zrange(key, start, stop, options={})
    if options[:scores]
      values_and_scores = send_and_return("ZRANGE %s %s %s WITHSCORES", :string, key.to_s, :string, start.to_i.to_s, :string, stop.to_i.to_s)
      values_and_scores.each_slice(2).to_a
    else
      send_and_return("ZRANGE %s %s %s", :string, key.to_s, :string, start.to_i.to_s, :string, stop.to_i.to_s)
    end
  end

  def zinterstore(destination, numkeys, key, *keys_and_options)
    options = keys_and_options.last.is_a?(Hash) ? keys_and_options.pop : {}

    command = "ZINTERSTORE %s %s %s"
    arguments = [:string, destination.to_s, :string, numkeys.to_i.to_s, :string, key.to_s]

    keys_and_options.each do |key|
      command << " %s"
      arguments += [:string, key.to_s]
    end

    if options[:weights] && !Array(options[:weights]).empty?
      command << " WEIGHTS"
      Array(options[:weights]).each do |weight|
        command << " %s"
        arguments += [:string, weight.to_s]
      end
    end

    case options[:aggregate]
    when :sum, :min, :max
      command << " AGGREGATE #{options[:aggregate].to_s.upcase}"
    end

    send_and_return(command, *arguments)
  end

  def version
    Gem::Version.new(info["redis_version"])
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
