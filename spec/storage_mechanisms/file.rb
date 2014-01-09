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
  
  it "should create a file when set is called" do
    @mech.set 'somekey.test','some_value'
    File.exists?( File.join( '/tmp/stormech-file-test','somekey.test' ) ).should be_true
  end
  
  it "should delete a file when unset is called" do
    @mech.set 'somekey.test','some_value'
    File.exists?( File.join( '/tmp/stormech-file-test','somekey.test' ) ).should be_true
    @mech.unset 'somekey.test'
    File.exists?( File.join( '/tmp/stormech-file-test','somekey.test' ) ).should be_false
  end
  
  it "should write metadata to a file" do
    @mech.set 'somekey.test','some_value', :metadata => { :type => :string }
    File.exists?( File.join( '/tmp/stormech-file-test','somekey.test' ) ).should be_true
    File.exists?( File.join( '/tmp/stormech-file-test/.meta','somekey.test' ) ).should be_true
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
    @mech.set 'somekey.test','some_value', :metadata => metadata_to_give
    fetched_meta = @mech.metadata( 'somekey.test' )
    ( fetched_meta == metadata_to_test ).should be_true
  end
  
end