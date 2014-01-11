$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..')


# require 'bin/sadie_server'

describe 'RedisBasedSadie' do
  
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
      def @server.get_session
        @sadie_session
      end
      @session = @server.get_session
    end
    
    after :each do
      system 'rm -rf /tmp/sadie-test-keystor'
    end
    
    it "should register a redis based storage mechanism when redis params exist" do
      def @session.get_storage_manager
        @storage_manager
      end
      @session.get_storage_manager.mechanism_is_registered?( :redis ).should be_true
    end
    
  end
  
end
