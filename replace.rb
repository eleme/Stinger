#!/usr/bin/env ruby


headrs = Dir[File.join(Dir.pwd,"Stinger/libffi","**","**")].select { |e| 
 e.end_with?(".h")
}.map { |e|   File.basename(e) }

Dir[File.join(Dir.pwd,"Stinger/libffi","**","**")].select { |e| 
 e.end_with?(".h") || e.end_with?(".m") || e.end_with?(".c") 
}.each { |e|
  puts e
  if File.file?(e)
    text = ""
    File.open(e).each do |line|
      if line.include?("#include") && headrs.any? { |e| line.include?(e) } 
        text += line.gsub("<", "\"").gsub(">", "\"")
      else
        text += line
      end
    end
    File.open(e, "w") { |file| file.puts text }
  end
}