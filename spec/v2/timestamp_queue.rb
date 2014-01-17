$:.unshift File.join(File.dirname(__FILE__), '..', '..',  'lib')
require 'timestamp_queue'

describe TimestampQueue do
  
  before :each do
    @tsq = TimestampQueue.new
  end
  
  it "should store a key using the current time if one is not provided" do
    @tsq.stub(:_current_time).and_return(99)
    @tsq.insert( 'testkey' )
    rec = @tsq.find :first, :before => 100, :as => :hash
    rec[:key].should == 'testkey'
    rec[:timestamp].should == 99
  end
  
  it "should return a key if the as parameter is not provided" do
    @tsq.stub(:_current_time).and_return(99)
    @tsq.insert( 'testkey' )
    key = @tsq.find :first, :before => 100
    key.should == 'testkey'
  end
  
  it "should return an array of records using :all" do
    @tsq.stub(:_current_time).and_return(99,100,101,104)
    @tsq.insert( 'testkey1' )
    @tsq.insert( 'testkey2' )
    @tsq.insert( 'testkey3' )
    @tsq.insert( 'testkey4' )
    keys = @tsq.find :all, :before => 102
    keys.is_a?( Array ).should be_true
    keys.empty?.should be_false
    keys.length.should == 3
    keys[0].should == 'testkey1'
    keys[1].should == 'testkey2'
    keys[2].should == 'testkey3'
  end
  
  it "should remove records from the queue" do
    @tsq.stub(:_current_time).and_return(99,100,101,104)
    @tsq.insert( 'testkey1' )
    @tsq.insert( 'testkey2' )
    @tsq.insert( 'testkey3' )
    @tsq.insert( 'testkey4' )
    keys = @tsq.find :all, :before => 102
    keys.is_a?( Array ).should be_true
    keys.empty?.should be_false
    keys = @tsq.find :all, :before => 102
    keys.nil?.should be_true
  end
  
end