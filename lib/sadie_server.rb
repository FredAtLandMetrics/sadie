require 'sadie_session'
require 'yaml'

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
    @sadie_session = SadieSession.new( :primers_dirpath => File.join( self.framework_dirpath, 'primers' ) )
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
  
end