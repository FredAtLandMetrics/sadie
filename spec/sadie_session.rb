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
  
#   it "should read primers in subdirectories" do
#   end
  
end