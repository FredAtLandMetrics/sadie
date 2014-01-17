$:.unshift File.join(File.dirname(__FILE__), '..', '..',  'lib')
require 'sadie_server'
require 'pp'

test_framework_dirpath = File.join( File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation')

describe SadieServer do
  
  describe '#proc_args' do
    
    it "should accept a framework-dirpath arg" do
      
      result = SadieServer::proc_args ["--framework-dirpath=#{test_framework_dirpath}"]
      result.should_not be_nil
      result.is_a?( Hash ).should be_true
      result.has_key?( :framework_dirpath ).should be_true
      result[:framework_dirpath].should == test_framework_dirpath
      
    end
    
  end
  
  describe "#initialize" do
    
    it "should store the framework dirpath" do
      
      serv = SadieServer.new( SadieServer::proc_args( ["--framework-dirpath=#{test_framework_dirpath}"] ) )
      serv.framework_dirpath.should == test_framework_dirpath
      
    end
    
  end
  
end