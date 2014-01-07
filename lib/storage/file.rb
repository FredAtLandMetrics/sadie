require 'sadie_storage_mechanism'
class SadieStorageMechanismFile < SadieStorageMechanism
  
  def initialize( params=nil )
    @key_storage_dirpath = "/tmp/sadie-key-storage"
    unless params.nil?
      if params.is_a?( Hash )
        if params.has_key? :key_storage_dirpath
          @key_storage_dirpath = params[:key_storage_dirpath]
        end
      end
    end
  end
  
  def set( key, value )
    raise 'Key storage directory does not exist' unless _keystorage_directory_exists?
    File.open(_keyvalue_filepath(key), 'wb') { |file| file.write(value) }
  end
  
  def get( key )
    raise 'Key storage directory does not exist' unless _keystorage_directory_exists?
    value = File.open(_keyvalue_filepath(key), 'rb') { |f| f.read }
    value
  end
  
  def unset( key )
    raise 'Key storage directory does not exist' unless _keystorage_directory_exists?
    File.delete(_keyvalue_filepath(key))
  end
  
  def has_key?( key )
    raise 'Key storage directory does not exist' unless _keystorage_directory_exists?
    File.exists?(_keyvalue_filepath(key))
  end
  
  def _keyvalue_filepath(key)
    File.join(@key_storage_dirpath,key)
  end
  
  def _keystorage_directory_exists?
    Dir.exists?( @key_storage_dirpath )
  end
end