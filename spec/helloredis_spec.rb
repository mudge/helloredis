require "spec_helper"
require "rubygems/version"

describe Helloredis do
  before(:each) do
    subject.select(5)
    subject.flushdb
  end

  it "has a context" do
    subject.context.should be_a(Hiredis::Context)
  end

  it "raises an exception if it can't connect" do
    expect { Helloredis.new(:host => "localhost", :port => 666) }.to raise_error
    expect { Helloredis.new(:path => "/fake.redis") }.to raise_error
  end

  describe "#version" do
    it "returns a Gem::Version" do
      subject.version.should be_a(Gem::Version)
    end
  end

  describe "#set" do
    it "returns OK when there are no errors" do
      subject.set("foo", "bar").should == "OK"
    end

    it "is aliased to []=" do
      subject["foo"] = "bar"
      subject.get("foo").should == "bar"
    end

    it "allows keys with spaces" do
      subject.set("foo bar", "bar").should == "OK"
    end
  end

  describe "#get" do
    it "returns the value" do
      subject.set("foo", "bar")
      subject.get("foo").should == "bar"
    end

    it "is aliased to []" do
      subject.set("foo", "bar")
      subject["foo"].should == "bar"
    end

    it "allows keys with spaces" do
      subject.set("foo bar", "bar")
      subject.get("foo bar").should == "bar"
    end
  end

  describe "#del" do
    it "returns the number of keys deleted" do
      subject.set("foo", "bar")
      subject.del("foo").should == 1
    end
  end

  describe "#append" do
    it "returns the length of the new string" do
      subject.set("foo", "bar")
      subject.append("foo", "bar").should == 6
    end
  end

  describe "#exists" do
    it "returns true if the key exists" do
      subject.set("foo", "bar")
      subject.exists("foo").should == true
    end

    it "returns false if the key does not exist" do
      subject.exists("foo").should == false
    end

    it "is aliased to exists?" do
      subject.exists?("foo").should == false
    end
  end

  describe "#ping" do
    it "returns PONG" do
      subject.ping.should == "PONG"
    end
  end

  describe "#expire" do
    it "returns true for existing keys" do
      subject.set("foo", "bar")
      subject.expire("foo", 10).should == true
    end

    it "returns false for non-existent keys" do
      subject.expire("foo", 10).should == false
    end
  end

  describe "#expireat" do
    it "returns true for existing keys" do
      subject.set("foo", "bar")
      subject.expireat("foo", 1293840000).should == true
    end

    it "returns false for non-existent keys" do
      subject.expireat("foo", 1129384000).should == false
    end

    it "accepts time objects" do
      subject.set("foo", "bar")
      subject.expireat("foo", Time.mktime(2000, 1, 1, 0, 0, 0)).should == true
    end
  end

  describe "#keys" do
    it "returns an array of keys" do
      subject.set("foo1", "bar")
      subject.set("foo2", "bar")
      subject.set("foo3", "bar")
      subject.keys("foo*").sort.should == ["foo1", "foo2", "foo3"]
    end
  end

  describe "#select" do
    it "returns OK" do
      subject.select(1).should == "OK"
    end
  end

  describe "#move" do
    before(:each) do
      subject.select(6)
      subject.del("foo")
      subject.select(5)
    end

    it "returns true if a key was moved" do
      subject.set("foo", "bar")
      subject.move("foo", 6).should == true
    end

    it "returns false if a key was not moved" do
      subject.move("foo", 6).should == false
    end
  end

  if REDIS_VERSION > Gem::Version.new("2.1.2")
    describe "#persist" do
      it "returns true if the timeout was removed" do
        subject.set("foo", "bar")
        subject.expire("foo", 10)
        subject.persist("foo").should == true
      end

      it "returns false if there was no timeout" do
        subject.set("foo", "bar")
        subject.persist("foo").should == false
      end
    end
  end

  describe "#info" do
    it "returns a hash of info" do
      subject.info.should be_a(Hash)
    end

    it "contains the redis version" do
      subject.info.should have_key("redis_version")
    end
  end

  describe "#randomkey" do
    it "returns a random key" do
      subject.set("foo", "bar")
      subject.randomkey.should be_a(String)
    end

    it "returns nil when there are no keys" do
      subject.randomkey.should be_nil
    end
  end

  describe "#rename" do
    it "returns OK on success" do
      subject.set("foo", "bar")
      subject.rename("foo", "woo").should == "OK"
    end

    it "raises an error when the key doesn't exist" do
      expect { subject.rename("foo", "woo") }.to raise_error
    end

    it "does not raise an error if the new key already exists" do
      subject.set("foo", "bar")
      subject.set("woo", "bar")
      expect { subject.rename("foo", "woo") }.not_to raise_error
    end
  end

  describe "#renamenx" do
    it "returns true if the key was renamed" do
      subject.set("foo", "bar")
      subject.renamenx("foo", "woo").should == true
    end

    it "returns false if the new key already exists" do
      subject.set("foo", "bar")
      subject.set("woo", "bar")
      subject.renamenx("foo", "woo").should == false
    end

    it "raises an error if the key doesn't exist" do
      expect { subject.renamenx("foo", "woo") }.to raise_error
    end
  end

  describe "#lpush" do
    it "returns the length of the list" do
      subject.lpush("foo", "bar").should == 1
    end

    it "raises an error if the key exists and is not a list" do
      subject.set("foo", "bar")
      expect { subject.lpush("foo", "bar") }.to raise_error
    end
  end

  if REDIS_VERSION >= Gem::Version.new("2.1.1")
    describe "#lpushx" do
      it "returns the length of the list" do
        subject.lpush("mylist", "World")
        subject.lpush("mylist", "Hello").should == 2
        subject.lpushx("myotherlist", "Hello").should == 0
      end
    end

    describe "#rpushx" do
      it "returns the length of the list" do
        subject.rpush("mylist", "World")
        subject.rpush("mylist", "Hello").should == 2
        subject.rpushx("myotherlist", "Hello").should == 0
      end
    end
  end

  describe "#sort" do
    it "returns a sorted list in the simplest form" do
      subject.lpush("foo", 3)
      subject.lpush("foo", 1)
      subject.lpush("foo", 2)
      subject.sort("foo").should == ["1", "2", "3"]
    end

    it "can return a sorted list in descending order" do
      subject.lpush("foo", 3)
      subject.lpush("foo", 1)
      subject.lpush("foo", 2)
      subject.sort("foo", :order => :desc).should == ["3", "2", "1"]
    end

    it "can sort alphabetically" do
      subject.lpush("foo", "c")
      subject.lpush("foo", "a")
      subject.lpush("foo", "b")
      subject.sort("foo", :alpha => true).should == ["a", "b", "c"]
    end

    it "can sort alphabetically in reverse" do
      subject.lpush("foo", "c")
      subject.lpush("foo", "a")
      subject.lpush("foo", "b")
      subject.sort("foo", :alpha => true, :order => :desc).should == ["c", "b", "a"]
    end

    it "can limit sorting" do
      subject.lpush("foo", 3)
      subject.lpush("foo", 1)
      subject.lpush("foo", 2)
      subject.sort("foo", :count => 2, :offset => 0).should == ["1", "2"]
    end

    it "does defaults to offset 0 with only count" do
      subject.lpush("foo", 3)
      subject.lpush("foo", 1)
      subject.lpush("foo", 2)
      subject.sort("foo", :count => 2).should == ["1", "2"]
    end

    it "sorts by external keys" do
      subject.lpush("people", "mrnormal")
      subject.lpush("people", "mrfat")
      subject.lpush("people", "mrskinny")
      subject.set("weight_mrfat", 100)
      subject.set("weight_mrnormal", 75)
      subject.set("weight_mrskinny", 50)
      subject.sort("people", :by => "weight_*").should == ["mrskinny", "mrnormal", "mrfat"]
    end

    it "retrieves external keys" do
      subject.lpush("people", "mrnormal")
      subject.lpush("people", "mrfat")
      subject.lpush("people", "mrskinny")
      subject.set("weight_mrfat", 100)
      subject.set("weight_mrnormal", 75)
      subject.set("weight_mrskinny", 50)
      subject.set("name_mrfat", "Bob")
      subject.set("name_mrnormal", "Carl")
      subject.set("name_mrskinny", "Harry")
      subject.sort("people", :by => "weight_*", :get => "name_*").should == ["Harry", "Carl", "Bob"]
    end

    it "supports multiple GET options" do
      subject.lpush("people", "mrnormal")
      subject.lpush("people", "mrfat")
      subject.lpush("people", "mrskinny")
      subject.set("weight_mrfat", 100)
      subject.set("weight_mrnormal", 75)
      subject.set("weight_mrskinny", 50)
      subject.set("name_mrfat", "Bob")
      subject.set("name_mrnormal", "Carl")
      subject.set("name_mrskinny", "Harry")
      subject.sort("people", :by => "weight_*", :get => ["name_*", "weight_*"]).should == ["Harry", "50", "Carl", "75", "Bob", "100"]
    end

    it "can store the result in a key" do
      subject.lpush("foo", 3)
      subject.lpush("foo", 1)
      subject.lpush("foo", 2)
      subject.sort("foo", :store => "sorted_foo")
      subject.lrange("sorted_foo", 0, 2).should == ["1", "2", "3"]
    end
  end

  describe "#lrange" do
    it "returns part of a list" do
      subject.lpush("foo", 3)
      subject.lpush("foo", 2)
      subject.lpush("foo", 1)
      subject.lrange("foo", 0, 1).should == ["1", "2"]
    end
  end

  describe "#ttl" do
    it "returns the remaining time to live of a key" do
      subject.set("foo", "bar")
      subject.expire("foo", 10)
      subject.ttl("foo").should == 10
    end

    it "returns -1 when the key does not exist" do
      subject.ttl("foo").should == -1
    end
  end

  describe "#type" do
    it "returns the type of the value stored at key" do
      subject.set("foo", "bar")
      subject.lpush("woo", "bar")
      subject.type("foo").should == "string"
      subject.type("woo").should == "list"
    end
  end

  describe "#decr" do
    it "returns the new integer value of the key" do
      subject.set("foo", 10)
      subject.decr("foo").should == 9
    end
  end

  describe "#decrby" do
    it "returns the new integer value of the key" do
      subject.set("foo", 10)
      subject.decrby("foo", 5).should == 5
    end
  end

  if REDIS_VERSION >= Gem::Version.new("2.1.8")
    describe "#getbit" do
      it "returns the bit value stored at offset" do
        subject.setbit("key", 7, 1)
        subject.getbit("key", 0).should == 0
        subject.getbit("key", 7).should == 1
        subject.getbit("key", 100).should == 0
      end
    end

    describe "#setbit" do
      it "returns the original bit value stored at offset" do
        subject.setbit("key", 7, 1).should == 0
        subject.setbit("key", 7, 0).should == 1
        subject.get("key").should == ""
      end
    end
  end

  if REDIS_VERSION <= Gem::Version.new("2.1")
    describe "#substr" do
      it "returns the substring of the string value stored at key" do
        subject.set("foo", "This is a string")
        subject.substr("foo", 0, 3).should == "This"
        subject.substr("foo", -3, -1).should == "ing"
      end
    end
  else
    describe "#getrange" do
      it "returns the substring of the string value stored at key" do
        subject.set("foo", "This is a string")
        subject.getrange("foo", 0, 3).should == "This"
        subject.getrange("foo", -3, -1).should == "ing"
      end
    end
  end

  if REDIS_VERSION >= Gem::Version.new("2.1.8")
    describe "#setrange" do
      it "returns the length of the string after it was modified" do
        subject.set("key1", "Hello World")
        subject.setrange("key1", 6, "Redis").should == 11
        subject.get("key1").should == "Hello Redis"
      end
    end
  end

  if REDIS_VERSION >= Gem::Version.new("2.1.2")
    describe "#strlen" do
      it "returns the length of the string" do
        subject.set("key", "Hello world")
        subject.strlen("key").should == 11
      end
    end
  end

  describe "#getset" do
    it "returns the old value of the key" do
      subject.set("foo", "bar")
      subject.getset("foo", "baz").should == "bar"
      subject.get("foo").should == "baz"
    end

    it "raises an error if the key is not a string" do
      subject.lpush("foo", "bar")
      expect { subject.getset("foo", "baz") }.to raise_error
    end
  end

  describe "#incr" do
    it "returns the new integer value of the key" do
      subject.set("foo", 10)
      subject.incr("foo").should == 11
    end
  end

  describe "#incrby" do
    it "returns the new integer value of the key" do
      subject.set("foo", 10)
      subject.incrby("foo", 5).should == 15
    end
  end

  describe "#mget" do
    it "returns a list of values" do
      subject.set("foo1", "bar1")
      subject.set("foo2", "bar2")
      subject.set("foo3", "bar3")
      subject.mget("foo1", "foo2", "foo3").should == ["bar1", "bar2", "bar3"]
    end

    it "requires at least one key" do
      expect { subject.mget }.to raise_error(ArgumentError)
    end
  end

  describe "#mset" do
    it "returns OK" do
      subject.mset("foo1" => "bar1", "foo2" => "bar2").should == "OK"
      subject.get("foo1").should == "bar1"
      subject.get("foo2").should == "bar2"
    end
  end

  describe "#msetnx" do
    it "returns true or false depending on whether the keys were set" do
      subject.msetnx("key1" => "Hello", "key2" => "there").should == true
      subject.msetnx("key2" => "there", "key3" => "world").should == false
      subject.mget("key1", "key2", "key3").should == ["Hello", "there", nil]
    end
  end

  describe "#setex" do
    it "returns OK on success" do
      subject.setex("foo", 10, "bar").should == "OK"
      subject.ttl("foo").should == 10
      subject.get("foo").should == "bar"
    end
  end

  describe "#setnx" do
    it "returns true if the key was set" do
      subject.setnx("foo", "bar").should == true
    end

    it "returns false if the key was not set" do
      subject.set("foo", "bar")
      subject.setnx("foo", "baz").should == false
    end
  end

  describe "#hset" do
    it "returns true if a new field was set" do
      subject.hset("hash", "foo", "bar").should == true
    end

    it "returns false if the field already exists and was updated" do
      subject.hset("hash", "foo", "bar")
      subject.hset("hash", "foo", "baz").should == false
    end
  end

  describe "#hget" do
    it "returns the value of the field" do
      subject.hset("hash", "foo", "bar")
      subject.hget("hash", "foo").should == "bar"
    end
  end

  describe "#hdel" do
    it "returns true if the field was present and is now removed" do
      subject.hset("hash", "foo", "bar")
      subject.hdel("hash", "foo").should == true
    end

    it "returns false if the field or hash does not exist" do
      subject.hdel("hash", "foo").should == false
    end
  end

  describe "#hexists" do
    it "returns true if the hash contains field" do
      subject.hset("hash", "foo", "bar")
      subject.hexists("hash", "foo").should == true
    end

    it "returns false if the hash does not contain field" do
      subject.hexists("hash", "foo").should == false
    end
  end

  describe "#hgetall" do
    it "returns a list of all fields and their values" do
      subject.hset("hash", "foo1", "bar1")
      subject.hset("hash", "foo2", "bar2")
      subject.hgetall("hash").should == {"foo1" => "bar1", "foo2" => "bar2"}
    end

    it "returns an empty hash if the key doesn't exist" do
      subject.hgetall("hash").should == {}
    end
  end

  describe "#hincrby" do
    it "returns the new integer value of the field" do
      subject.hset("hash", "foo", 5)
      subject.hincrby("hash", "foo", 1).should == 6
      subject.hincrby("hash", "foo", -1).should == 5
      subject.hincrby("hash", "foo", -10).should == -5
    end
  end

  describe "#hkeys" do
    it "returns the list of all fields in the hash" do
      subject.hset("hash", "foo1", "bar1")
      subject.hset("hash", "foo2", "bar2")
      subject.hkeys("hash").should == ["foo1", "foo2"]
    end
  end

  describe "#hlen" do
    it "returns the number of fields in the hash" do
      subject.hset("hash", "foo1", "bar1")
      subject.hset("hash", "foo2", "bar2")
      subject.hlen("hash").should == 2
    end
  end

  describe "#hmget" do
    it "returns a list of values for the given fields" do
      subject.hset("hash", "foo1", "bar1")
      subject.hset("hash", "foo2", "bar2")
      subject.hmget("hash", "foo1", "foo2", "foo3").should == ["bar1", "bar2", nil]
    end
  end

  describe "#hmset" do
    it "returns OK on success" do
      subject.hmset("hash", "foo1" => "bar1", "foo2" => "bar2").should == "OK"
      subject.hget("hash", "foo1").should == "bar1"
      subject.hget("hash", "foo2").should == "bar2"
    end
  end

  describe "#hsetnx" do
    it "returns true if the field was new and has been set" do
      subject.hsetnx("hash", "foo", "bar").should == true
    end

    it "returns false if the field already exists" do
      subject.hset("hash", "foo", "bar")
      subject.hsetnx("hash", "foo", "baz").should == false
      subject.hget("hash", "foo").should == "bar"
    end
  end

  describe "#hvals" do
    it "returns the list of values in a hash" do
      subject.hset("hash", "foo1", "bar1")
      subject.hset("hash", "foo2", "bar2")
      subject.hvals("hash").should == ["bar1", "bar2"]
    end

    it "returns an empty list if the key does not exist" do
      subject.hvals("hash").should == []
    end
  end

  describe "#rpush" do
    it "returns the length of the list" do
      subject.rpush("list", "foo").should == 1
    end
  end

  describe "#blpop" do
    it "returns the key and value" do
      subject.rpush("list2", "foo")
      subject.rpush("list3", "foo")
      subject.blpop("list1", "list2", "list3", 1).should == ["list2", "foo"]
    end
  end

  describe "#brpop" do
    it "returns the key and value" do
      subject.rpush("list2", "foo")
      subject.rpush("list2", "woo")
      subject.rpush("list3", "foo")
      subject.brpop("list1", "list2", "list3", 1).should == ["list2", "woo"]
    end
  end

  if REDIS_VERSION >= Gem::Version.new("2.1.7")
    describe "#brpoplpush" do
      it "returns the element being popped" do
        subject.rpush("list1", "one")
        subject.rpush("list1", "two")
        subject.rpush("list1", "three")
        subject.brpoplpush("list1", "list2", 1).should == "three"
      end
    end
  end

  describe "#lindex" do
    it "returns the element" do
      subject.rpush("foo", "bar")
      subject.rpush("foo", "baz")
      subject.lindex("foo", 0).should == "bar"
      subject.lindex("foo", -1).should == "baz"
    end
  end

  if REDIS_VERSION >= Gem::Version.new("2.1.1")
    describe "#linsert" do
      it "returns the length of the list after the insert" do
        subject.rpush("mylist", "Hello")
        subject.rpush("mylist", "World")
        subject.linsert("mylist", "There", :before => "World").should == 3
        subject.lrange("mylist", 0, -1).should == ["Hello", "There", "World"]
      end

      it "only accepts :before and :after" do
        subject.rpush("mylist", "Hello")
        subject.rpush("mylist", "World")
        expect { subject.linsert("mylist", "World", :between => "World") }.to raise_error
      end
    end
  end

  describe "#llen" do
    it "returns the length of the list" do
      subject.rpush("foo", "bar")
      subject.llen("foo").should == 1
    end
  end

  describe "#lpop" do
    it "returns the element" do
      subject.rpush("foo", "bar")
      subject.rpush("foo", "baz")
      subject.lpop("foo").should == "bar"
      subject.lrange("foo", 0, -1).should == ["baz"]
    end
  end

  describe "#lrem" do
    it "returns the number of removed elements" do
      subject.rpush("foo", "bar")
      subject.rpush("foo", "bar")
      subject.rpush("foo", "baz")
      subject.rpush("foo", "bar")
      subject.lrem("foo", -2, "bar").should == 2
      subject.lrange("foo", 0, -1).should == ["bar", "baz"]
    end
  end

  describe "#lset" do
    it "returns OK on success" do
      subject.rpush("foo", "one")
      subject.rpush("foo", "two")
      subject.rpush("foo", "three")
      subject.lset("foo", 0, "four").should == "OK"
      subject.lset("foo", -2, "five").should == "OK"
      subject.lrange("foo", 0, -1).should == ["four", "five", "three"]
    end
  end

  describe "#ltrim" do
    it "returns OK on success" do
      subject.rpush("foo", "one")
      subject.rpush("foo", "two")
      subject.rpush("foo", "three")
      subject.ltrim("foo", 1, -1).should == "OK"
      subject.lrange("foo", 0, -1).should == ["two", "three"]
    end
  end

  describe "#rpop" do
    it "returns the value of the last element" do
      subject.rpush("foo", "one")
      subject.rpush("foo", "two")
      subject.rpush("foo", "three")
      subject.rpop("foo").should == "three"
      subject.lrange("foo", 0, -1).should == ["one", "two"]
    end
  end

  describe "#rpoplpush" do
    it "returns the element being popped and pushed" do
      subject.rpush("foo", "one")
      subject.rpush("foo", "two")
      subject.rpush("foo", "three")
      subject.rpoplpush("foo", "foo2").should == "three"
      subject.lrange("foo", 0, -1).should == ["one", "two"]
      subject.lrange("foo2", 0, -1).should == ["three"]
    end
  end

  describe "#sadd" do
    it "returns true if the element was added" do
      subject.sadd("foo", "bar").should == true
    end

    it "returns false if the element was already a member" do
      subject.sadd("foo", "bar")
      subject.sadd("foo", "bar").should == false
    end
  end

  describe "#scard" do
    it "returns the number of elements in the set" do
      subject.sadd("foo", "bar")
      subject.scard("foo").should == 1
    end
  end

  describe "#sdiff" do
    it "returns the members of the resulting set" do
      subject.sadd("foo1", "a")
      subject.sadd("foo1", "b")
      subject.sadd("foo1", "c")
      subject.sadd("foo2", "c")
      subject.sadd("foo2", "d")
      subject.sadd("foo2", "e")
      subject.sdiff("foo1", "foo2").should == ["a", "b"]
    end
  end

  describe "#sdiffstore" do
    it "returns the number of elements in the set" do
      subject.sadd("foo1", "a")
      subject.sadd("foo1", "b")
      subject.sadd("foo1", "c")
      subject.sadd("foo2", "c")
      subject.sadd("foo2", "d")
      subject.sadd("foo2", "e")
      subject.sdiffstore("foodiff", "foo1", "foo2").should == 2
      subject.smembers("foodiff").should == ["a", "b"]
    end
  end

  describe "#smembers" do
    it "returns all elements of the set" do
      subject.sadd("foo", "bar")
      subject.sadd("foo", "baz")
      subject.smembers("foo").should == ["baz", "bar"]
    end
  end

  describe "#sinter" do
    it "returns the members of the resulting set" do
      subject.sadd("foo1", "a")
      subject.sadd("foo1", "b")
      subject.sadd("foo1", "c")
      subject.sadd("foo2", "c")
      subject.sadd("foo2", "d")
      subject.sadd("foo2", "e")
      subject.sinter("foo1", "foo2").should == ["c"]
    end
  end

  describe "#sinterstore" do
    it "returns the number of elements in the resulting set" do
      subject.sadd("foo1", "a")
      subject.sadd("foo1", "b")
      subject.sadd("foo1", "c")
      subject.sadd("foo2", "c")
      subject.sadd("foo2", "d")
      subject.sadd("foo2", "e")
      subject.sinterstore("foointer", "foo1", "foo2").should == 1
      subject.smembers("foointer").should == ["c"]
    end
  end

  describe "#sismember" do
    it "returns true if the element is a member of the set" do
      subject.sadd("foo", "bar")
      subject.sismember("foo", "bar").should == true
    end

    it "returns false if the element is not a member of the set" do
      subject.sismember("foo", "bar").should == false
    end
  end

  describe "#smove" do
    it "returns true if the element is moved" do
      subject.sadd("foo", "one")
      subject.sadd("foo", "two")
      subject.sadd("foo2", "three")
      subject.smove("foo", "foo2", "two").should == true
      subject.smembers("foo").should == ["one"]
      subject.smembers("foo2").should == ["three", "two"]
    end
  end

  describe "#spop" do
    it "returns the removed element" do
      subject.sadd("foo", "bar")
      subject.spop("foo").should == "bar"
      subject.smembers("foo").should == []
    end
  end

  describe "#srandmember" do
    it "returns a randomly selected element" do
      subject.sadd("foo", "bar")
      subject.srandmember("foo").should == "bar"
      subject.smembers("foo").should == ["bar"]
    end
  end

  describe "#srem" do
    it "returns true if the element was removed" do
      subject.sadd("foo", "one")
      subject.sadd("foo", "two")
      subject.srem("foo", "two").should == true
      subject.smembers("foo").should == ["one"]
    end

    it "returns false if the element was not a member of the set" do
      subject.sadd("foo", "one")
      subject.srem("foo", "two").should == false
    end
  end

  describe "#sunion" do
    it "returns the members of the resulting set" do
      subject.sadd("foo1", "a")
      subject.sadd("foo1", "b")
      subject.sadd("foo1", "c")
      subject.sadd("foo2", "c")
      subject.sadd("foo2", "d")
      subject.sadd("foo2", "e")
      subject.sunion("foo1", "foo2").should == ["c", "d", "a", "b", "e"]
    end
  end

  describe "#sunionstore" do
    it "returns the number of elements in the resulting set" do
      subject.sadd("foo1", "a")
      subject.sadd("foo1", "b")
      subject.sadd("foo1", "c")
      subject.sadd("foo2", "c")
      subject.sadd("foo2", "d")
      subject.sadd("foo2", "e")
      subject.sunionstore("foounion", "foo1", "foo2").should == 5
      subject.smembers("foounion").should == ["c", "d", "a", "b", "e"]
    end
  end

  describe "#zadd" do
    it "returns true if the element was added" do
      subject.zadd("foo", 1, "one").should == true
    end

    it "returns false if the element was already a member of the set" do
      subject.zadd("foo", 1, "one")
      subject.zadd("foo", 2, "one").should == false
    end
  end

  describe "#zcard" do
    it "returns the number of elements" do
      subject.zadd("foo", 1, "one")
      subject.zcard("foo").should == 1
    end
  end

  describe "#zcount" do
    it "returns the number of elements in the score range" do
      subject.zadd("foo", 1, "one")
      subject.zadd("foo", 2, "two")
      subject.zadd("foo", 3, "three")
      subject.zcount("foo", "-inf", "+inf").should == 3
      subject.zcount("foo", "(1", "3").should == 2
    end
  end

  describe "#zincrby" do
    it "returns the new score" do
      subject.zadd("foo", 1, "one")
      subject.zadd("foo", 2, "two")
      subject.zincrby("foo", 2, "one").should == "3"
    end
  end

  describe "#zrange" do
    it "returns a list of elements in the range" do
      subject.zadd("foo", 1, "one")
      subject.zadd("foo", 2, "two")
      subject.zadd("foo", 3, "three")
      subject.zrange("foo", 0, -1).should == ["one", "two", "three"]
    end

    it "returns a list of elements in the range with scores" do
      subject.zadd("foo", 1, "one")
      subject.zadd("foo", 2, "two")
      subject.zadd("foo", 3, "three")
      subject.zrange("foo", 0, -1, :scores => true).should == [["one", "1"], ["two", "2"], ["three", "3"]]
    end
  end

  describe "#zinterstore" do
    it "returns the number of elements in the resulting sorted set" do
      subject.zadd("zset1", 1, "one")
      subject.zadd("zset1", 2, "two")
      subject.zadd("zset2", 1, "one")
      subject.zadd("zset2", 2, "two")
      subject.zadd("zset2", 3, "three")
      subject.zinterstore("out", 2, "zset1", "zset2", :weights => [2, 3], :aggregate => :sum).should == 2
      subject.zrange("out", 0, -1, :scores => true).should == [["one", "5"], ["two", "10"]]
    end
  end
end
