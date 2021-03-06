$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'primer'
require 'sadie_session'
require 'pp'

describe Primer do
  
  before :each do
    system 'install -d /tmp/sadie-test-keystor'
    @session = SadieSession.new(
      :primers_dirpath =>
        File.join(
          File.dirname( __FILE__ ), '..','test','v2',
            'test_installation','primers'
        ),
      :file_storage_mechanism_dirpath => '/tmp/sadie-test-keystor'
    )
    @primer = Primer.new( :session => @session )
  end
  
  after :each do
    system 'rm -rf /tmp/sadie-test-keystor'
  end
  
  it "should default to the memory storage mechanism" do
    Primer.new.storage_mechanism.should == :memory
  end
  
  it  "should be able to successfully set using a storage manager" do
    @primer.prime [ "simple.test"] do
      @primer.assign [ "simple.test" ] do
        @primer.set( "simple.value" )
      end
    end
    @session.get( "simple.test" ).should == "simple.value"
  end
  
  it "should not allow assignment for keys not mentioned in the prime directive" do
    expect {
      @primer.prime [ "simple.test"] do
        @primer.assign [ "simple.other" ]
      end
    }.to raise_error
    
  end
  
  it "should not allow set for keys not mentioned in the assign directive" do
    expect {
      @primer.prime [ "simple.test"] do
        @primer.assign [ "simple.test" ] do
          @primer.set ["simple.other"], "someval"
        end
      end
    }.to raise_error
  end
  
  it "should be ok to use strings instead of arrays for prime" do
    @primer.prime "simple.test" do
      @primer.assign [ "simple.test" ] do
        @primer.set "someval"
      end
    end
    @session.get("simple.test").should == "someval"
  end
  
  it "should be ok to use strings instead of arrays for assign" do
    @primer.prime ["simple.test"] do
      @primer.assign "simple.test" do
        @primer.set "someval"
      end
    end
    @session.get("simple.test").should == "someval"
  end
  
  it "should be ok to use strings instead of arrays for set" do
    @primer.prime ["simple.test"] do
      @primer.assign "simple.test" do
        @primer.set "simple.test","someval"
      end
    end
    @session.get("simple.test").should == "someval"
  end
  
  it "should successfully load a primer file using decorate method" do
    @primer.decorate( File.join(File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation', 'primers', 'minimal.rb') )
    @session.get( "minimal.primer" ).should == "testval"
  end
  
  it "should successfully execute before each clauses" do
    
    @primer.decorate( File.join(File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation', 'primers', 'test_before_each.rb') )
    @session.get( "test.var1" ).should == "val1"
    @session.get( "test.var2" ).should == "val2"
    r = @primer.instance_variable_get(:@r)
    r.has_key?("test.var1").should be_true
    r.has_key?("test.var2").should be_true
    r["test.var1"].should == 1
    r["test.var2"].should == 1
  end
  
  it "should successfully execute before key clauses" do
    
    @primer.decorate( File.join(File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation', 'primers', 'test_before_key.rb') )
    @session.get( "test.var1" ).should == "val1"
    @session.get( "test.var2" ).should == "val2"
    r = @primer.instance_variable_get(:@r)
    r.has_key?("test.var1").should be_true
    r.has_key?("test.var2").should be_false
    r["test.var1"].should == 1
  end
  
  it "should successfully execute after each clauses" do
    
    @primer.decorate( File.join(File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation', 'primers', 'test_after_each.rb') )
    @session.get( "test.var1" ).should == "val1"
    @session.get( "test.var2" ).should == "val2"
    r = @primer.instance_variable_get(:@r)
    r.has_key?("test.var1").should be_true
    r.has_key?("test.var2").should be_true
    r["test.var1"].should == "val1"
    r["test.var2"].should == "val2"
  end
  
  it "should successfully execute after key clauses" do
    
    @primer.decorate( File.join(File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation', 'primers', 'test_after_key.rb') )
    @session.get( "test.var1" ).should == "val1"
    @session.get( "test.var2" ).should == "val2"
    r = @primer.instance_variable_get(:@r)
    r.has_key?("test.var1").should be_true
    r.has_key?("test.var2").should be_false
    r["test.var1"].should == "val1"
  end
  
  it "should set the refresh rate" do
    @primer.decorate( File.join(File.dirname(__FILE__), '..', 'test', 'v2', 'test_installation', 'primers', 'test_refresh.rb') )
    @primer.refresh_rate.should == 1
  end
  
  it "should be possible to set the default storage mechanism" do
    Primer.new( :session => @session ).storage_mechanism.should == :memory
    Primer.new( :session => @session, 
                :default_storage_mechanism => :file ).storage_mechanism.should == :file
  end
  
end