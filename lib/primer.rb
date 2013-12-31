class Primer
  
  attr_accessor :keys, :mode, :storage_manager, :storage_mechanism, :current_keys
  
  def initialize( params=nil )
    self.storage_mechanism = :memory
    unless params.nil?
      if params.is_a? Hash
        if params.has_key?( :storage_manager )
          self.storage_manager = params[:storage_manager]
        end
      end      
    end
  end
  
  def decorate( primer_filepath )
    if File.exists?( primer_filepath )
      self.instance_eval File.open(primer_filepath, 'rb') { |f| f.read } 
    else
      raise ArgumentError, "#{primer_filepath} not found"
    end
  end
  
  def prime( k )
    self.keys = k.is_a?( Array ) ? k : [k]
    yield if block_given?
  end
  
  def assign( keys = nil )
    self.current_keys = keys
    unless mode == :registration
      yield if block_given?
    end
  end
  
  def set( value )
    self.storage_manager.set(
      :mechanism => self.storage_mechanism,
      :keys => self.current_keys.nil? ? self.keys : self.current_keys,
      :value => value
    )
  end
  
  def store_in( mech )
    self.storage_mechanism = mech
  end
  
end