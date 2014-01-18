class SadieStorageManager
  
  def initialize
    @registered_mechanisms = {}
    @@mechanism_type = {}
    mechanisms_dirpath = File.join( File.dirname( __FILE__ ), 'storage' )
    
    raise 'storage mechanism library dirpath does not exist' unless Dir.exists?( mechanisms_dirpath )
    
    Dir.entries( mechanisms_dirpath ).each do |filename|
      load File.join( mechanisms_dirpath, filename ) if filename =~ /[^\.]+\.rb/
    end    
  end
  
  def self.register_mechanism_type( params=nil )
    raise 'register_mechanism_type requires Hash parameter' if params.nil? || ! params.is_a?( Hash )
    raise 'register_mechanism_type requires a :type parameter' unless params.has_key?( :type )
    raise 'register_mechanism_type requires a :class parameter' unless params.has_key?( :class )
    SadieStorageManager.class_variable_get(:@@mechanism_type)[params[:type]] = params[:class]
  end
  
  def mechanism_type_is_registered?( type )
    @registered_mechanisms.has_key?( type )
  end
  
  def register_storage_mechanism( params=nil )
    raise 'cannot call register_storage_mechanism without parameters' if params.nil? || ! params.is_a?( Hash )
    raise 'register_storage_mechanism requires a :type parameter' unless params.has_key?( :type )
    raise 'register_storage_mechanism requires a :locktype parameter' unless params.has_key?( :locktype )
    raise 'register_storage_mechanism requires a :name parameter' unless params.has_key?( :name )
    raise 'register_storage_mechanism requires a :keycheck_stage parameter' unless params.has_key?( :keycheck_stage )
    
    raise 'cannot call register_storage_mechanism with unknown mechanism type' unless @@mechanism_type.has_key?( params[:type] )
    
    @registered_mechanisms[ params[:name] ] = { :keycheck_stage => params[:keycheck_stage],
                                                :lock_manager => 'stub',
                                                :mechanism => @@mechanism_type[params[:type]].new }
  end
  
#   def where_key?( key )
#     ret = nil
#     registered_mechanisms.each do |mech|
#       if @mechanisms[mech].has_key?( key )
#         ret = mech
#         break
#       end
#     end
#     ret
#   end
#   
#   def has_key?( key )
#     ( ! where_key?( key ).nil? )
#   end
#   
#   def get( key )
#     @mechanisms[where_key?( key )].get( key ) if has_key?( key )
#   end
#   
#   def unset( key )
#     if has_key?( key )
#       @mechanisms[where_key?( key )].unset( key )
#     end
#   end
#   
#   def has_metadata?( key )
#     @mechanisms[where_key?( key )].has_metadata?( key ) if has_key?( key )
#   end
#   
#   def metadata( key )
#     @mechanisms[where_key?( key )].metadata( key ) if has_key?( key )
#   end
#   
  def set( params=nil )
    raise 'no registered storage mechanisms available' if @registered_mechanisms.empty?
    raise 'cannot call set without parameters' if params.nil?
    
    if ( ! params.has_key?( :key ) ) && ( ! params.has_key?( :keys ) )
      raise 'either :key or :keys must be defined'
    end
    
    keys = nil
    if params.has_key?( :key )
      keys = Array( params[:key] )
    elsif params.has_key?( :keys )
      keys = Array( params[:keys] )
    end
    
    if keys.empty? || ( keys[0].is_a?( String ) && keys[0].empty? )
      raise 'at least one key must be present'
    end
    
#     unless params.nil?
#       
#       if params.is_a? Hash
#         
#         if params.has_key?( :mechanism )
#           
#           if mechanism_is_registered? params[:mechanism]
#             
#             if params.has_key?( :keys ) && params[:keys].is_a?( Array ) &&
#                params.has_key?( :value )
#               has_metadata = false
#               if params.has_key?(:metadata) && params[:metadata].is_a?( Hash )
#                 has_metadata = true
#               end
#               params[:keys].each do |key|
#                 if has_metadata
#                   @mechanisms[params[:mechanism]].set( key, params[:value], :metadata => params[:metadata] )
#                 else
#                   @mechanisms[params[:mechanism]].set( key, params[:value] )
#                 end
#               end
#             end
#           end
#         end
#       end
#     end
  end
  
end