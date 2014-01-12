require 'redis'

class RedisTimestampQueue
  
  def initialize( params=nil )
    raise 'the redis timestamp queue requires parameters to be initialized' if params.nil? || ! params.is_a?( Hash )
    @port = params.has_key?( :port ) ? params[:port] : nil
    @host = params.has_key?( :host ) ? params[:host] : 'localhost'
    @handle  = params.has_key?( :handle ) ? params[:handle] : 'default_redis_tsq_handle'
    @redis_server = Redis.new( :host => @host, :port => @port.to_i ) unless @host.nil? || @port.nil?
  end
  
  def insert( key, params=nil )
    ts = nil
    if ( params.is_a?( Hash ) ) &&
       ( params.has_key?( :timestamp ) )
      ts = params[:timestamp]
    else
      ts = _current_time
    end
    @redis_server.zadd( _redis_sorted_set_name, ts, key )
  end
  
  def find( which, params=nil )
    if which == :first
      _find_first( params )
    elsif which == :all
      _find_all( params )
    end
  end
  
  def empty?
    ( @redis_server.zcard( _redis_sorted_set_name ) <= 0 )
  end
  
  private
  
  def _redis_sorted_set_name
    "SADIE:TSQ:#{@handle}"
  end
    
  def _find_first( params )
    ret = nil
    if params.is_a? Hash
      if params.has_key? :before
        thresh = params[:before]
        recs = @redis_server.zrangebyscore( _redis_sorted_set_name, "0", thresh.to_s, :with_scores => true, :limit => [0, 1] )
        if ( ! recs.nil? ) && ( ! recs.empty? )
          key,ts = recs[0]
          ret = _package_rec( ts, key, params )
          @redis_server.zremrangebyscore( _redis_sorted_set_name, "0", thresh.to_s )
        end
      end
    end
    ret    
  end
  
  def _find_all( params )
    ret = nil
    if params.is_a? Hash
      if params.has_key? :before
        thresh = params[:before]
        recs = @redis_server.zrangebyscore( _redis_sorted_set_name, "0", thresh.to_s, :with_scores => true )
        if ( ! recs.nil? ) && ( ! recs.empty? )
          retarray = []
          recs.each do |recarray|
            key,ts = recarray
            retarray.push _package_rec( ts, key, params )
          end
          if ! retarray.empty?
            ret = retarray
            @redis_server.zremrangebyscore( _redis_sorted_set_name, "0", thresh.to_s )
          end
        end
      end
    end
    ret    
  end
  
  def _current_time
    Time.now.to_i
  end
  
  def _package_rec(timestamp,key,params)
    if params.nil? || ! params.is_a?( Hash )
      key
    elsif params.has_key?( :as )
      if params[:as] == :hash
        { :timestamp => timestamp,
          :key => key }
      else
        key
      end
    else
      key
    end
  end

end