require 'sadie_storage_mechanism'
class SadieStorageMechanismMemory < SadieStorageMechanism
  
  def initialize
    @storage_hash = {}
  end
  
  def set( key, value )
    @storage_hash[key] = value
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
  
end