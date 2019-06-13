#! /usr/bin/ruby

dir = ARGV[0]

files = Dir["#{dir}/*"]
charsheets = []

class CharSheet
  attr_reader :path, :filename, :character, :version

  def initialize(path)
    @path = path
    @filename = path.split('/').last
    character = @filename.split('-')[0...-1].join(' ')
    version = @filename.split('-')[-1].split('.')[0..1].join('.')
    @character = character
    @version = version.to_f
  end
end

files.each do |file|
  next if file =~ /index\.html$/
  next unless file.end_with?('.html')
  next unless file =~ /\d+\.\d+\.html$/
  charsheets << CharSheet.new(file)
end

links = []
charsheets.group_by(&:character).each do |key, sheets|
  `cp #{sheets.sort_by(&:version).last.path} #{dir}/#{key.downcase.gsub(' ', '-')}.html`
  html = "<h1><a href=\"#{key}.html\">#{key.capitalize}</a></h1>"
  html << "<h4>previous versions</h4>"
  html << sheets.sort_by(&:version).reverse.map { |sheet| "<p><a href=\"#{sheet.filename}\">#{sheet.version}\</a></p>" }.join
  links << html
end

if dir =~ /^pregen/
  # we want a different index for pregen characters
  links = []
  charsheets.group_by(&:character).each do |key, sheets|
    `cp #{sheets.sort_by(&:version).first.path} #{dir}/#{key.downcase.gsub(' ', '-')}.html`
    html = "<h1><a href=\"#{key.downcase.gsub(' ', '-')}.html\">#{key.capitalize}</a></h1>"
    html << "<h4>leveled versions</h4>"
    html << sheets.sort_by(&:version).map { |sheet| "<p><a href=\"#{sheet.filename}\">#{sheet.version}\</a></p>" }.join
    links << html
  end
end

File.open(dir + '/index.html', 'w+') do |file|
  html = <<HTML
<!DOCTYPE html>
<head>
  <style>
    body { margin: 2rem; }
    h1 { margin: 0; }
    h4 { margin: 0 1rem; }
    p { margin: 0 1rem; }
  </style>
</head>
<body>
#{links.join}
</body>
HTML
  file.write(html)
end
