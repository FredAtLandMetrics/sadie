$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'timestamp_queue'
require 'sadie_session'
require 'pp'

describe SadieSession do
  
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
    @session_default_file = SadieSession.new(
      :primers_dirpath =>
        File.join(
          File.dirname( __FILE__ ), '..','test','v2',
            'test_installation','primers'
        ),
      :file_storage_mechanism_dirpath => '/tmp/sadie-test-keystor',
      :default_storage_mechanism => :file
    )
  end
  
  after :each do
    system 'rm -rf /tmp/sadie-test-keystor'
  end
  
  it "should be able to get and set" do
    @session.set('test.key','test.value')
    @session.get('test.key').should == 'test.value'
  end
  
  it "should register primers" do
    @session.primer_registered?("minimal.primer").should be_true
  end
  
  it "should not execute primer assign directives" do
    @session.has_key?("minimal.primer", :include_primers => false).should be_false
  end
  
  it "should be possible to _get_ registered keys" do
    @session.get("minimal.primer").should == "testval"    
  end
  
  it "should find primers in subdirectories" do
    @session.get("subdir.test").should == "testval"
  end
  
  it "should be possible to expire on get" do
    @session.get("test.expires.onget").should == "testval"
    @session.has_key?("test.expires.onget", :include_primers => false).should be_false
  end
  
  it "should put keys in the expire schedule" do
    
    expiry_queue_object = @session.instance_variable_get(:@expiry_queue)
    expiry_queue_rbtree = expiry_queue_object.instance_variable_get(:@queue)
    @session.get("test.expires.nsecs").should == "testval"
    expiry_queue_rbtree.values.index("test.expires.nsecs").nil?.should be_false
    
  end
  
  it "should expire keys using _expire_pass" do
    
    @session.stub(:_current_time).and_return(2,5,8,11,14)
    @session.stub(:_expiry_loop).and_return(false)
    @session.get("test.expires.nsecs").should == "testval"
    @session.has_key?("test.expires.nsecs", :include_primers => false).should be_true
    @session.send(:_expiry_pass) # exec private method _expiry_pass
    @session.has_key?("test.expires.nsecs", :include_primers => false).should be_false
    
  end
  
  it "should refresh keys" do
    
    @session.stub(:_current_time).and_return(2,5,8,11,14)
    @session.stub(:_refresh_loop).and_return(false)
    @session.get("test.refresh").should == "refresh"
    @session.send(:_refresh_pass) # exec private method _refresh_pass
    @session.get("test.refresh").should == "rrefresh"
    
  end
  
  it "should set the default storage mechanism" do
    
    @session.instance_variable_get(:@default_storage_mechanism).should == :memory
    @session_default_file = SadieSession.new(
      :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ),
      :default_storage_mechanism => :file
    )
    @session_default_file.instance_variable_get(:@default_storage_mechanism).should == :file
    
  end
  
  it "should initialize the file storage mechanism with the key storage dirpath set in init params" do

    mgr = @session.instance_variable_get(:@storage_manager)
    mechhash = mgr.instance_variable_get(:@mechanisms)
    filestoragemech = mechhash[:file]
    filestoragemech.key_storage_dirpath.should == '/tmp/sadie-test-keystor'
    
  end
  
  it "should store keys in different storage mechanisms" do
    @session.set('key1','val1',:mechanism => :memory)
    @session.set('key2','val2',:mechanism => :file)
    @session.instance_variable_get(:@storage_manager).where_key?('key1').should == :memory
    @session.instance_variable_get(:@storage_manager).where_key?('key2').should == :file
  end
  
  it "should be possible for primer files to choose the storage mechanism" do
    val_mem = @session.get("minimal.primer")
    val_file = @session.get("minimal.primer.file")
    val_mem.should == "testval"
    val_file.should == "testval_file"
    @session.instance_variable_get(:@storage_manager).where_key?('minimal.primer').should == :memory
    @session.instance_variable_get(:@storage_manager).where_key?('minimal.primer.file').should == :file
  end
  
  it "should be able to set and retrieve metadata" do
    test_metadata_hash = {  :type => :string,
                            :importance => :huge  }
    test_metadata_hash_right = {  :type => :string,
                                  :importance => :huge  }
    test_metadata_hash_wrong = {  :type => :string,
                                  :importance => :mild  }
    @session.set( "test.key1", "test.value1", :metadata => test_metadata_hash )
    @session.set( "test.key2", "test.value2" )
    @session.has_metadata?( "test.key1" ).should be_true
    @session.has_metadata?( "test.key2" ).should be_false
    ( @session.metadata( "test.key1" ) == test_metadata_hash_right ).should be_true
    ( @session.metadata( "test.key1" ) == test_metadata_hash_wrong ).should be_false
    
  end
  
  it "should not be possible to prime the same key more than once at the same time" do
    val = @session.get("wait.primary")
    sleep 1
    val = @session.get("wait.primary")
    ($max > 1).should be_false
  end
  
  # --- SLOW!
  if ENV.has_key?('SADIE_SESSION_TEST_TIMERS') && ENV['SADIE_SESSION_TEST_TIMERS'].to_i == 1
    
    it "should expire keys after specified time" do
      
      @session.get("test.expires.nsecs").should == "testval"
      @session.has_key?("test.expires.nsecs").should be_true
      sleep 2
      @session.has_key?("test.expires.nsecs").should be_false
    end
    
    it "should refresh keys after specified time" do
      
      @session.get("test.refresh").should == "refresh"
      sleep 2
      @session.get("test.refresh").should == "rrefresh"
    end
    
  end
  

end