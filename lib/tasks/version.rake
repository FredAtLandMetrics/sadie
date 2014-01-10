# increment version
task :inc_version do
    version = current_sadie_version
    if (matches = version.match(/^(\d+\.\d+\.)(\d+)$/))
        pre = matches[1]
        post = Integer(matches[2]) + 1
        version = "#{pre}#{post}"
    end
    fh = File.open("lib/sadie/version.rb","w")
    fh.puts "class Sadie"
    fh.puts '  VERSION = "' + version + '"'
    fh.puts "end"
    fh.close
    puts "incremented sadie version to #{version}"
end

def current_sadie_version
    version = "0.0.0"
    File.open("lib/sadie/version.rb","r").each do |line|
        if matches = line.match(/version\s*\=\s*\"([^\"]+)\"/i)
            version = matches[1]
            break
        end
    end    
    version
end
