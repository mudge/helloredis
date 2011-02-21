This is an incomplete, experimental Ruby FFI interface to [Hiredis][0].

It exists mainly as a tool to teach me about [Ruby's FFI interface][1] and, as such,
the location of the `libhiredis` library is hard-coded into `hiredis.rb` as being
`/usr/local/lib`. If you want to tinker with this yourself, make sure to amend that
path as necessary.

Prerequisites
=============

* [Hiredis][0] installed to `/usr/local/lib`;
* If you want to experiment with a timeout when connecting to a Redis server, you
  will need a recent HEAD version of Hiredis with [timeout support][2].

Usage
=====

    require "helloredis"

    redis = Helloredis.new # defaults to connecting to 127.0.0.1:6379
    redis.set("foo", "bar")
    # => "OK"
    redis.get("foo")
    # => "bar"
    redis.lpush("mylist", "arnold")
    # => 1
    redis.lpush("mylist", "bob")
    # => 2
    redis.sort("mylist", :alpha => true, :order => :desc, :count => 1, :offset => 0)
    # => ["bob"]

See `spec/helloredis_spec.rb` for more usage information.

  [0]: https://github.com/antirez/hiredis
  [1]: https://github.com/ffi/ffi
  [2]: https://github.com/antirez/hiredis/compare/663d6d1258b3ef49178e...36f73fdb0c8756a53cb7
