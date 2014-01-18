require 'sadie_storage_mechanism'
class SadieStorageMechanismMemory < SadieStorageMechanism
  
  def initialize
    @storage_hash = {}
    @metadata = {}
  end
  
  def set( key, value, params=nil  )
    @storage_hash[key] = value
    unless params.nil?
      if params.has_key? :metadata
        _write_metadata( key, params[:metadata] )
      end
    end
  end
  
  def get( key )
    @storage_hash[key] if @storage_hash.has_key?( key )
  end
  
  def unset( key )
    @storage_hash.delete key
  end
  
  def has_key?( key )
    @storage_hash.has_key?( key )
  end
  
  def metadata( key )
    @metadata[key] if has_metadata?( key )
  end
  
  def has_metadata?( key )
    @metadata.has_key?( key )
  end
  
  private
  
  def _write_metadata( key, metadata_hash )
    raise 'metadata must be a hash' unless ( ! metadata_hash.nil? ) && ( metadata_hash.is_a?( Hash ) )
    @metadata[key] = metadata_hash
  end
  
end

SadieStorageManager.register_mechanism_type( :type => :local_memory,
                                             :class =>  SadieStorageMechanismMemory )
