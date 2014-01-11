require 'sadie_session'
require 'yaml'
require 'pp'

class SadieServer
  
  attr_accessor :framework_dirpath, :default_storage_mechanism
  def initialize( params=nil )
    self.framework_dirpath = "/var/sadie"
    self.default_storage_mechanism = :memory
    unless params.nil?
      if params.is_a? Hash
        if params.has_key?( :framework_dirpath )
          self.framework_dirpath = params[:framework_dirpath]
        end
      end      
    end
    
    sess_params = {
      :primers_dirpath => File.join( self.framework_dirpath, 'primers' )
    }
    if _config_hash.is_a?( Hash )
      
      # storage params
      if _config_hash.has_key?( 'storage' ) &&
         _config_hash['storage'].is_a?( Hash )
      
        # default storage mechanism
        if _config_hash['storage'].has_key?( 'default_storage_mechanism' )
          sess_params[:default_storage_mechanism] = _config_hash['storage']['default_storage_mechanism']
        end
        
        # key storage dirpath
        if _config_hash['storage'].has_key?( 'file' ) &&
          _config_hash['storage']['file'].is_a?( Hash ) &&
          _config_hash['storage']['file'].has_key?( 'key_storage_dirpath' )
          sess_params[:file_storage_mechanism_dirpath] = _config_hash['storage']['file']['key_storage_dirpath']
        end
      end

      # redis params
      if _config_hash.has_key?( 'redis' ) &&
         _config_hash['redis'].is_a?( Hash )
        
        if _config_hash['redis'].has_key?( 'port' )
          
          sess_params[:redis_port] = _config_hash['redis']['port']
          
        end
        
         if _config_hash['redis'].has_key?( 'host' )
          
          sess_params[:redis_host] = _config_hash['redis']['host']
          
        end
        
     end
      
    end
#     puts "sess_params: #{sess_params.pretty_inspect}"
    @sadie_session = SadieSession.new( sess_params )
  end
   
  def get( key )
    @sadie_session.get( key )
  end
 
  def set( key, value )
    @sadie_session.set( key, value )
  end
# 
#   def query
#   end
# 
#   def set_multiple
#   end
# 
#   def get_multiple
#   end
  def self.proc_args( argv_param=nil )
    argv = argv_param.dup
    ARGV.clear
    ret = nil
    
    unless argv.nil?
      if argv.is_a? Array
        unless argv.empty?
          argv.each do |argstr|
            puts "argstr: #{argstr}"
            if argstr =~ /^\-\-([^\=]+)\=(.*)$/
              ret = {} if ret.nil?
              k,v = $1,$2
              ret[k.gsub(/\-/,"_").to_sym] = v
            else
              ARGV.push argstr
            end
          end
        end        
      end
    end
    ret
  end
  
private
  
  def _config_hash
    
    if @config_hash.nil?
      @config_hash = YAML.load_file(File.join(self.framework_dirpath,'config','sadie.yml'))
      
      if @config_hash.is_a?( Hash )
        if ( @config_hash.has_key?( 'storage' ) ) &&
           ( @config_hash['storage'].is_a?( Hash ) ) &&
           ( @config_hash['storage'].has_key?( 'default_storage_mechanism' ) )
          @config_hash['storage']['default_storage_mechanism'] = @config_hash['storage']['default_storage_mechanism'].to_sym
        end
      end
      
    end
    @config_hash
    
  end
  
end