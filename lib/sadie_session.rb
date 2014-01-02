require 'sadie_storage_manager'
require 'storage_mechanisms/memory'
require 'primer'
require 'thread'
require 'rbtree'

class SadieSession
  attr_accessor :primers_dirpath
  
  def initialize( params )
    @storage_manager_thread_mutex = Mutex.new
    @expiry_mutex = Mutex.new
    @expire_schedule = MultiRBTree.new
    @expiry_thread = Thread.new do
      _expiry_loop
    end
    @refresh_mutex = Mutex.new
    @refresh_schedule = MultiRBTree.new
    @refresh_thread = Thread.new do
      _refresh_loop
    end
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
    @storage_manager_thread_mutex.synchronize do

      @storage_manager.register_storage_mechanism :memory, SadieStorageMechanismMemory.new
    end
  end
  
  def has_key?( key )
    @storage_manager_thread_mutex.synchronize do
      @storage_manager.has_key?( key )
    end
  end
  
  def primer_registered?( key )
    @registered_key.has_key? key
  end
  
  def unset( key )
    @storage_manager_thread_mutex.synchronize do
      @storage_manager.unset( key )
    end
  end
  
  def set( keys, value, params=nil )
    expires, mechanism = :never, :memory
    unless params.nil?
      if params.is_a? Hash
        expires = params[:expire] if params.has_key?( :expire )
        mechanism = params[:mechanism] if params.has_key?( :mechanism )
      end
    end
    @storage_manager_thread_mutex.synchronize do
      @storage_manager.set( :keys => Array( keys ),
                            :value => value,
                            :mechanism => mechanism )
    end
    manage_expiry( keys, expires ) unless expires == :never || expires == :on_get
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
        manage_refresh( key, p.refresh_rate )
        @storage_manager.get( key )
      else
        @storage_manager.get( key )
      end
    end
  end
  
  def manage_expiry( keys, expires_seconds )
    if ! expires_seconds.is_a?( Symbol ) && expires_seconds.to_i > 0
      expires = expires_seconds.to_i + _current_time
      unless Array(keys).empty?
        Array(keys).each do |key|
          @expiry_mutex.synchronize do
            @expire_schedule[expires] = key
          end
        end
      end
    end
  end
  
  def manage_refresh( keys, refresh_seconds )
    if ! refresh_seconds.is_a?( Symbol ) && refresh_seconds.to_i > 0
      refreshes = refresh_seconds.to_i + _current_time
      unless Array(keys).empty?
        Array(keys).each do |key|
          @refresh_mutex.synchronize do
            @refresh_schedule[refreshes] = key
          end
        end
      end
    end
  end
  
  private
  
  def _register_primers
    Dir.glob( File.join( self.primers_dirpath, "**", "*.rb" ) ).each do |primer_filepath|
      p = Primer.new( :session => self )
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
          @refresh_mutex.synchronize do
            @refresh_schedule[ts] = key
          end
          break
        end
      end
  end
  
  def _refresh( key )
    p = Primer.new( :session => self )
    p.decorate( @registered_key[ key ] )
    manage_refresh( key, p.refresh_rate )
  end
  
  def _current_time
    Time.now.to_i
  end
end