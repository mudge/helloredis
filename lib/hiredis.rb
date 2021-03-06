require 'ffi'

module Hiredis
  extend FFI::Library

  # Be sure to set this to the location of your compiled libhiredis library.
  ffi_lib ['/usr/local/lib/libhiredis.dylib', '/usr/local/lib/libhiredis.so']

  class Context < FFI::ManagedStruct
    layout :fd, :int,
           :flags, :int,
           :obuf, :string,
           :err, :int,
           :errstr, :string,
           :fn, :pointer,
           :reader, :pointer

    def self.release(ptr)
      Hiredis.redisFree(ptr)
    end
  end

  class Reply < FFI::Struct
    OK = 0
    ERR = -1

    STRING = 1
    ARRAY = 2
    INTEGER = 3
    NIL = 4
    STATUS = 5
    ERROR = 6

    layout :type, :int,
           :integer, :long_long,
           :len, :int,
           :str, :string,
           :elements, :size_t,
           :element, :pointer
  end

  attach_function :redisConnect, [:string, :int], :pointer
  attach_function :redisConnectNonBlock, [:string, :int], :pointer
  attach_function :redisConnectUnix, [:string], :pointer
  attach_function :redisConnectUnixNonBlock, [:string], :pointer
  attach_function :redisCommand, [:pointer, :string, :varargs], :pointer
  attach_function :freeReplyObject, [:pointer], :void
  attach_function :redisFree, [:pointer], :void
  attach_function :redisCommandArgv, [:pointer, :int, :string, :size_t], :pointer
  attach_function :redisAppendCommand, [:pointer, :string, :varargs], :void
  attach_function :redisAppendCommandArgv, [:pointer, :int, :string, :size_t], :void
  attach_function :redisGetReply, [:pointer, :pointer], :int
end

