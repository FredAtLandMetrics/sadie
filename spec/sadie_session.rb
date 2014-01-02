$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'sadie_session'
require 'pp'
describe SadieSession do
  
  it "should be able to get and set" do
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    session.set('test.key','test.value')
    session.get('test.key').should == 'test.value'
  end
  
  it "should register primers" do
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    session.primer_registered?("minimal.primer").should be_true
  end
  
  it "should not execute primer assign directives" do
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    session.has_key?("minimal.primer").should be_false
  end
  
  it "should be possible to _get_ registered keys" do
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    session.get("minimal.primer").should == "testval"    
  end
  
  it "should find primers in subdirectories" do
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    session.get("subdir.test").should == "testval"
  end
  
  it "should be possible to expire on get" do
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    session.get("test.expires.onget").should == "testval"
    session.has_key?("test.expires.onget").should be_false
  end
  
  it "should put keys in the expire schedule" do
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    
    def session.in_expire_schedule?( key )
      ( ! @expire_schedule.values.index(key).nil? )
    end
    
    session.get("test.expires.nsecs").should == "testval"
    session.in_expire_schedule?("test.expires.nsecs").should be true
  end
  
  it "should expire keys using _expire_pass" do
    
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    def session.run_expiry_pass
      _expiry_pass
    end
    session.stub(:_current_time).and_return(2,5,8,11,14)
    session.stub(:_expiry_loop).and_return(false)
    session.get("test.expires.nsecs").should == "testval"
    session.has_key?("test.expires.nsecs").should be_true
    session.run_expiry_pass
    session.has_key?("test.expires.nsecs").should be_false
  end
  
  it "should expire keys after specified time" do
    
    session = SadieSession.new( :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ))
    session.get("test.expires.nsecs").should == "testval"
    session.has_key?("test.expires.nsecs").should be_true
    sleep 2
    session.has_key?("test.expires.nsecs").should be_false
  end

end