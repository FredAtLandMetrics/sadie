prime ["test.refresh"] do
  refresh 1
  assign do
    if session.has_key?( "test.refresh", :include_primers => false )
      set session.get("test.refresh").gsub(/^r/,"rr")
    else
      set "refresh"
    end
  end
end