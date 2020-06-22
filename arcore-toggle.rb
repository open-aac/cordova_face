if ARGV[0] == 'enable'
  puts `cordova plugin add https://github.com/open-aac/cordova_face`
  `cp plugins/com.mycoughdrop.coughdrop.CoughDropFace/src/android/MainActivity.java platforms/android/app/src/main/java/com/mycoughdrop/coughdrop/MainActivity.java`
elsif ARGV[0] == 'disable'
  puts `cordova plugin remove com.mycoughdrop.coughdrop.CoughDropFace`
  `cp platforms/android/app/src/main/java/com/mycoughdrop/coughdrop/MainActivity.java.original platforms/android/app/src/main/java/com/mycoughdrop/coughdrop/MainActivity.java`
end
str = File.read(File.join('platforms', 'android', 'app', 'build.gradle'))
lines = str.split(/\n/)
commenting_out = false
updated_lines = []
lines.each do |line|
  if line.match(/ARCORE DEPENDENCIES START/)
    commenting_out = true
  elsif line.match(/ARCORE DEPENDENCIES END/)
    commenting_out = false
  elsif commenting_out
    if ARGV[0] == 'disable'
      line = "//" + line unless line.match(/^\/\//)
    elsif ARGV[0] == 'enable'
      line = line.sub(/^\/\//, '')
    end
  end
  updated_lines << line
end
File.write(File.join('platforms', 'android', 'app', 'build.gradle'), updated_lines.join("\n"))