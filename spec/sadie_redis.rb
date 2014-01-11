$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..')

require 'rack/test'
require 'sadie_server'
require 'sadie_session'
require 'pp'

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
      def @server.get_session
        @sadie_session
      end
      sess = @server.get_session
      def sess.get_redis_port
        @redis_port
      end
      def sess.get_redis_host
        @redis_host
      end
      sess.get_redis_port.to_i.should == 6379
      sess.get_redis_host.should == 'localhost'
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
  
end