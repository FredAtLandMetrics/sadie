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
  end
  
end