$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..')

require 'rack/test'
require 'sadie_server'
require 'sadie_session'
require 'pp'
require 'redis_timestamp_queue'
require 'redis'

class SadieServer
  def self.proc_args( argv=nil )
    { :framework_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','redis_test_installation' ) }
  end
end

require 'bin/sadie_server'
  

describe 'RedisBasedSadie' do
  
  describe SadieServer do
    include Rack::Test::Methods
    
    def app
      Sinatra::Application
    end
    
    before :each do
      system 'install -d /tmp/sadie-test-keystor'
      @server = SadieServer.new( SadieServer::proc_args )
    end
    
    after :each do
      system 'rm -rf /tmp/sadie-test-keystor'
    end
    
    it "should initialize the session with the redis host and port" do
      sess = @server.instance_variable_get(:@sadie_session)
      sess.instance_variable_get(:@redis_port).to_i.should == 6379
      sess.instance_variable_get(:@redis_host).should == 'localhost'
    end
    
    it "should initialize the session with redis-based session coordination" do
      sess = @server.instance_variable_get(:@sadie_session)
      sess.instance_variable_get(:@session_coordination).should == :redis
    end
      
  end
  
  describe SadieSession do
    
    before :each do
      system 'install -d /tmp/sadie-test-keystor'
      @server = SadieServer.new( SadieServer::proc_args )
      @session = @server.instance_variable_get(:@sadie_session)
    end
    
    after :each do
      system 'rm -rf /tmp/sadie-test-keystor'
    end
    
    it "should register a redis based storage mechanism when redis params exist" do
      storage_mgr = @session.instance_variable_get(:@storage_manager)
      storage_mgr.mechanism_is_registered?( :redis ).should be_true
    end
    
    it "should init the expiry queue as a RedisTimestampQueue" do
      @session.instance_variable_get(:@expiry_queue).is_a?( RedisTimestampQueue ).should be_true
    end
    
    it "should init the refresh queue as a RedisTimestampQueue" do
      @session.instance_variable_get(:@refresh_queue).is_a?( RedisTimestampQueue ).should be_true
    end
  
  end
  
  describe SadieStorageMechanismRedis do
    before :each do
      system 'install -d /tmp/sadie-test-keystor'
      @server = SadieServer.new( SadieServer::proc_args )
      @session = @server.instance_variable_get(:@sadie_session)
      @storage_mgr = @session.instance_variable_get(:@storage_manager)
      @redis_storage_mechanism = @storage_mgr.instance_variable_get(:@mechanisms)[:redis]
      @redis_server = @redis_storage_mechanism.instance_variable_get(:@redis_server)
      @redis_server.flushall
    end
    
    after :each do
      system 'rm -rf /tmp/sadie-test-keystor'
    end
    
    it "should be able to get and set" do
      @redis_storage_mechanism.set("testkey","testval")
      @redis_storage_mechanism.get("testkey").should == "testval"
    end
    
    it "should have a functional has_key? method" do
      @redis_storage_mechanism.has_key?( "somekey.test" ).should be_false
      @redis_storage_mechanism.set 'somekey.test','some_value'
      @redis_storage_mechanism.has_key?( "somekey.test" ).should be_true
    end
    
    it "should have a functional unset method" do
      @redis_storage_mechanism.set 'somekey.test','some_value'
      @redis_storage_mechanism.has_key?( "somekey.test" ).should be_true
      @redis_storage_mechanism.unset 'somekey.test'
      @redis_storage_mechanism.has_key?( "somekey.test" ).should be_false
    end
    
    
    it "should return the same metadata that was given to it" do
      metadata_to_give = {
        :type => :string,
        :awesomeness_level => :excrutiatingly
      }
      metadata_to_test = {
        :type => :string,
        :awesomeness_level => :excrutiatingly
      }
      wrong_metadata_to_test = {
        :type => :integer,
        :awesomeness_level => :excrutiatingly
      }
      @redis_storage_mechanism.set 'somekey.test','some_value', :metadata => metadata_to_give
      fetched_meta = @redis_storage_mechanism.metadata( 'somekey.test' )
      ( fetched_meta == metadata_to_test ).should be_true
      ( fetched_meta == wrong_metadata_to_test ).should be_false
    end
    
  end
  
  describe RedisTimestampQueue do
    before :each do
      @tsq = RedisTimestampQueue.new( :host => 'localhost', :port => 6379, :handle => 'test' )
      @redis_server = @tsq.instance_variable_get(:@redis_server)
      @redis_server.flushall
    end
    
    it "should initialize the redis server connection" do
      @redis_server.nil?.should be_false
    end
    
    it "should set the port, host, and handle instance variables" do
      @tsq.instance_variable_get(:@host).should == 'localhost'
      @tsq.instance_variable_get(:@port).should == 6379
      @tsq.instance_variable_get(:@handle).should == 'test'
    end
    
    it "should store a key using the current time if one is not provided" do
      @tsq.stub(:_current_time).and_return(99)
      @tsq.insert( 'testkey' )
      rec = @tsq.find :first, :before => 100, :as => :hash
      rec[:key].should == 'testkey'
      rec[:timestamp].should == 99
    end
    
    it "should return a key if the as parameter is not provided" do
      @tsq.stub(:_current_time).and_return(99)
      @tsq.insert( 'testkey' )
      key = @tsq.find :first, :before => 100
      key.should == 'testkey'
    end
    
    it "should return an array of records using :all" do
      @tsq.stub(:_current_time).and_return(99,100,101,104)
      @tsq.insert( 'testkey1' )
      @tsq.insert( 'testkey2' )
      @tsq.insert( 'testkey3' )
      @tsq.insert( 'testkey4' )
      keys = @tsq.find :all, :before => 102
      keys.is_a?( Array ).should be_true
      keys.empty?.should be_false
      keys.length.should == 3
      keys[0].should == 'testkey1'
      keys[1].should == 'testkey2'
      keys[2].should == 'testkey3'
    end    
    
    it "should remove records from the queue" do
      @tsq.stub(:_current_time).and_return(99,100,101,104)
      @tsq.insert( 'testkey1' )
      @tsq.insert( 'testkey2' )
      @tsq.insert( 'testkey3' )
      @tsq.insert( 'testkey4' )
      keys = @tsq.find :all, :before => 102
      keys.is_a?( Array ).should be_true
      keys.empty?.should be_false
      keys = @tsq.find :all, :before => 102
      keys.nil?.should be_true
    end
  
  end
  
  describe 'Lock Manager in Redis Coordination Mode' do
    
    before :each do
      @redis_server = Redis.new( :host => 'localhost', :port => 6379 )
      @redis_server.flushall
      @lockmgr = LockManager.new( :mode => :redis_coordinated,
                                  :redis_host => 'localhost',
                                  :redis_port => 6379 )
    end
    
    it "should set proper instance variables when started with redis mode" do
      @lockmgr.instance_variable_get(:@mode).should == :redis_coordinated
      @lockmgr.instance_variable_get(:@redis_port).should == 6379
      @lockmgr.instance_variable_get(:@redis_host).should == 'localhost'
    end
    
    it "should properly protect critical sections with acquire and release" do
      @total = 0
      @max = 0
      t1 = Thread.new do
        @total += 1
        @max = @total if @total > @max
        sleep rand(3).to_i
        @total -= 1
      end
      t2 = Thread.new do
        @total += 1
        @max = @total if @total > @max
        sleep rand(3).to_i
        @total -= 1
      end
      t3 = Thread.new do
        @total += 1
        @max = @total if @total > @max
        sleep rand(3).to_i
        @total -= 1
      end
      sleep 5
      t1.join
      t2.join
      t3.join
      ( @max > 1 ).should be_true
      
      lockid = @lockmgr.create( :systype => 'test', :locktype => 'test' )
      @total = 0
      @max = 0
      t1 = Thread.new do
        3.times do
          unless @lockmgr.acquire( lockid ).nil?
            @total += 1
            @max = @total if @total > @max
            sleep rand(3).to_i
            @total -= 1
            @lockmgr.release( lockid )
          end
        end
      end
      t2 = Thread.new do
        3.times do
          unless @lockmgr.acquire( lockid ).nil?
            @total += 1
            @max = @total if @total > @max
            sleep rand(3).to_i
            @total -= 1
            @lockmgr.release( lockid )
          end
        end
      end
      t3 = Thread.new do
        3.times do
          unless @lockmgr.acquire( lockid ).nil?
            @total += 1
            @max = @total if @total > @max
            sleep rand(3).to_i
            @total -= 1
            @lockmgr.release( lockid )
          end
        end
      end
      sleep 5
      t1.join
      t2.join
      t3.join
      ( @max > 1 ).should be_false
    end
      
  end
  
end
