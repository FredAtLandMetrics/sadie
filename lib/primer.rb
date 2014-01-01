class Primer
  
  attr_accessor :keys, :mode, :storage_manager, :storage_mechanism, :assign_keys
  
  def initialize( params=nil )
    self.storage_mechanism = :memory
    @before_block = {}
    @after_block = {}
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
  
  def before( arg, &block )
    if arg == :each
      if block_given?
        @before_block[:each] = block
      end
    elsif arg.is_a? String
      if self.keys.index( arg ).nil?
        raise 'key passed as argument to before must be declared in the prime directive'
      else
        @before_block[arg] = block
      end
    end
  end
  
  def after( arg, &block )
    if arg == :each
      if block_given?
        @after_block[:each] = block
      end
    elsif arg.is_a? String
      if self.keys.index( arg ).nil?
        raise 'key passed as argument to after must be declared in the prime directive'
      else
        @after_block[arg] = block
      end
    end
  end
  
  def prime( k=nil )
    self.keys = Array(k) if _validate_key_arg(k)
    yield if block_given?
  end
  
  def assign( keys = nil )
    if keys.nil?
      self.assign_keys = self.keys
    elsif _validate_key_arg(keys)
      unless (Array( keys ) - self.keys).empty?
        raise 'assigning keys that are not given as arguments to prime is not permitted'
      end
      self.assign_keys = Array(keys)
    end
    unless mode == :registration
      yield if block_given?
    end
  end
  
  def set( keys=nil, value=nil)
    if value.nil?
      _set1(keys)
    else
      _set2(keys,value)
    end
  end
  
  def store_in( mech )
    self.storage_mechanism = mech
  end
  
  private
  
  def _set2( keys=nil, value )
    if keys.nil?
      _set1(value)
    elsif _validate_key_arg(keys)
      unless (Array( keys ) - self.assign_keys).empty?
        raise 'assigning keys that are not given as arguments to assign (or to prime, if assign was given no keys as arguments) is not permitted'
      end
      
      if @before_block.has_key?(:each) && ! @before_block[:each].nil?
        
        Array(keys).each do |key|
          @before_block[:each].call(key)
        end
        
      end
      
      Array(keys).each do |key|
        if @before_block.has_key?(key) && ! @before_block[key].nil?
          
          @before_block[key].call(key)
          
        end
      end
      
      self.storage_manager.set(
        :mechanism => self.storage_mechanism,
        :keys => Array(keys),
        :value => value
      )
      
      if @after_block.has_key?(:each) && ! @after_block[:each].nil?
        
        Array(keys).each do |key|
          @after_block[:each].call(key,value)
        end
        
      end
      
      Array(keys).each do |key|
        if @after_block.has_key?(key) && ! @after_block[key].nil?
          
          @after_block[key].call(key,value)
          
        end
      end
    end
  end
  
  def _set1( value )
    unless @before_block[:each].nil?
      
      Array(keys).each do |key|
        @before_block[:each].call(key)
      end
      
    end
    Array(self.assign_keys).each do |key|
      if @before_block.has_key?(key) && ! @before_block[key].nil?
        
        @before_block[key].call(key)
        
      end
    end
    self.storage_manager.set(
      :mechanism => self.storage_mechanism,
      :keys => self.assign_keys,
      :value => value
    )
    if @after_block.has_key?(:each) && ! @after_block[:each].nil?
      
      Array(keys).each do |key|
        @after_block[:each].call(key,value)
      end
      
    end
    
    Array(keys).each do |key|
      if @after_block.has_key?(key) && ! @after_block[key].nil?
        
        @after_block[key].call(key,value)
        
      end
    end
  end
  
  def _validate_key_arg( k=nil )
    if k.is_a?(String)
      true
    elsif k.is_a?( Array )
      k.each do |key|
        unless key.is_a?( String )
          raise 'keys must be string or array or strings'
        end
      end
    else
      raise 'keys must be string or array or strings'
    end
    true
  end
  
end