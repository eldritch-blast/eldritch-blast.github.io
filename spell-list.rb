#! /usr/bin/ruby

require 'toml-rb'

list = ARGV[0]
out = ARGV[1]
first = ARGV[2]
last = ARGV[3]
extras = ARGV[4..-1]

puts "Writing #{list} spell list to #{out}."
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
    spells << spell if spell['metadata']['lists'].include?(list) || extras.include?(spell['id'])
  end
end

haml = ".spell-list.flex\n"

def ord(level)
  case level
  when 1
    'st'
  when 2
    'nd'
  when 3
    'rd'
  else
    'th'
  end
end

def spell_to_haml(spell, prepared)
  keywords = []
  keywords << 'conc.' if spell['text']['duration'].start_with?('Concentration')
  keywords << 'ritual' if spell['text']['ritual']
  level = spell['text']['level']
  name = spell['text']['name'].strip
<<SPELL
    .spell
      .prepared
        .checkbox#{'.checked' if prepared}
      .title #{name}
      .level #{level}<sup>#{ord(level)}</sup>
      .keywords.b #{keywords.join(', ')}
SPELL
end

spells = spells.group_by { |spell| spell['metadata']['action'] }

haml << <<HAML
  .spell-actions.column
    .head.b Spell Actions
HAML

spells['action'].sort_by { |spell| [spell['text']['level'], spell['text']['name']] }.each do |spell|
  haml << spell_to_haml(spell, extras.include?(spell['id']))
end

haml << <<HAML
  .other-spells.column
    .head.b Bonus Actions
HAML

spells['bonus'].sort_by { |spell| [spell['text']['level'], spell['text']['name']] }.each do |spell|
  haml << spell_to_haml(spell, extras.include?(spell['id']))
end

if spells.include?('reaction')
  haml << <<HAML
    .head.b Reactions
HAML

  spells['reaction'].sort_by { |spell| [spell['text']['level'], spell['text']['name']] }.each do |spell|
    haml << spell_to_haml(spell, extras.include?(spell['id']))
  end
end

haml << <<HAML
    .head.b Non-Combat Spells
HAML

spells['non-combat'].sort_by { |spell| [spell['text']['level'], spell['text']['name']] }.each do |spell|
  haml << spell_to_haml(spell, extras.include?(spell['id']))
end

File.open(out, 'w+') do |f|
  f.write haml
end
