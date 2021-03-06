require "spec_helper"

describe Hiredis do
  describe "#redisConnect" do
    it "connects without error" do
      expect { Hiredis.redisConnect("127.0.0.1", 6379) }.not_to raise_error
    end

    it "has no error" do
      context_pointer = Hiredis.redisConnect("127.0.0.1", 6379)
      context = Hiredis::Context.new(context_pointer)
      context[:err].should == 0
    end

    it "has an error when there is an issue" do
      context_pointer = Hiredis.redisConnect("127.0.0.1", 666)
      context = Hiredis::Context.new(context_pointer)
      context[:err].should == 1
      context[:errstr].should_not be_empty
    end
  end

  context "with a successful connection" do
    let(:hiredis) { Hiredis.redisConnect("127.0.0.1", 6379) }

    before(:each) do
      Hiredis.redisCommand(hiredis, "DEL foo")
    end

    describe "#redisCommand" do
      it "works with SET and GET" do
        set_reply_pointer = Hiredis.redisCommand(hiredis, "SET foo bar")
        set_reply = Hiredis::Reply.new(set_reply_pointer)
        set_reply[:type].should == Hiredis::Reply::STATUS
        set_reply[:str].should == "OK"
        Hiredis.freeReplyObject(set_reply_pointer)

        get_reply_pointer = Hiredis.redisCommand(hiredis, "GET foo")
        get_reply = Hiredis::Reply.new(get_reply_pointer)
        get_reply[:type].should == Hiredis::Reply::STRING
        get_reply[:str].should == "bar"
        Hiredis.freeReplyObject(get_reply_pointer)
      end

      it "works with varargs" do
        set_reply_pointer = Hiredis.redisCommand(hiredis, "SET foo %s", :string, "bar")
        set_reply = Hiredis::Reply.new(set_reply_pointer)
        set_reply[:type].should == Hiredis::Reply::STATUS
        set_reply[:str].should == "OK"
        Hiredis.freeReplyObject(set_reply_pointer)
      end

      it "works with binary safe strings" do
        set_reply_pointer = Hiredis.redisCommand(hiredis, "SET foo %b", :string, "bar", :size_t, 3)
        set_reply = Hiredis::Reply.new(set_reply_pointer)
        set_reply[:type].should == Hiredis::Reply::STATUS
        set_reply[:str].should == "OK"
        Hiredis.freeReplyObject(set_reply_pointer)
      end
    end

    describe "#redisAppendCommand" do
      it "works with SET and GET" do
        reply_pointer = FFI::MemoryPointer.new(:pointer)
        Hiredis.redisAppendCommand(hiredis, "SET foo bar")
        Hiredis.redisAppendCommand(hiredis, "GET foo")
        Hiredis.redisGetReply(hiredis, reply_pointer).should == Hiredis::Reply::OK
        set_reply = Hiredis::Reply.new(reply_pointer.read_pointer)
        set_reply[:type].should == Hiredis::Reply::STATUS
        set_reply[:str].should == "OK"
        Hiredis.freeReplyObject(reply_pointer.read_pointer)

        reply_pointer = FFI::MemoryPointer.new(:pointer)
        Hiredis.redisGetReply(hiredis, reply_pointer).should == Hiredis::Reply::OK
        get_reply = Hiredis::Reply.new(reply_pointer.read_pointer)
        get_reply[:type].should == Hiredis::Reply::STRING
        get_reply[:str].should == "bar"
        Hiredis.freeReplyObject(reply_pointer.read_pointer)
      end
    end
  end
end
