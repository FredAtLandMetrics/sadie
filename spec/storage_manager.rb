$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'sadie_storage_manager'
require 'pp'
describe SadieStorageManager do
  
  before :each do
    @storagemgr = SadieStorageManager.new
  end
  
  it "(the class) should respond to register_mechanism_type" do
    @storagemgr.class.respond_to?( 'register_mechanism_type' ).should be_true
  end
  
  it "should respond to mechanism_type_is_registered?" do
    @storagemgr.respond_to?( 'mechanism_type_is_registered?' ).should be_true
  end
  
  it "should initialize the type register hash" do
    @storagemgr.class.class_variable_get(:@@mechanism_type).is_a?( Hash ).should be_true
  end
  
  it "should auto-register storage mechanism types" do
    mechtypes = @storagemgr.class.class_variable_get(:@@mechanism_type)
    mechtypes.has_key?( :local_memory ).should be_true
    mechtypes.has_key?( :local_filesystem ).should be_true
    mechtypes.has_key?( :redis_instance ).should be_true
  end
  
  it "should respond to the set method" do
    @storagemgr.respond_to?( 'set' ).should be_true
  end
  
  it "should respond to register_storage_mechanism" do
    @storagemgr.respond_to?( 'register_storage_mechanism' ).should be_true
  end
  
  describe '- method: set' do
    
    it "should raise an exception when set called with no registered storage mechanisms" do
      expect {
        @storagemgr.set( :key => 'testkey',
                        :value => 'testvalue',
                        :storage_mechanism => :memory )
      }.to raise_error('no registered storage mechanisms available')
    end
    
    describe '(with registered storage mechanisms)' do
      
      before :each do
        @storagemgr.register_storage_mechanism( :type           => :local_memory,
                                                :keycheck_stage => 1,
                                                :locktype       => :local,
                                                :name           => :memory         )
      end
      
      it "should raise an exception when called without arguments" do
        expect {
          @storagemgr.set
        }.to raise_error('cannot call set without parameters')
      end
    
      it "should raise an exception when called with neither a key or keys param" do
        expect {
          @storagemgr.set( :value => 'testvalue',
                          :storage_mechanism => :memory )
        }.to raise_error('either :key or :keys must be defined')
      end
      
      it "should raise an exception when keys are empty" do
        expect {
          @storagemgr.set( :key => [], :value => 'testvalue',
                           :storage_mechanism => :memory )
        }.to raise_error('at least one key must be present')
        expect {
          @storagemgr.set( :key => "", :value => 'testvalue',
                          :storage_mechanism => :memory )
        }.to raise_error('at least one key must be present')
      end
      
    end
  end
  
  describe '- method: register_storage_mechanism' do
    
    it "should raise an exception when called without arguments" do
      expect {
        @storagemgr.register_storage_mechanism
      }.to raise_error('cannot call register_storage_mechanism without parameters')
    end
    
    it "should raise an exception when call references non-existant storage mechanism" do
      
      expect {
        @storagemgr.register_storage_mechanism( :type           => :unknown,
                                                :keycheck_stage => 1,
                                                :locktype       => :local,
                                                :name           => :memory         )
      }.to raise_error('cannot call register_storage_mechanism with unknown mechanism type')
      
    end
    
    it "should raise an exception when called without a :type parameter" do
      
      expect {
        @storagemgr.register_storage_mechanism( :keycheck_stage => 1,
                                                :locktype       => :local,
                                                :name           => :memory         )
      }.to raise_error('register_storage_mechanism requires a :type parameter')
      
    end
    
    it "should raise an exception when called without a :locktype parameter" do
      
      expect {
        @storagemgr.register_storage_mechanism( :keycheck_stage  => 1,
                                                :type            => :local_memory,
                                                :name            => :memory         )
      }.to raise_error('register_storage_mechanism requires a :locktype parameter')
      
    end
    
    it "should raise an exception when called without a :name parameter" do
      
      expect {
        @storagemgr.register_storage_mechanism( :type           => :local_memory,
                                                :keycheck_stage => 1,
                                                :locktype       => :local         )
      }.to raise_error('register_storage_mechanism requires a :name parameter')
      
    end
    
    it "should raise an exception when called without a :keycheck_stage parameter" do
      
      expect {
        @storagemgr.register_storage_mechanism( :type           => :local_memory,
                                                :locktype       => :local,
                                                :name           => :memory         )
      }.to raise_error('register_storage_mechanism requires a :keycheck_stage parameter')
      
    end
    
    it "should properly add the mechanism" do
      @storagemgr.register_storage_mechanism( :type           => :local_memory,
                                              :keycheck_stage => 1,
                                              :locktype       => :local,
                                              :name           => :memory         )
      mech = @storagemgr.instance_variable_get(:@registered_mechanisms)[:memory]
      mech.nil?.should be_false
      mech.is_a?( Hash ).should be_true
      mech.has_key?( :keycheck_stage ).should be_true
      mech.has_key?( :mechanism      ).should be_true
      mech.has_key?( :lock_manager   ).should be_true
      mech[:keycheck_stage].should == 1
      mech[:mechanism].is_a?( SadieStorageMechanismMemory ).should be_true
    end
   
  end
  
  
  
  
end