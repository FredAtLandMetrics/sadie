require 'storage/memory'
describe SadieStorageMechanismMemory do
  
  it "should successfully return a set value" do
    
    mech = SadieStorageMechanismMemory.new
    mech.set 'somekey.test','some_value'
    mech.get( 'somekey.test' ).should == 'some_value'
    
  end
  
  it "should have a functional has_key? method" do
    mech = SadieStorageMechanismMemory.new
    mech.has_key?( "somekey.test" ).should be_false
    mech.set 'somekey.test','some_value'
    mech.has_key?( "somekey.test" ).should be_true
  end
  
  it "should have a functional unset method" do
    mech = SadieStorageMechanismMemory.new
    mech.set 'somekey.test','some_value'
    mech.has_key?( "somekey.test" ).should be_true
    mech.unset 'somekey.test'
    mech.has_key?( "somekey.test" ).should be_false
    
  end
  
end