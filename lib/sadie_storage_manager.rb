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
  
  def registered_mechanisms
    @mechanisms.keys
  end
  
  def where_key?( key )
    ret = nil
    registered_mechanisms.each do |mech|
      if @mechanisms[mech].has_key?( key )
        ret = mech
        break
      end
    end
    ret
  end
  
  def has_key?( key )
    ( ! where_key?( key ).nil? )
  end
  
  def get( key )
    @mechanisms[where_key?( key )].get( key ) if has_key?( key )
  end
  
  def unset( key )
    if has_key?( key )
      @mechanisms[where_key?( key )].unset( key )
    end
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