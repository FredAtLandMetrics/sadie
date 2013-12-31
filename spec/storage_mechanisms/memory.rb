require 'storage/memory'
describe SadieStorageMechanismMemory do
  
  it "should successfully return a set value" do
    
    mech = SadieStorageMechanismMemory.new
    mech.set 'somekey.test','some_value'
    mech.get( 'somekey.test' ).should == 'some_value'
    
  end
  
end