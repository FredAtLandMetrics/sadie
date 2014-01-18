require 'redis'
require 'sadie_storage_mechanism'

class SadieStorageMechanismRedis < SadieStorageMechanism
  
  def initialize ( params=nil )
    
    raise 'the redis storage mechanism requires parameters to be initialized' if params.nil? || ! params.is_a?( Hash )
    
    @port = params.has_key?( :port ) ? params[:port] : nil
    @host = params.has_key?( :host ) ? params[:host] : 'localhost'
    
    @redis_server = Redis.new( :host => @host, :port => @port.to_i ) unless @host.nil? || @port.nil?
    
  end
  
  def set( key, value, params=nil )
    @redis_server.set( key, value )
    unless params.nil?
      if params.has_key? :metadata
        _write_metadata( key, params[:metadata] )
      end
    end
  end
  
  def get( key )
    @redis_server.get( key )
  end
  
  def unset( key )
    @redis_server.del key
  end
  
  def has_key?( key )
    @redis_server.exists(key)
  end
  
  def metadata( key )
    Marshal.load( @redis_server.get( _metadata_key( key ) ) ) if has_metadata?( key )
  end
  
  def has_metadata?( key )
    @redis_server.exists( _metadata_key( key ) )
  end
  
  private
  
  def _write_metadata( key, metadata_hash )
    raise 'metadata must be a hash' unless ( ! metadata_hash.nil? ) && ( metadata_hash.is_a?( Hash ) )
    @redis_server.set( _metadata_key( key ), Marshal.dump( metadata_hash ) )
  end
  
  def _metadata_key( key )
    "#{key}:metadata"
  end
  
end

SadieStorageManager.register_mechanism_type( :type => :redis_instance,
                                             :class =>  SadieStorageMechanismRedis )

