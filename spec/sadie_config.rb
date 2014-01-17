$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'sadie_config'

describe SadieConfig do
  
  before :each do
    @conf = SadieConfig.new :filepath => File.join( File.dirname( __FILE__ ), '..', 'test', 'installations', 'nonfunctional_config_test', 'config', 'sadie.yml' )
  end
  
  it "should respond to is_set?" do
    @conf.respond_to?( 'is_set?' ).should be_true
  end
  
  it "should respond to get" do
    @conf.respond_to?( 'get' ).should be_true
  end
  
  it "should have a functional is_set? and it should use symbols, nbot strings for keys" do
    @conf.is_set?( :storage_mechanisms ).should be_true
    @conf.is_set?( 'storage_mechanisms' ).should be_false    
    @conf.is_set?( [:storage_mechanisms,:memory,:type] ).should be_true
  end
  
  it "should have a functional get" do
    @conf.get( [:storage_mechanisms,:memory,:type] ).should == 'local_memory'
  end
  
  it "should return the storage mechanisms in order" do
    mechs = @conf.get( :storage_mechanisms ).keys
    mechs[0].should == :memory
    mechs[1].should == :file
    mechs[2].should == :nfs
    mechs[3].should == :redis
    mechs[4].should == :remote1
    mechs[5].should == :remote2
    mechs[6].should == :remote3
  end
  
end
