require 'storage/memory'
describe SadieStorageMechanismMemory do
  
  before :each do
    @mech = SadieStorageMechanismMemory.new
  end
  it "should successfully return a set value" do
    @mech.set 'somekey.test','some_value'
    @mech.get( 'somekey.test' ).should == 'some_value'
    
  end
  
  it "should have a functional has_key? method" do
    @mech.has_key?( "somekey.test" ).should be_false
    @mech.set 'somekey.test','some_value'
    @mech.has_key?( "somekey.test" ).should be_true
  end
  
  it "should have a functional unset method" do
    @mech.set 'somekey.test','some_value'
    @mech.has_key?( "somekey.test" ).should be_true
    @mech.unset 'somekey.test'
    @mech.has_key?( "somekey.test" ).should be_false
    
  end
  
  it "should return the same metadata that was given to it" do
    metadata_to_give = {
      :type => :string,
      :awesomeness_level => :excrutiatingly
    }
    metadata_to_test = {
      :type => :string,
      :awesomeness_level => :excrutiatingly
    }
    wrong_metadata_to_test = {
      :type => :integer,
      :awesomeness_level => :excrutiatingly
    }
    @mech.set 'somekey.test','some_value', :metadata => metadata_to_give
    fetched_meta = @mech.metadata( 'somekey.test' )
    ( fetched_meta == metadata_to_test ).should be_true
    ( fetched_meta == wrong_metadata_to_test ).should be_false
  end
  
end