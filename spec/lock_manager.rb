$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'lock_manager'
require 'thread'

describe LockManager do
  
  before :each do
    @lockmgr = LockManager.new
  end
  
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
  
  it "should properly protect critical sections with critical section insist" do
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
        @lockmgr.critical_section_insist( lockid ) do
          @total += 1
          @max = @total if @total > @max
          sleep rand(3).to_i
          @total -= 1
        end
      end
    end
    t2 = Thread.new do
      3.times do
        @lockmgr.critical_section_insist( lockid ) do
          @total += 1
          @max = @total if @total > @max
          sleep rand(3).to_i
          @total -= 1
        end
      end
    end
    t3 = Thread.new do
      3.times do
        @lockmgr.critical_section_insist( lockid ) do
          @total += 1
          @max = @total if @total > @max
          sleep rand(3).to_i
          @total -= 1
        end
      end
    end
    sleep 5
    t1.join
    t2.join
    t3.join
    ( @max > 1 ).should be_false
  end
  
  it "should add keys to the lockset" do
    lockid = @lockmgr.create( :systype => 'test', :locktype => 'test' )
    @lockmgr.set_add( lockid, 'testkey' )
    sethash = @lockmgr.instance_variable_get(:@locksets)
    sethash[lockid.to_s].index('testkey').nil?.should be_false
  end
  
  it "should delete keys from the lockset" do
    lockid = @lockmgr.create( :systype => 'test', :locktype => 'test' )
    @lockmgr.set_add( lockid, 'testkey' )
    sethash = @lockmgr.instance_variable_get(:@locksets)
    sethash[lockid.to_s].index('testkey').nil?.should be_false
    @lockmgr.set_del( lockid, 'testkey' )
    sethash[lockid.to_s].index('testkey').nil?.should be_true
  end
  
  it "should have a functional in_set? method" do
    lockid = @lockmgr.create( :systype => 'test', :locktype => 'test' )
    @lockmgr.set_add( lockid, 'testkey' )
    @lockmgr.in_set?( lockid, 'testkey' ).should be_true
    @lockmgr.set_del( lockid, 'testkey' )
    @lockmgr.in_set?( lockid, 'testkey' ).should be_false
  end
end
