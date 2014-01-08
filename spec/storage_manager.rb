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
  
  it "should report a mechanism is registered after it has been registered" do
    storage = SadieStorageManager.new
    mech = SadieStorageMechanismMemory.new
    storage.register_storage_mechanism :memory, mech
    storage.mechanism_is_registered?( :memory ).should be_true
  end
  
  it "should have a functional has_key? method" do
    storage = SadieStorageManager.new
    mech = SadieStorageMechanismMemory.new
    storage.register_storage_mechanism :memory, mech
    storage.has_key?( "test.key" ).should be_false
    storage.set( :keys => ["test.key"],
                 :value => "test.value",
                 :mechanism => :memory )
    storage.has_key?( "test.key" ).should be_true
  end
  
  it "should have a functional get method" do
    storage = SadieStorageManager.new
    mech = SadieStorageMechanismMemory.new
    storage.register_storage_mechanism :memory, mech
    storage.set( :keys => ["test.key"],
                 :value => "test.value",
                 :mechanism => :memory )
    storage.get( "test.key" ).should == "test.value"
  end
  
  it "should have a functional unset method" do
    storage = SadieStorageManager.new
    mech = SadieStorageMechanismMemory.new
    storage.register_storage_mechanism :memory, mech
    storage.set( :keys => ["test.key"],
                 :value => "test.value",
                 :mechanism => :memory )
    storage.has_key?( "test.key" ).should be_true
    storage.unset "test.key"
    storage.has_key?( "test.key" ).should be_false
  end
  
end
