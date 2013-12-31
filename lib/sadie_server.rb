class SadieServer
  
  attr_accessor :framework_dirpath
  def initialize( params )
    unless params.nil?
      if params.is_a? Hash
        if params.has_key?( :framework_dirpath )
          self.framework_dirpath = params[:framework_dirpath]
        end
      end      
    end
  end
#   
#   def get
#   end
# 
#   def set
#   end
# 
#   def query
#   end
# 
#   def set_multiple
#   end
# 
#   def get_multiple
#   end
  
  def self.proc_args( argv )
    ret = nil
    unless argv.nil?
      if argv.is_a? Array
        unless argv.empty?
          argv.each do |argstr|
            if argstr =~ /^\-\-([^\=]+)\=(.*)$/
              ret = {} if ret.nil?
              k,v = $1,$2
              ret[k.gsub(/\-/,"_").to_sym] = v
            end
          end
        end        
      end
    end
    ret
  end
  
end