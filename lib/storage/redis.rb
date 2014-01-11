require 'sadie_storage_mechanism'
class SadieStorageMechanismRedis < SadieStorageMechanism
  
  def initialize (params=nil )
  end
  
  def set( key, value )
    false
  end
  
  def get( key )
    nil
  end
  
  def unset( key )
    nil
  end
  
end