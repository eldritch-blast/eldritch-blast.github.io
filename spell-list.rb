#! /usr/bin/env ruby

require 'toml-rb'

list = ARGV[0]
out = ARGV[1]
first = ARGV[2].to_i
last = ARGV[3].to_i
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
      .level #{to_string(level)}
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

if spells.include?('bonus')
haml << <<HAML
  .other-spells.column
    .head.b Bonus Actions
HAML

  spells['bonus'].sort_by { |spell| [spell['text']['level'], spell['text']['name']] }.each do |spell|
    haml << spell_to_haml(spell, extras.include?(spell['id']))
  end
end

if spells.include?('reaction')
  haml << <<HAML
    .head.b Reactions
HAML

  spells['reaction'].sort_by { |spell| [spell['text']['level'], spell['text']['name']] }.each do |spell|
    haml << spell_to_haml(spell, extras.include?(spell['id']))
  end
end

if spells.include?('non-combat')
haml << <<HAML
    .head.b Non-Combat Spells
HAML

  spells['non-combat'].sort_by { |spell| [spell['text']['level'], spell['text']['name']] }.each do |spell|
    haml << spell_to_haml(spell, extras.include?(spell['id']))
  end
end

File.open(out, 'w+') do |f|
  f.write haml
end
