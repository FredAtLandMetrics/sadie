prime ["test.var1","test.var2"] do
  
  @r = {}
  
  before "test.var1" do |varname|
    @r[varname] = 1
  end
  
  assign do
    set "test.var1","val1"
    set "test.var2","val2"
  end
  
end