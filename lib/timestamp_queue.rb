require 'rbtree'
class TimestampQueue
  
  def initialize
    @queue = MultiRBTree.new
  end
  
  def insert( key, params=nil )
    ts = nil
    if ( params.is_a?( Hash ) ) &&
       ( params.has_key?( :timestamp ) )
      ts = params[:timestamp]
    else
      ts = _current_time
    end      
    @queue[ts] = key
  end
  
  def find( which, params=nil )
    if which == :first
      _find_first( params )
    elsif which == :all
      _find_all( params )
    end
  end
  
  def empty?
    @queue.empty?
  end
  
  private
  
  def _get_functions( params )
    testfunc,getfunc = nil,nil,nil
    if params.is_a? Hash
      if params.has_key? :before
        thresh = params[:before]
        testfunc = Proc.new { |x| (x < thresh) }
        getfunc = Proc.new { |q| q.shift }
      end
    end
    [testfunc,getfunc]
  end
  
  def _find_first( params )
    
    ret = nil
    testfunc,getfunc = _get_functions(params)
    unless testfunc.nil?
      ts,key = getfunc.call(@queue)
#       puts "testing: #{ts}, #{key}"
      if testfunc.call(ts)
        ret = _package_rec(ts,key,params)
      else
        @queue[ts] = key
      end
    end
    
    ret
  end
  
  def _find_all( params )
    ret = nil
    testfunc,getfunc = _get_functions(params)
    unless testfunc.nil?
      
      retarray = []
      loop do
        break if @queue.empty?
        ts,key = getfunc.call(@queue)
        if testfunc.call(ts)
          retarray.push _package_rec(ts,key,params)
        else
          @queue[ts] = key
          break
        end
      end
      ret = retarray unless retarray.empty?
    end
    ret
  end
  
  
  def _package_rec(timestamp,key,params)
    if params.nil? || ! params.is_a?( Hash )
      key
    elsif params.has_key?( :as )
      if params[:as] == :hash
        { :timestamp => timestamp,
          :key => key }
      else
        key
      end
    else
      key
    end
  end
  
  def _current_time
    Time.now.to_i
  end
  
end