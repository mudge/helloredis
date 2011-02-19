require "./helloredis"

describe Helloredis do
  before(:each) do
    subject.del("foo", "foo bar")
  end

  it "has a context" do
    subject.context.should be_a(Hiredis::Context)
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
end
