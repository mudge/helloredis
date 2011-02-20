require "spec_helper"

describe Helloredis do
  before(:each) do
    subject.select(5)
    subject.flushdb
  end

  it "has a context" do
    subject.context.should be_a(Hiredis::Context)
  end

  it "raises an exception if it can't connect" do
    expect { Helloredis.new("localhost", 666) }.to raise_error
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

  # # Redis 2.1.2+ feature.
  # describe "#persist" do
  #   it "returns true if the timeout was removed" do
  #     subject.set("foo", "bar")
  #     subject.expire("foo", 10)
  #     subject.persist("foo").should == true
  #   end

  #   it "returns false if there was no timeout" do
  #     subject.set("foo", "bar")
  #     subject.persist("foo").should == false
  #   end
  # end

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
end
