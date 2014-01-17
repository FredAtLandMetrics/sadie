class SadieStorageManager
  
  def initialize
    @registered_mechanisms = {}
  end
  
  def register_storage_mechanism( params=nil )
    raise 'register_storage_mechanism requires Hash parameter' if params.nil? || ! params.is_a?( Hash )
    raise 'register_storage_mechanism requires a :type parameter' unless params.has_key?( :type )
    raise 'register_storage_mechanism requires a :class parameter' unless params.has_key?( :class )
    @registered_mechanisms[:type] = [ params[:class] ]
  end
  
  def mechanism_is_registered?( type )
    @registered_mechanisms.has_key?( type )
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
#   def set( params )
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
#   end
  
end