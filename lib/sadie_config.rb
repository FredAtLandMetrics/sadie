require 'yaml'
require 'pp'
class SadieConfig
  
  def initialize( params=nil )
    @config_data = {}
    if params.is_a?( Hash )
      
      _initialize_config_data_from_file( params[:filepath] ) if params.has_key?( :filepath ) && ( File.exists?( params[:filepath] ) )
    end
  end
  
  def is_set?( k )
    ( ! _get_parent_and_key( k ).nil? )
  end
  
  def get( k )
    res = _get_parent_and_key( k )
    ( ( res.nil? ) ? nil : res[0][res[1]] )
  end
  
  private
  
  def _get_parent_and_key( key )
    
    keys = Array( key )
    ptr,pos,ret = @config_data, 0, nil
    loop do
      break unless keys[pos].is_a?( Symbol )
      break unless ptr.has_key?( keys[pos] )
      if pos >= ( keys.length - 1 )
        ret = [ ptr, keys[pos] ]
        break
      end
      break unless ptr[keys[pos]].is_a?( Hash )
      ptr = ptr[keys[pos]]
      pos += 1
    end
    ret
    
  end
  
  def _initialize_config_data_from_file( filepath )
    contents = File.open( filepath, 'rb' ) { |f| f.read }
    @config_data = _symbolize_string_keys( YAML::load( contents ) )
  end
  
  def _symbolize_string_keys( h )
    ret = nil
    if h.is_a?( Hash )
      ret = {}
      h.each do |k,v|
        nk = k.is_a?( String ) ? k.to_sym : k
        ret[ nk ] = v.is_a?( Hash ) ? _symbolize_string_keys( v ) : v
      end
    end
    ret
  end
  
end