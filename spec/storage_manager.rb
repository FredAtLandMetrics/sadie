$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'sadie_storage_manager'
require 'storage_mechanisms/memory'

describe SadieStorageManager do
  
  it "should be able to get and set using the memory storage mechanism" do
    
    storage = SadieStorageManager.new
    mech = SadieStorageMechanismMemory.new
    storage.register_storage_mechanism :memory, mech
    storage.set( :mechanism => :memory,
                 :keys => [ "simple.test" ],
                 :value => "test.value" )
    mech.get( "simple.test" ).should == "test.value"
  end
  
end
