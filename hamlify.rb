#! /usr/bin/ruby

dirs = Dir["*"].select{|f| File.directory? f }

dirs.each do |dir|
  files = Dir["#{dir}/*"].each do |f|
    next unless f.end_with?('.haml')
    `haml #{f} #{f.sub(/\.haml$/, '.html')}`
  end
end
