prime ["test.var1","test.var2"] do
  
  @r = {}
  
  after "test.var1" do |varname,val|
    @r[varname] = val
  end
  
  assign do
    set "test.var1","val1"
    set "test.var2","val2"
  end
  
end