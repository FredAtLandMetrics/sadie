$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'sadie_storage_manager'

describe SadieStorageManager do
  
  before :each do
    @storagemgr = SadieStorageManager.new
  end
  
  it "should respond to register_storage_mechanism" do
    @storagemgr.respond_to?( 'register_storage_mechanism' ).should be_true
  end
  
  it "should respond to mechanism_is_registered?" do
    @storagemgr.respond_to?( 'mechanism_is_registered?' ).should be_true
  end
  
  it "should auto-register storage mechanism types" do
    
  end
  
end