require 'sadie_storage_manager'
require 'storage/memory'
require 'storage/file'
require 'primer'
require 'thread'
require 'rbtree'
require 'lock_manager'

class SadieSession
  attr_accessor :primers_dirpath
  
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
  
  def initialize( params )
    
    # init lock manager
    @lockmgr = LockManager.new
    
    # init expiry and refresh threads
    @expiry_lock = @lockmgr.create( :systype => :session,
                                    :locktype => :expiry  )
    @refresh_lock = @lockmgr.create( :systype => :session,
                                     :locktype => :refresh  )
    @expire_schedule,@refresh_schedule = MultiRBTree.new,MultiRBTree.new
    _initialize_expiry_thread
    _initialize_refresh_thread
    
    # init registered key hash
    @registered_key = {}
    
    # init session operating parameters
    @default_storage_mechanism = :memory
    @file_storage_mechanism_dirpath = nil
    unless params.nil?
      if params.is_a? Hash
        
        if params.has_key?( :primers_dirpath )
          self.primers_dirpath = params[:primers_dirpath]
          puts "initializing session with primer dirpath: #{self.primers_dirpath}"
          _register_primers
        end
        
        if params.has_key?( :default_storage_mechanism )
          @default_storage_mechanism = params[:default_storage_mechanism]
        end
        
        if params.has_key?( :file_storage_mechanism_dirpath )
          @file_storage_mechanism_dirpath = params[:file_storage_mechanism_dirpath]
        end
        
      end
    end
    
    # init storage manager
    @storagemgr_lock = @lockmgr.create( :systype => :session,
                                        :locktype => :expiry  )
    @storage_manager = SadieStorageManager.new
    @lockmgr.critical_section_insist( @storagemgr_lock ) do
      @storage_manager.register_storage_mechanism :memory, SadieStorageMechanismMemory.new
      @storage_manager.register_storage_mechanism :file, SadieStorageMechanismFile.new(:key_storage_dirpath => @file_storage_mechanism_dirpath)
    end
    
  end
  
  def has_key?( key )
    ( @storage_manager.has_key?( key ) || primer_registered?( key ) )
  end
  
  def primer_registered?( key )
    @registered_key.has_key? key
  end
  
  def unset( key )
    @lockmgr.critical_section_insist( @storagemgr_lock ) do
      @storage_manager.unset( key )
    end
  end
  
  def set( keys, value, params=nil )
    expires, mechanism = :never, @default_storage_mechanism
    unless params.nil?
      if params.is_a? Hash
        expires = params[:expire] if params.has_key?( :expire )
        mechanism = params[:mechanism] if params.has_key?( :mechanism )
      end
    end
    @lockmgr.critical_section_insist( @storagemgr_lock ) do
      @storage_manager.set( :keys => Array( keys ),
                            :value => value,
                            :mechanism => mechanism )
    end
    _manage_expiry( keys, expires ) unless expires == :never || expires == :on_get
  end
  
  def get( key )
    if @storage_manager.has_key?( key )
      @storage_manager.get( key )
    elsif primer_registered?( key )
      p = Primer.new( :session => self )
      p.decorate( @registered_key[ key ] )
      if p.expire == :on_get
        ret = @storage_manager.get( key )
        @storage_manager.unset( key )
        ret
      elsif ( p.refreshes? )
        _manage_refresh( key, p.refresh_rate )
        @storage_manager.get( key )
      else
        @storage_manager.get( key )
      end
    end
  end
  
  private
  
  def _manage_expiry( keys, expires_seconds )
    if ! expires_seconds.is_a?( Symbol ) && expires_seconds.to_i > 0
      expires = expires_seconds.to_i + _current_time
      unless Array(keys).empty?
        Array(keys).each do |key|
          @lockmgr.critical_section_insist( @expiry_lock ) do
            @expire_schedule[expires] = key
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
            @refresh_schedule[refreshes] = key
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
    @expiry_mutex.synchronize do
      loop do
        break if @expire_schedule.empty?
        ts,key = @expire_schedule.shift
        if ts < time_now_in_seconds
          unset key
        else
          @expire_schedule[ts] = key
          break
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
      loop do
        break if @refresh_schedule.empty?
        ts,key = @refresh_schedule.shift
        if ts < time_now_in_seconds
          _refresh key
        else
          @lockmgr.critical_section_insist( @refresh_lock ) do
            @refresh_schedule[ts] = key
          end
          break
        end
      end
  end
  
  def _refresh( key )
    p = Primer.new( :session => self )
    p.decorate( @registered_key[ key ] )
    _manage_refresh( key, p.refresh_rate )
  end
  
  def _current_time
    Time.now.to_i
  end
end