require 'sadie_storage_manager'
require 'storage/memory'
require 'storage/file'
require 'storage/redis'
require 'primer'
require 'thread'
require 'lock_manager'
require 'timestamp_queue'

class SadieSession
  attr_accessor :primers_dirpath
  
  def initialize( params )
    
    # init session operating parameters
    @default_storage_mechanism = :memory
    @file_storage_mechanism_dirpath = nil
    @redis_port,@redis_host = nil,nil
    @session_coordination = :none
    unless params.nil?
      if params.is_a? Hash
        
        if params.has_key?( :primers_dirpath )
          self.primers_dirpath = params[:primers_dirpath]
          
        end
        
        if params.has_key?( :default_storage_mechanism )
          @default_storage_mechanism = params[:default_storage_mechanism]
        end
        
        if params.has_key?( :file_storage_mechanism_dirpath )
          @file_storage_mechanism_dirpath = params[:file_storage_mechanism_dirpath]
        end
        
        if params.has_key?( :redis_port )
          @redis_port = params[:redis_port]
        end
        
        if params.has_key?( :redis_host )
          @redis_host = params[:redis_host]
        end
        
        if params.has_key?( :session_coordination )
          @session_coordination = params[:session_coordination]
        end
      end
    end
    
    # init lock manager
    @lockmgr = LockManager.new
    
    # init expiry and refresh threads
    @expiry_lock = @lockmgr.create( :systype => :session,
                                    :locktype => :expiry  )
    @refresh_lock = @lockmgr.create( :systype => :session,
                                     :locktype => :refresh  )

    @expiry_queue,@refresh_queue = TimestampQueue.new,TimestampQueue.new
    
    _initialize_expiry_thread
    _initialize_refresh_thread
    
    
    # init registered key hash
    @registered_key = {}
    
    # register primers
    _register_primers if ( ! self.primers_dirpath.nil? ) && ( Dir.exists?( self.primers_dirpath ) )
    
    # init storage manager
    @storagemgr_lock = @lockmgr.create( :systype => :session,
                                        :locktype => :expiry  )
    @storage_manager = SadieStorageManager.new
    @lockmgr.critical_section_insist( @storagemgr_lock ) do
      @storage_manager.register_storage_mechanism :memory, SadieStorageMechanismMemory.new
      @storage_manager.register_storage_mechanism :file, SadieStorageMechanismFile.new(:key_storage_dirpath => @file_storage_mechanism_dirpath)
      
      unless @redis_host.nil? || @redis_port.nil?
        @storage_manager.register_storage_mechanism :redis, SadieStorageMechanismRedis.new(
          :host => @redis_host,
          :port => @redis_port
        )
      end
    end
    
  end
  
  def has_key?( key, params )
    ret = @storage_manager.has_key?( key )
    include_primers = true
    
    if ( params.is_a?( Hash ) ) && ( params.has_key?( :include_primers ) )
      include_primers = params[:include_primers]
    end      
    
    if ( ! ret ) && ( include_primers )
      ret = primer_registered?( key )
    end
    
    ret
  end
  
  def primer_registered?( key )
    @registered_key.has_key? key
  end
  
  def unset( key )
    @lockmgr.critical_section_insist( @storagemgr_lock ) do
      @storage_manager.unset( key )
    end
  end
  
  def has_metadata?( key )
    @storage_manager.has_metadata?( key )
  end
  
  def metadata( key )
    @storage_manager.metadata( key )
  end
  
  def set( keys, value, params=nil )
    expires, mechanism, metadata = :never, @default_storage_mechanism, nil
    unless params.nil?
      if params.is_a? Hash
        expires = params[:expire] if params.has_key?( :expire )
        mechanism = params[:mechanism] if params.has_key?( :mechanism )
        metadata = params[:metadata] if params.has_key?( :metadata )
      end
    end
    @lockmgr.critical_section_insist( @storagemgr_lock ) do
      @storage_manager.set( :keys => Array( keys ),
                            :value => value,
                            :mechanism => mechanism,
                            :metadata => metadata )
    end
    _manage_expiry( keys, expires ) unless expires == :never || expires == :on_get
  end
  
  def get( key )
    ret = nil
    if @storage_manager.has_key?( key )
      ret = @storage_manager.get( key )
    elsif primer_registered?( key )
      
      @primer_lock = @lockmgr.create( :systype => :session,
                                      :locktype => :primer,
                                      :key => key )
      p = nil
      
      @lockmgr.critical_section_try( @primer_lock ) do
        p = _get_primed_primer( key )
        ret = @storage_manager.get( key )
        if p.expire == :on_get
          @storage_manager.unset( key )
        end
      end
      if ! p.nil?
        _manage_refresh( key, p.refresh_rate ) if ( p.refreshes? )
      else 
        @lockmgr.critical_section_insist( @primer_lock ) do
          if @storage_manager.has_key?( key )
            ret = @storage_manager.get( key )
          else
            ret = get( key )  # recurse should only happen if primer set to expire on get
          end
        end
      end
      
    end
    ret
  end
  
  private
  
  def _get_primed_primer( key )
    p = Primer.new( :session => self )
    p.decorate( @registered_key[ key ] )
    p
  end
  
  def _initialize_refresh_thread
    @refresh_thread = Thread.new do
      _refresh_loop
    end
  end
  
  def _initialize_expiry_thread
    @expiry_thread = Thread.new do
      _expiry_loop
    end
  end
  
  def _manage_expiry( keys, expires_seconds )
    if ! expires_seconds.is_a?( Symbol ) && expires_seconds.to_i > 0
      expires = expires_seconds.to_i + _current_time
      unless Array(keys).empty?
        Array(keys).each do |key|
          @lockmgr.critical_section_insist( @expiry_lock ) do
            @expiry_queue.insert( key, :timestamp => expires )
          end
        end
      end
    end
  end
  
  def _manage_refresh( keys, refresh_seconds )
    if ! refresh_seconds.is_a?( Symbol ) && refresh_seconds.to_i > 0
      refreshes = refresh_seconds.to_i + _current_time
      unless Array(keys).empty?
        Array(keys).each do |key|
          @lockmgr.critical_section_insist( @refresh_lock ) do
            @refresh_queue.insert( key, :timestamp => refreshes )
          end
        end
      end
    end
  end
  
  def _register_primers
    Dir.glob( File.join( self.primers_dirpath, "**", "*.rb" ) ).each do |primer_filepath|
      p = Primer.new( :session => self,
                      :default_storage_mechanism => @default_storage_mechanism )
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
  
  def _expiry_loop
    loop do
      _expiry_pass
      sleep 1
    end
  end
  
  def _expiry_pass
    time_now_in_seconds = _current_time
    
    loop do
      break if @expiry_queue.empty?
      
      ts,key = nil
      
      keys_to_unset = nil
      @lockmgr.critical_section_insist( @expiry_lock ) do
        
        keys_to_unset = @expiry_queue.find( :all, :before => time_now_in_seconds )
        
      end
      
      unless keys_to_unset.nil?
        keys_to_unset.each do |key|
          unset key
        end
      end
      
    end
      
  end
  
  def _refresh_loop
    loop do
      _refresh_pass
      sleep 1
    end
  end
  
  def _refresh_pass
    time_now_in_seconds = _current_time
    unless @refresh_queue.empty?
      keys = nil
      @lockmgr.critical_section_insist( @refresh_lock ) do
        keys = @refresh_queue.find(:all, :before => time_now_in_seconds)
      end
      
      unless keys.nil?
        keys.each do | key |
          _refresh key
        end
      end
    end
  end
  
  def _refresh( key )
    @primer_lock = @lockmgr.create( :systype => :session,
                                    :locktype => :primer,
                                    :key => key )
    p = nil
    @lockmgr.critical_section_try( @primer_lock ) do
      p = _get_primed_primer( key )
    end
    
    _manage_refresh( key, p.refresh_rate ) unless p.nil?
  end
  
  def _current_time
    Time.now.to_i
  end
end

