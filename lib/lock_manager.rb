require 'thread'

class LockManager
  
  def initialize
    @locks, @locksets = {}, {}
  end
  
  def set_add( lock_id, key )
    @locksets[lock_id.to_s] = [] unless @locksets.has_key?( lock_id.to_s )
    @locksets[lock_id.to_s].push key if @locksets[lock_id.to_s].index( key ).nil?
  end
  
  def set_del( lock_id, key )
    @locksets[lock_id.to_s] = [] unless @locksets.has_key?( lock_id.to_s )
    @locksets[lock_id.to_s].delete( key )
  end
  
  def in_set?( lock_id, key )
    @locksets[lock_id.to_s] = [] unless @locksets.has_key?( lock_id.to_s )
    ( ! @locksets[lock_id.to_s].index( key ).nil? )
  end
  
  def create( params )
    systype = params[:systype].to_s
    locktype = params[:locktype].to_s
    lock_id = "#{systype}:#{locktype}"
    if params.has_key?(:key)
      lock_id += ":#{params[:key].to_s}"
    end
    @locks[lock_id] = Mutex.new unless @locks.has_key?( lock_id )
    lock_id
  end
  
  def acquire( lock_id )
    if @locks[lock_id].try_lock
      lock_id
    else
      nil
    end
  end
  
  def release( lock_id )
    if @locks.has_key?( lock_id )
      @locks[lock_id].unlock
    end
  end
  
  def critical_section_insist( lock_id )
    if block_given?
      if @locks.has_key?( lock_id )
        @locks[lock_id].synchronize do
          yield
        end
      end
    end
  end
  
  def critical_section_try( lock_id )
    if block_given?
      if @locks.has_key?( lock_id )
        unless acquire( lock_id ).nil?
          yield
          release( lock_id )
        end
      end
    end
  end

end
