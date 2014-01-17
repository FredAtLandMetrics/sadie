$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'sadie_storage_manager'
require 'storage_mechanisms/memory'

describe SadieStorageManager do
  
  before :each do
    @storage = SadieStorageManager.new
    @mech = SadieStorageMechanismMemory.new
    @storage.register_storage_mechanism :memory, @mech
  end
  
  it "should be able to get and set using the memory storage mechanism" do
    @storage.set( :mechanism => :memory,
                  :keys => [ "simple.test" ],
                  :value => "test.value" )
    @mech.get( "simple.test" ).should == "test.value"
  end
  
  it "should report a mechanism is registered after it has been registered" do
    @storage.mechanism_is_registered?( :memory ).should be_true
  end
  
  it "should have a functional has_key? method" do
    @storage.has_key?( "test.key" ).should be_false
    @storage.set( :keys => ["test.key"],
                  :value => "test.value",
                  :mechanism => :memory )
    @storage.has_key?( "test.key" ).should be_true
  end
  
  it "should have a functional get method" do
    @storage.set( :keys => ["test.key"],
                  :value => "test.value",
                  :mechanism => :memory )
    @storage.get( "test.key" ).should == "test.value"
  end
  
  it "should have a functional unset method" do
    @storage.set( :keys => ["test.key"],
                  :value => "test.value",
                  :mechanism => :memory )
    @storage.has_key?( "test.key" ).should be_true
    @storage.unset "test.key"
    @storage.has_key?( "test.key" ).should be_false
  end
  
  it "should be able to set metadata for a key" do
    @storage.set( :keys => ["test.key1"],
                  :value => "test.value1",
                  :mechanism => :memory )
    test_metadata_hash = {  :type => :string,
                            :importance => :huge  }
    test_metadata_hash_right = {  :type => :string,
                                  :importance => :huge  }
    test_metadata_hash_wrong = {  :type => :string,
                                  :importance => :mild  }
    @storage.set( :keys => ["test.key2"],
                  :value => "test.value2",
                  :mechanism => :memory,
                  :metadata => test_metadata_hash )
    @storage.has_metadata?( "test.key1" ).should be_false
    @storage.has_metadata?( "test.key2" ).should be_true
    ( @storage.metadata( "test.key2" ) == test_metadata_hash_right ).should be_true
    ( @storage.metadata( "test.key2" ) == test_metadata_hash_wrong ).should be_false
  end    
  
end
