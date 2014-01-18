require 'sadie_storage_mechanism'
# require 'marshal'

class SadieStorageMechanismFile < SadieStorageMechanism
  attr_accessor :key_storage_dirpath
  
  def initialize( params=nil )
    self.key_storage_dirpath = "/tmp/sadie-key-storage"
    unless params.nil?
      if params.is_a?( Hash )
        if params.has_key?( :key_storage_dirpath ) && ! params[:key_storage_dirpath].nil?
          self.key_storage_dirpath = params[:key_storage_dirpath]
        end
      end
    end
  end
  
  def set( key, value, params=nil )
    _validate_keystorage_directory
    File.open(_keyvalue_filepath(key), 'wb') { |file| file.write(value) }
    unless params.nil?
      if params.has_key? :metadata
        _write_metadata_file( key, params[:metadata] )
      end
    end
  end
  
  def metadata( key )
    contents = File.open( _metadata_filepath( key ), 'rb') { |f| f.read }
#     puts "contents: #{contents}"
    Marshal.load( contents ) if has_metadata?( key )
  end
  
  def has_metadata?( key )
    File.exists? _metadata_filepath( key )
  end
  
  def get( key )
    _validate_keystorage_directory
    value = File.open(_keyvalue_filepath(key), 'rb') { |f| f.read }
    value
  end
  
  def unset( key )
    _validate_keystorage_directory
    File.delete(_keyvalue_filepath(key))
  end
  
  def has_key?( key )
    _validate_keystorage_directory
    File.exists?(_keyvalue_filepath(key))
  end
  
private

  def _metadata_filepath( key )
    _ensure_metadata_dirpath_exists
    File.join( self.key_storage_dirpath, '.meta', key )
  end
  
  def _write_metadata_file( key, metadata_hash )
    raise 'metadata must be a hash' unless ( ! metadata_hash.nil? ) && ( metadata_hash.is_a?( Hash ) )
    _ensure_metadata_dirpath_exists
    File.open( _metadata_filepath( key ), 'wb' ) { |file| file.write( Marshal.dump( metadata_hash ) ) }
  end

  def _validate_keystorage_directory
    raise "Key storage directory (#{self.key_storage_dirpath}) does not exist" unless _keystorage_directory_exists?
  end

  def _keyvalue_filepath(key)
    File.join( self.key_storage_dirpath, key )
  end
  
  def _keystorage_directory_exists?
    Dir.exists?( self.key_storage_dirpath )
  end
  
  def _ensure_metadata_dirpath_exists
    dirpath = File.join( self.key_storage_dirpath, '.meta' )
    Dir.mkdir( dirpath ) unless Dir.exists?( dirpath )
  end
end

SadieStorageManager.register_mechanism_type( :type => :local_filesystem,
                                             :class =>  SadieStorageMechanismFile )
