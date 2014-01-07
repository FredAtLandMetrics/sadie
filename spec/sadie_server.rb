$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..')

require 'sadie_server'

class SadieServer
  def self.proc_args( argv=nil )
    { :framework_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation' ) }
  end
end

require 'bin/sadie_server'
require 'rack/test'

describe 'the sadie server app' do
  
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
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
    srv = SadieServer.new( SadieServer::proc_args )
    srv._config_hash.is_a?( Hash ).should be_true
  end
  
  it "should return the default storage mechanism config val as a symbol" do
    srv = SadieServer.new( SadieServer::proc_args )
    srv._config_hash['storage']['default_storage_mechanism'].is_a?(Symbol).should be_true
  end
  
end