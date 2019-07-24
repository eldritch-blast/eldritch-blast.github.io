#! /usr/bin/env ruby

dir = ARGV[0]

files = Dir["#{dir}/*"].each do |f|
  next unless f.end_with?('.haml')
  `haml #{f} #{f.sub(/\.haml$/, '.html')}`
end
