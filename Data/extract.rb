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
    ens = str.split(/,(?![^(]*\))/).map(&:strip).reject(&:empty?)
    eo_to_ens[eo] = ens
    for en in ens
      en_to_eos[en] = en_to_eos[en] + [eo]
    end
  else
    puts "Skipping '#{eo}'"
  end
end

sorter = lambda {|a, b| SortAlphabetical.normalize(a.downcase) <=> SortAlphabetical.normalize(b.downcase) }

puts "Creating eo_to_ens.json..."
File.open("../Vortaro/eo_to_ens.json", "w") { |f| f.write(eo_to_ens.to_json) }
puts "Creating en_to_eos.json..."
File.open("../Vortaro/en_to_eos.json", "w") { |f| f.write(en_to_eos.to_json) }
puts "Creating eos.txt..."
File.open("../Vortaro/eos.txt", "w") { |f| f.write(eo_to_ens.keys.sort(&sorter).join("\n")) }
puts "Creating ens.txt..."
File.open("../Vortaro/ens.txt", "w") { |f| f.write(en_to_eos.keys.sort(&sorter).join("\n")) }
