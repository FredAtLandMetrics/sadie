prime ["test.expires.onget"] do
  expire :on_get
  assign do
    set "testval"
  end
end