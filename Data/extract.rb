require 'rubygems'
require 'bundler/setup'
require 'json'
require 'sort_alphabetical'

lines = File.readlines("espdic.txt")

eo_to_ens = Hash.new([])
en_to_eos = Hash.new([])

for line in lines
  eo, str = line.split(" : ").map(&:strip)
  if str
    ens = str.split(', ').map(&:strip)
    eo_to_ens[eo] = ens
    for en in ens
      en_to_eos[en] = en_to_eos[en] + [eo]
    end
  else
    puts "Skipping '#{eo}'"
  end
end

File.open("eo_to_ens.json", "w") { |f| f.write(eo_to_ens.to_json) }
File.open("en_to_eos.json", "w") { |f| f.write(en_to_eos.to_json) }
File.open("eos.txt", "w") { |f| f.write(eo_to_ens.keys.sort_alphabetical.join("\n")) }
File.open("ens.txt", "w") { |f| f.write(en_to_eos.keys.sort_alphabetical.join("\n")) }
