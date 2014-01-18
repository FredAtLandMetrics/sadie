$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'redis'
require 'storage_manager_lock_manager'
require 'sadie_storage_manager'

describe 'RedisBasedSadie' do

  describe 'Storage Manager registering Redis storage mechanism' do
    before :each do
      @redis_server = Redis.new( :host => 'localhost', :port => 6379 )
      @redis_server.flushall
      @storagemgr = SadieStorageManager.new
    end
    
    it "should properly add the mechanism" do
      @storagemgr.register_storage_mechanism( :type           => :redis_instance,
                                              :keycheck_stage => 2,
                                              :locktype       => :redis,
                                              :name           => :redis         )
      mech = @storagemgr.instance_variable_get(:@registered_mechanisms)[:redis]
      mech.nil?.should be_false
      mech.is_a?( Hash ).should be_true
      mech.has_key?( :keycheck_stage ).should be_true
      mech.has_key?( :mechanism      ).should be_true
      mech.has_key?( :lock_manager   ).should be_true
      mech[:keycheck_stage].should == 2
      mech[:mechanism].is_a?( SadieStorageMechanismRedis ).should be_true
      mech[:lock_manager].is_a?( StorageManagerLockManager ).should be_true
      mech[:lock_manager].instance_variable_get(:@mode).should == :redis_coordinated
    end
    
  end
  
  describe 'Lock Manager in Redis Coordination Mode' do
    
    before :each do
      @redis_server = Redis.new( :host => 'localhost', :port => 6379 )
      @redis_server.flushall
      @lockmgr = StorageManagerLockManager.new( :mode => :redis_coordinated,
                                  :redis_host => 'localhost',
                                  :redis_port => 6379 )
    end
    
    it "should set proper instance variables when started with redis mode" do
      @lockmgr.instance_variable_get(:@mode).should == :redis_coordinated
      @lockmgr.instance_variable_get(:@redis_port).should == 6379
      @lockmgr.instance_variable_get(:@redis_host).should == 'localhost'
    end
    
    if ENV.has_key?('SADIE_REDIS_EXTENSIVE') && ENV['SADIE_REDIS_EXTENSIVE'] == 1
    
      it "should properly protect critical sections with acquire and release" do
        @total = 0
        @max = 0
        t1 = Thread.new do
          @total += 1
          @max = @total if @total > @max
          sleep rand(3).to_i
          @total -= 1
        end
        t2 = Thread.new do
          @total += 1
          @max = @total if @total > @max
          sleep rand(3).to_i
          @total -= 1
        end
        t3 = Thread.new do
          @total += 1
          @max = @total if @total > @max
          sleep rand(3).to_i
          @total -= 1
        end
        sleep 5
        t1.join
        t2.join
        t3.join
        ( @max > 1 ).should be_true
        
        lockid = @lockmgr.create( :systype => 'test', :locktype => 'test' )
        @total = 0
        @max = 0
        t1 = Thread.new do
          3.times do
            unless @lockmgr.acquire( lockid ).nil?
              @total += 1
              @max = @total if @total > @max
              sleep rand(3).to_i
              @total -= 1
              @lockmgr.release( lockid )
            end
          end
        end
        t2 = Thread.new do
          3.times do
            unless @lockmgr.acquire( lockid ).nil?
              @total += 1
              @max = @total if @total > @max
              sleep rand(3).to_i
              @total -= 1
              @lockmgr.release( lockid )
            end
          end
        end
        t3 = Thread.new do
          3.times do
            unless @lockmgr.acquire( lockid ).nil?
              @total += 1
              @max = @total if @total > @max
              sleep rand(3).to_i
              @total -= 1
              @lockmgr.release( lockid )
            end
          end
        end
        sleep 5
        t1.join
        t2.join
        t3.join
        ( @max > 1 ).should be_false
      end
      
    end
    
  end  

end
