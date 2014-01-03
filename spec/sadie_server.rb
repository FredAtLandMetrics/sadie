$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..')

require 'sadie_server'

class SadieServer
  def self.proc_args( argv )
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
end