$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'primer'
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
# require 'sadie_storage_manager'
# require 'storage_mechanisms/memory'
require 'sadie_session'
require 'pp'

describe Primer do
  
  it "should default to the memory storage mechanism" do
    p = Primer.new
    p.storage_mechanism.should == :memory
  end
  
  it  "should be able to successfully set using a storage manager" do
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    p = Primer.new( :session => session )
    p.prime [ "simple.test"] do
      p.assign [ "simple.test" ] do
        p.set( "simple.value" )
      end
    end
    session.get( "simple.test" ).should == "simple.value"
  end
  
  it "should not allow assignment for keys not mentioned in the prime directive" do
    expect {
      session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
#       storage = SadieStorageManager.new
#       mech = SadieStorageMechanismMemory.new
#       storage.register_storage_mechanism :memory, mech
      p = Primer.new( :session => session )
      p.prime [ "simple.test"] do
        p.assign [ "simple.other" ]
      end
    }.to raise_error
    
  end
  
  it "should not allow set for keys not mentioned in the assign directive" do
    expect {
      session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
      p = Primer.new( :session => session )
      p.prime [ "simple.test"] do
        p.assign [ "simple.test" ] do
          p.set ["simple.other"], "someval"
        end
      end
    }.to raise_error
  end
  
  it "should be ok to use strings instead of arrays for prime" do
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    p = Primer.new( :session => session )
    p.prime "simple.test" do
      p.assign [ "simple.test" ] do
        p.set "someval"
      end
    end
    session.get("simple.test").should == "someval"
  end
  
  it "should be ok to use strings instead of arrays for assign" do
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    p = Primer.new( :session => session )
    p.prime ["simple.test"] do
      p.assign "simple.test" do
        p.set "someval"
      end
    end
    session.get("simple.test").should == "someval"
  end
  
  it "should be ok to use strings instead of arrays for set" do
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    p = Primer.new( :session => session )
    p.prime ["simple.test"] do
      p.assign "simple.test" do
        p.set "simple.test","someval"
      end
    end
    session.get("simple.test").should == "someval"
  end
  
  it "should successfully load a primer file using decorate method" do
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    p = Primer.new( :session => session )
    p.decorate( File.join(File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation', 'primers', 'minimal.rb') )
    session.get( "minimal.primer" ).should == "testval"
  end
  
  it "should successfully execute before each clauses" do
    
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    p = Primer.new( :session => session )
    def p.get_r
      @r
    end
    p.decorate( File.join(File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation', 'primers', 'test_before_each.rb') )
    session.get( "test.var1" ).should == "val1"
    session.get( "test.var2" ).should == "val2"
    r= p.get_r
    r.has_key?("test.var1").should be_true
    r.has_key?("test.var2").should be_true
    r["test.var1"].should == 1
    r["test.var2"].should == 1
  end
  
  it "should successfully execute before key clauses" do
    
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    p = Primer.new( :session => session )
    def p.get_r
      @r
    end
    p.decorate( File.join(File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation', 'primers', 'test_before_key.rb') )
    session.get( "test.var1" ).should == "val1"
    session.get( "test.var2" ).should == "val2"
    r= p.get_r
    r.has_key?("test.var1").should be_true
    r.has_key?("test.var2").should be_false
    r["test.var1"].should == 1
  end
  
  it "should successfully execute after each clauses" do
    
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    p = Primer.new( :session => session )
    def p.get_r
      @r
    end
    p.decorate( File.join(File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation', 'primers', 'test_after_each.rb') )
    session.get( "test.var1" ).should == "val1"
    session.get( "test.var2" ).should == "val2"
    r= p.get_r
    r.has_key?("test.var1").should be_true
    r.has_key?("test.var2").should be_true
    r["test.var1"].should == "val1"
    r["test.var2"].should == "val2"
  end
  
  it "should successfully execute after key clauses" do
    
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    p = Primer.new( :session => session )
    def p.get_r
      @r
    end
    p.decorate( File.join(File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation', 'primers', 'test_after_key.rb') )
    session.get( "test.var1" ).should == "val1"
    session.get( "test.var2" ).should == "val2"
    r= p.get_r
    r.has_key?("test.var1").should be_true
    r.has_key?("test.var2").should be_false
    r["test.var1"].should == "val1"
  end
  
  
end