$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'primer'
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'sadie_storage_manager'
require 'storage_mechanisms/memory'
require 'pp'

describe Primer do
  
  it "should default to the memory storage mechanism" do
    p = Primer.new
    p.storage_mechanism.should == :memory
  end
  
  it  "should be able to successfully set using a storage manager" do
    storage = SadieStorageManager.new
    mech = SadieStorageMechanismMemory.new
    storage.register_storage_mechanism :memory, mech
    p = Primer.new( :storage_manager => storage )
    p.assign [ "simple.test" ] do
      p.set( "simple.value" )
    end
    mech.get( "simple.test" ).should == "simple.value"
  end
  
  it "should successfully load a primer file using decorate method" do
    storage = SadieStorageManager.new
    mech = SadieStorageMechanismMemory.new
    storage.register_storage_mechanism :memory, mech
    p = Primer.new( :storage_manager => storage )
    p.decorate( File.join(File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation', 'primers', 'minimal.rb') )
    mech.get( "minimal.primer" ).should == "testval"
  end
  
end