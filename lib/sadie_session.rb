class SadieSession
  attr_accessor :primers_dirpath
  
  def initialize( params )
    unless params.nil?
      if params.is_a? Hash
        if params.has_key?( :primers_dirpath )
          self.primers_dirpath = params[:primers_dirpath]
        end
      end      
    end
    @storage_manager = SadieStorageManager.new
    @storage_manager.register_storage_mechanism :memory, SadieStorageMechanismMemory.new
  end
  
  def set( keys, value, params )
    expires, mechanism = :never, :memory
    unless params.nil?
      if params.is_a? Hash
        expires = params[:expires] if params.has_key?( :expires )
        mechanism = params[:mechanism] if params.has_key( :mechanism )
      end
    end
    @storage_manager.set( :keys => Array( keys ),
                          :value => value,
                          :mechanism => mechanism )
    manage_expiry( keys, expires ) unless expires == :never
  end
  
  def get( key )
    @storage_manager.get( key )
  end
  
  def manage_expiry( keys, expires )
    
  end
  
end