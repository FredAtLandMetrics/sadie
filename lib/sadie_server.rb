require 'sadie_session'

class SadieServer
  
  attr_accessor :framework_dirpath
  def initialize( params )
    self.framework_dirpath = "/var/sadie"
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
  
  def self.proc_args( argv_param )
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