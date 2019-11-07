#! /usr/bin/env ruby

require 'toml-rb'

list = ARGV[0]
out = ARGV[1]
first = ARGV[2].to_i
last = ARGV[3].to_i
extras = ARGV[4..-1]

puts "Writing #{list} spell cards to #{out}."
puts "Including #{extras} as additional #{list} spells."

spells = []

(first..last).each do |level|
  Dir["data/spells/#{level}/*"].each do |spell|
    begin
      spell = TomlRB.load_file(spell)
    rescue TomlRB::ParseError => ex
      puts "parse error in #{spell}: #{ex}"
      exit
    end
    lists = spell['metadata']['lists']

    spells << spell if extras.include?(spell['id']) || (spell['metadata']['lists'].include?(list) && level > 0)
  end
end

haml = ".spell-list.flex\n"

def to_string(level)
  return 'cantrip' if level == 0
  case level
  when 1
    '1<sup>st</sup>'
  when 2
    '2<sup>nd</sup>'
  when 3
    '3<sup>rd</sup>'
  else
    level.to_s + '<sup>th</sup>'
  end
end

def spell_to_haml(spell)
  level = spell['text']['level']
  name = spell['text']['name'].strip
  school = spell['text']['school']
  school = level == 0 ? school.capitalize + ' cantrip' : to_string(level) + '-level ' + school
  ritual = spell['text']['ritual']
  school << ' (ritual)' if ritual
  casting_time = spell['text']['casting_time']
  range = spell['text']['range']
  duration = spell['text']['duration']
  components = spell['text']['components'].join(', ')
  components << "(#{spell['text']['material']})" if components.include?('M')
  card = <<SPELL

    .card
      %h3 #{name}
      .level #{level}
      .school #{school}
      .casting-time #{casting_time}
      .range #{range}
      .components #{components}
      .duration #{duration}
SPELL
begin
  paragraphs = paragraphize(spell['text']['description'])
  paragraphs << add_title(paragraphize(spell['text']['at_higher_levels']), 'At Higher Levels') if spell['text']['at_higher_levels']
rescue Exception => e
  puts "Error in #{name}:"
  throw e
end
  card << paragraphs
  card
end

def paragraphize(paragraphs)
  paragraphs.map do |p|
<<P
      %p
        #{p}
P
  end.join("\n")
end

def add_title(paragraph, title)
  subparagraphs = paragraph.split("\n")
  markup = subparagraphs.shift
  title = markup.sub("%p", "  %span.title #{title}.")
  subparagraphs.unshift(title)
  subparagraphs.unshift(markup)
  subparagraphs.join("\n")
end

haml = <<HAML
!!!
%head
  %title Spell Cards
  %link{rel: 'stylesheet', type: 'text/css', href: '../charsheet.css'}
%body
  .flex.spell-cards
HAML


spells.sort_by { |spell| spell['text']['description'].join("\n").length }.each_slice(4) do |page|
  page.each do |spell|
    haml << spell_to_haml(spell)
  end
  haml << "\n    .blank-page\n"
end

File.open(out, 'w+') do |f|
  f.write haml
end
