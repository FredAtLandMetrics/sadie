$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
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
    def @session.in_expire_schedule?( key )
      ( ! @expire_schedule.values.index(key).nil? )
    end
    
    @session.get("test.expires.nsecs").should == "testval"
    @session.in_expire_schedule?("test.expires.nsecs").should be true
  end
  
  it "should expire keys using _expire_pass" do
    
    def @session.run_expiry_pass
      _expiry_pass
    end
    @session.stub(:_current_time).and_return(2,5,8,11,14)
    @session.stub(:_expiry_loop).and_return(false)
    @session.get("test.expires.nsecs").should == "testval"
    @session.has_key?("test.expires.nsecs", :include_primers => false).should be_true
    @session.run_expiry_pass
    @session.has_key?("test.expires.nsecs", :include_primers => false).should be_false
  end
  
  it "should refresh keys" do
    
    def @session.run_refresh_pass
      _refresh_pass
    end
    @session.stub(:_current_time).and_return(2,5,8,11,14)
    @session.stub(:_refresh_loop).and_return(false)
    @session.get("test.refresh").should == "refresh"
    @session.run_refresh_pass
    @session.get("test.refresh").should == "rrefresh"
  end
  
  it "should set the default storage mechanism" do
   def @session.get_default_storage_mechanism
      @default_storage_mechanism
    end
    @session.get_default_storage_mechanism.should == :memory
    @session_default_file = SadieSession.new(
      :primers_dirpath => File.join( File.dirname( __FILE__ ), '..','test','v2','test_installation','primers' ),
      :default_storage_mechanism => :file)
    def @session_default_file.get_default_storage_mechanism
      @default_storage_mechanism
    end
    @session_default_file.get_default_storage_mechanism.should == :file
  end
  
  it "should initialize the file storage mechanism with the key storage dirpath set in init params" do
    def @session.storagemgr
      @storage_manager
    end
    mgr = @session.storagemgr
    def mgr.getfilemech
      @mechanisms[:file]
    end
    filemech = mgr.getfilemech
    filemech.key_storage_dirpath.should == '/tmp/sadie-test-keystor'
  end
  
  it "should store keys in different storage mechanisms" do
    def @session.detect_storage_mechanism(key)
      @storage_manager.where_key?( key )
    end
    @session.set('key1','val1',:mechanism => :memory)
    @session.set('key2','val2',:mechanism => :file)
    @session.detect_storage_mechanism('key1').should == :memory
    @session.detect_storage_mechanism('key2').should == :file
  end
  
  it "should be possible for primer files to choose the storage mechanism" do
    def @session.detect_storage_mechanism(key)
      @storage_manager.where_key?( key )
    end
    val_mem = @session.get("minimal.primer")
    val_file = @session.get("minimal.primer.file")
    val_mem.should == "testval"
    val_file.should == "testval_file"
    @session.detect_storage_mechanism("minimal.primer").should == :memory
    @session.detect_storage_mechanism("minimal.primer.file").should == :file
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