require 'storage/file'
describe SadieStorageMechanismFile do
  
  before :each do
    system 'install -d /tmp/stormech-file-test'
    @mech = SadieStorageMechanismFile.new( :key_storage_dirpath => '/tmp/stormech-file-test' )
  end
  
  after :each do
    system 'rm -rf /tmp/stormech-file-test'
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
  
end