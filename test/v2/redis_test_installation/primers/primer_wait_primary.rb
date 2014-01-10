prime ["wait.primary"] do
  refresh 1
  assign do
    secval = session.get("wait.secondary")
    set "primary#{secval}"
  end
end