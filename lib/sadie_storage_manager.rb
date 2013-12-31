class SadieStorageManager
  
  def initialize
    @mechanisms = {}
  end
  
  def register_storage_mechanism( handle, mechanism )
    @mechanisms[handle] = mechanism
  end
  
  def mechanism_is_registered?( mechanism_handle )
    
    @mechanisms.has_key?( mechanism_handle )
    
  end
  
  def set( params )
    unless params.nil?
      
      if params.is_a? Hash
        
        if params.has_key?( :mechanism )
          
          if mechanism_is_registered? params[:mechanism]
            
            if params.has_key?( :keys ) && params[:keys].is_a?( Array ) &&
               params.has_key?( :value )
            
              params[:keys].each do |key|
                @mechanisms[params[:mechanism]].set( key, params[:value] )
              end
            end
            
          end
          
        end
        
      end
      
    end
  end
  
end