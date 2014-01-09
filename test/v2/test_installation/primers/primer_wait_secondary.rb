prime ["wait.secondary"] do
  refresh 1
  before :each do
#     puts "before pre"
    $counter ||= 0
    $max ||= 0
    $counter += 1
    $max = $counter if $counter > $max
    puts "counter: #{$counter}, max: #{$max}"
  end
  after :each do
#     puts "after pre"
    $counter -= 1
#     puts "after post"
    puts "counter: #{$counter}, max: #{$max}"
  end
  assign do
    sleep 1
    set "secondary"
  end
end