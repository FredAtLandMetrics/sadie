require 'thread'
require 'redis-mutex'

class StorageManagerLockManager
  
  def initialize( params=nil )
    @locks, @locksets, @mode = {}, {}, :single_instance
    @redis_host, @redis_port = nil, nil
#     Redis::Classy.db = Redis.new(:host => @redis_host, :port => @redis_port)
    
    if ( ! params.nil? ) &&
       params.is_a?( Hash )
      
      if params.has_key?( :mode ) &&
         params[:mode] == :redis_coordinated
        
        @mode = :redis_coordinated
        @redis_host = params[:redis_host] if params.has_key?( :redis_host )
        @redis_port = params[:redis_port] if params.has_key?( :redis_port )
        Redis::Classy.db = Redis.new(:host => @redis_host, :port => @redis_port)
      end
      
    end
  end
  
#   def set_add( lock_id, key )
#     critical_section_insist( lock_id ) do
#       @locksets[lock_id.to_s] = [] unless @locksets.has_key?( lock_id.to_s )
#       @locksets[lock_id.to_s].push key if @locksets[lock_id.to_s].index( key ).nil?
#     end
#   end
#   
#   def set_del( lock_id, key )
#     critical_section_insist( lock_id ) do
#       @locksets[lock_id.to_s] = [] unless @locksets.has_key?( lock_id.to_s )
#       @locksets[lock_id.to_s].delete( key )
#     end
#   end
#   
#   def in_set?( lock_id, key )
#     @locksets[lock_id.to_s] = [] unless @locksets.has_key?( lock_id.to_s )
#     ( ! @locksets[lock_id.to_s].index( key ).nil? )
#   end
#   
  def create( params )
    systype = params[:systype].to_s
    locktype = params[:locktype].to_s
    lock_id = "#{systype}:#{locktype}"
    if params.has_key?(:key)
      lock_id += ":#{params[:key].to_s}"
    end
    
    ret = nil
    if @mode == :single_instance
      @locks[lock_id] = Mutex.new unless @locks.has_key?( lock_id )
      ret = lock_id
    elsif @mode == :redis_coordinated
      @locks[lock_id] = Redis::Mutex.new( lock_id, :block => 10, :expire => 4 )
      ret = lock_id
    end
    ret
  end
  
  def acquire( lock_id )
    if @mode == :single_instance && @locks[lock_id].try_lock
      lock_id
    elsif @mode == :redis_coordinated && @locks[lock_id].lock
      lock_id
    else
      nil
    end
  end
  
  def release( lock_id )
    if @mode == :single_instance && @locks.has_key?( lock_id )
      @locks[lock_id].unlock
    elsif @mode == :redis_coordinated && @locks[lock_id].lock
      @locks[lock_id].unlock
    else
      nil
    end
  end
  
  def critical_section_insist( lock_id )
    if block_given?
      if @locks.has_key?( lock_id )
        if @mode == :single_instance
          @locks[lock_id].synchronize do
            yield
          end
        elsif @mode == :redis_coordinated
          @locks[lock_id].with_lock do
            yield
          end
        end
      end
    end
  end
  
  def critical_section_try( lock_id )
    if block_given?
      if @locks.has_key?( lock_id )
        if @mode == :single_instance
          unless acquire( lock_id ).nil?
            yield
            release( lock_id )
          end
        elsif @mode == :redis_coordinated
          unless @locks[lock_id].locked?
            @locks[lock_id].with_lock do
              yield
            end
          end
        end
      end
    end
  end

end
