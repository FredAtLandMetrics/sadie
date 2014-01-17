$:.unshift File.join(File.dirname(__FILE__), '..',  '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..')

require 'sadie_server'

class SadieServer
  def self.proc_args( argv=nil )
    { :framework_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','another_test_installation' ) }
  end
  
  def get_config_hash
    _config_hash
  end
end

require 'bin/sadie_server'
require 'rack/test'

describe 'the sadie server app' do
  
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
  
  it "returns the correct value" do
    get '/minimal.primer'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('testval')
  end
  
  it "updates via post" do
    fields = {
      :value => 'testval99'
    }
    post '/set.via.post', fields
    expect(last_response).to be_ok
    get '/set.via.post'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('testval99')
  end
  
  it "should return the config as a hash" do
    @server.get_config_hash.is_a?( Hash ).should be_true
  end
  
  it "should return the default storage mechanism config val as a symbol" do
    @server.get_config_hash['storage']['default_storage_mechanism'].is_a?(Symbol).should be_true
  end
  
  it "should initialize the session with the default storage mechanism" do
    sess = @server.instance_variable_get(:@sadie_session)
    sess.instance_variable_get(:@default_storage_mechanism).should == :file
  end
  
  it "should initialize the session with no session coordination" do
    sess = @server.instance_variable_get(:@sadie_session)
    sess.instance_variable_get(:@session_coordination).should == :none
  end
    
  
end