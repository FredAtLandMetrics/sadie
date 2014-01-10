prime ["wait.secondary"] do
  refresh 1
  before :each do
    $counter ||= 0
    $max ||= 0
    $counter += 1
    $max = $counter if $counter > $max
  end
  after :each do
    $counter -= 1
  end
  assign do
    sleep 1
    set "secondary"
  end
end