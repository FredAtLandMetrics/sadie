require 'sadie_storage_manager'
require 'storage_mechanisms/memory'
require 'primer'

class SadieSession
  attr_accessor :primers_dirpath
  
  def initialize( params )
    @registered_key = {}
    unless params.nil?
      if params.is_a? Hash
        if params.has_key?( :primers_dirpath )
          self.primers_dirpath = params[:primers_dirpath]
          _register_primers
        end
      end
    end
    @storage_manager = SadieStorageManager.new
    @storage_manager.register_storage_mechanism :memory, SadieStorageMechanismMemory.new
  end
  
  def has_key?( key )
    @storage_manager.has_key?( key )
  end
  
  def primer_registered?( key )
    @registered_key.has_key? key
  end
  
  def set( keys, value, params=nil )
    expires, mechanism = :never, :memory
    unless params.nil?
      if params.is_a? Hash
        expires = params[:expires] if params.has_key?( :expires )
        mechanism = params[:mechanism] if params.has_key( :mechanism )
      end
    end
    @storage_manager.set( :keys => Array( keys ),
                          :value => value,
                          :mechanism => mechanism )
    manage_expiry( keys, expires ) unless expires == :never
  end
  
  def get( key )
    if @storage_manager.has_key?( key )
      @storage_manager.get( key )
    elsif primer_registered?( key )
      p = Primer.new( :storage_manager => @storage_manager )
      p.decorate( @registered_key[ key ] )
      @storage_manager.get( key )
    end
  end
  
  def manage_expiry( keys, expires )
    
  end
  
  private
  
  def _register_primers
    Dir.glob( File.join( self.primers_dirpath, "**", "*.rb" ) ).each do |primer_filepath|
      p = Primer.new( :storage_manager => @storage_manager )
      p.mode = :registration
      p.decorate( primer_filepath )
      _register_keys p.keys, primer_filepath
    end
  end
  
  def _register_keys( keys=nil, filepath )
    if ( ! keys.nil? ) && ( ! Array( keys ).empty? )
      Array( keys ).each do |key|
        @registered_key[key] = filepath
      end
    end
  end
  
end