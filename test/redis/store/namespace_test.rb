require 'test_helper'

describe "Redis::Store::Namespace" do
  def setup
    @namespace = "theplaylist"
    @store  = Redis::Store.new :namespace => @namespace, :marshalling => false # TODO remove mashalling option
    @client = @store.instance_variable_get(:@client)
    @rabbit = "bunny"
    @default_store = Redis::Store.new
    @other_store = Redis::Store.new :namespace => 'other'
  end

  def teardown
    @store.flushdb
    @store.quit

    @default_store.flushdb
    @default_store.quit

    @other_store.flushdb
    @other_store.quit
  end

  it "only decorates instances that need to be namespaced" do
    store  = Redis::Store.new
    client = store.instance_variable_get(:@client)
    client.expects(:call).with([:get, "rabbit"])
    store.get("rabbit")
  end

  it "doesn't namespace a key which is already namespaced" do
    @store.send(:interpolate, "#{@namespace}:rabbit").must_equal("#{@namespace}:rabbit")
  end

  it "should only delete namespaced keys" do
    @default_store.set 'abc', 'cba'
    @store.set 'def', 'fed'

    @store.flushdb
    @store.get('def').must_equal(nil)
    @default_store.get('abc').must_equal('cba')
  end

  it "should not try to delete missing namespaced keys" do
    empty_store = Redis::Store.new :namespace => 'empty'
    empty_store.flushdb
    empty_store.keys.must_be_empty
  end

  it "namespaces setex and ttl" do
    @store.flushdb
    @other_store.flushdb

    @store.setex('foo', 30, 'bar')
    @store.ttl('foo').must_be_close_to(30)
    @store.get('foo').must_equal('bar')

    @other_store.ttl('foo').must_equal(-2)
    @other_store.get('foo').must_be_nil
  end

  describe 'method calls' do
    let(:store){Redis::Store.new :namespace => @namespace, :marshalling => false}
    let(:client){store.instance_variable_get(:@client)}

    it "should namespace get" do
       client.expects(:call).with([:get, "#{@namespace}:rabbit"]).once
       store.get("rabbit")
    end

    it "should namespace set" do
       client.expects(:call).with([:set, "#{@namespace}:rabbit", @rabbit])
       store.set "rabbit", @rabbit
    end

    it "should namespace setnx" do
       client.expects(:call).with([:setnx, "#{@namespace}:rabbit", @rabbit])
       store.setnx "rabbit", @rabbit
    end

    it "should namespace del with single key" do
       client.expects(:call).with([:del, "#{@namespace}:rabbit"])
       store.del "rabbit"
    end

    it "should namespace del with multiple keys" do
       client.expects(:call).with([:del, "#{@namespace}:rabbit", "#{@namespace}:white_rabbit"])
       store.del "rabbit", "white_rabbit"
    end

    it "should namespace keys" do
       store.set "rabbit", @rabbit
       store.keys("rabb*").must_equal [ "rabbit" ]
    end

    it "should namespace exists" do
       client.expects(:call).with([:exists, "#{@namespace}:rabbit"])
       store.exists "rabbit"
    end

    it "should namespace incrby" do
       client.expects(:call).with([:incrby, "#{@namespace}:counter", 1])
       store.incrby "counter", 1
    end

    it "should namespace decrby" do
       client.expects(:call).with([:decrby, "#{@namespace}:counter", 1])
       store.decrby "counter", 1
    end

    it "should namespace mget" do
       client.expects(:call).with([:mget, "#{@namespace}:rabbit", "#{@namespace}:white_rabbit"])
       store.mget "rabbit", "white_rabbit"
    end

    it "should namespace expire" do
       client.expects(:call).with([:expire, "#{@namespace}:rabbit", 60]).once
       store.expire("rabbit",60)
    end

    it "should namespace ttl" do
       client.expects(:call).with([:ttl, "#{@namespace}:rabbit"]).once
       store.ttl("rabbit")
    end
  end
end
