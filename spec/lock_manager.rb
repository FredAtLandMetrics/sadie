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
          @lockmgr.acquire( lockid )
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
          @lockmgr.acquire( lockid )
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
