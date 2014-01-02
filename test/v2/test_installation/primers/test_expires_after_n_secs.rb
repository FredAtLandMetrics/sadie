prime ["test.expires.nsecs"] do
  expire 1
  assign do
    set "testval"
  end
end