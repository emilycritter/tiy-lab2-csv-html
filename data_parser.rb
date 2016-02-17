require 'csv'
require 'erb'

# ==================== read
the_html = File.read("report.template.html")

# Methods
def parse_data file_name
	parse_data_cont file_name, []
end
def parse_data_cont file_name, rows
  CSV.foreach(file_name, headers: true) do |row|
    shipment = row.to_hash
		shipment["Money"] = shipment["Money"].to_f
		shipment["Crates"] = shipment["Crates"].to_f
		rows << shipment
  end
  rows
end

def add_pilot ary_of_hsh
  ary_of_hsh.each do |hsh|
    case hsh["Destination"]
      when 'Earth'; hsh.merge!({"Pilot"=>"Fry"})
      when 'Mars'; hsh.merge!({"Pilot"=>"Amy"})
      when 'Uranus'; hsh.merge!({"Pilot"=>"Bender"})
      else; hsh.merge!({"Pilot"=>"Lela"})
    end
  end
  ary_of_hsh
end

def add_bonus ary_of_hsh
  ary_of_hsh.each do |hsh|
    hsh.merge!({"Bonus"=>"#{hsh["Money"]*0.1}"})
		hsh["Bonus"] = hsh["Bonus"].to_f
  end
end

def formatted_number(n)
	a,b = sprintf("%0.2f", n).split('.')
	a.gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
	"$#{a}.#{b}"
end

def pie_chart_prep ary_of_hsh, hsh_values, label, new_ary, theme_color
	new_ary = ary_of_hsh.map {|hsh| {value: hsh[hsh_values].to_f, label: "#{hsh[label]}"}}
	new_ary = ary_to_hex_ary(theme_color, new_ary)
	return new_ary
end

theme_color = '#60BBB2'
def darken_color(hex_color, amount)
  hex_color = hex_color.gsub('#','')
  rgb = hex_color.scan(/../).map {|color| color.hex}
  rgb[0] = (rgb[0].to_i * amount).round
  rgb[1] = (rgb[1].to_i * amount).round
  rgb[2] = (rgb[2].to_i * amount).round
  "#%02x%02x%02x" % rgb
end

def lighten_color(hex_color, amount)
  hex_color = hex_color.gsub('#','')
  rgb = hex_color.scan(/../).map {|color| color.hex}
  rgb[0] = [(rgb[0].to_i + 255 * amount).round, 255].min
  rgb[1] = [(rgb[1].to_i + 255 * amount).round, 255].min
  rgb[2] = [(rgb[2].to_i + 255 * amount).round, 255].min
  "#%02x%02x%02x" % rgb
end

def ary_to_hex_ary (hex, ary)
  percent = (1.00 / (ary.count + 1).to_f).round(2)
  light = lighten_color(hex, 0.2)
  new_ary = []
  ary.each_with_index do |hsh, i|
    dark = darken_color(light, percent*(i+1))
    hsh = hsh.merge({color: "#{dark}"})
    new_ary.push(hsh)
  end
  new_ary
end


records = parse_data 'planet_express_logs.csv' # Parse data
add_pilot records # Add pilot key
add_bonus records # Add bonus key

# Get weekly revenue
total_rev = (records.map {|records| records["Money"]}).reduce(:+)
total_rev = formatted_number(total_rev)

# Get number of crates
total_crates = (records.map {|records| records["Crates"]}).reduce(:+)

# Get bonuses paid
total_bonus = (records.map {|records| records["Bonus"]}).reduce(:+)
total_bonus = formatted_number(total_bonus)

# Get data for Delivery Summary table
del_sum_add_column = records.last
del_sum_add_column = del_sum_add_column
	.map {|hsh| hsh.to_a}
	.map {|key, value| "'#{value.class.to_s.downcase.gsub('float', 'number')}', '#{key}'"}

del_sum_add_rows = records.map do |hsh|
	hsh.values
end


# Create hashes with pilot summary values
pilot_ary = []
records.each do |hsh|
  pilot_new = {}
  pilot_new["Pilot "] = hsh["Pilot"]
  if pilot_ary.any? {|h| h["Pilot "] == hsh["Pilot"]}
  else
    pilot_new = {}
    pilot_new["Pilot "] = hsh["Pilot"]
    pilot_new["Delivery Total"] = records
      .select {|records| records["Pilot"] == hsh["Pilot"]}
      .map {|records| records["Money"].to_f}
      .reduce(:+)

    pilot_new["Bonus Total"] = records
      .select {|records| records["Pilot"] == hsh["Pilot"]}
      .map {|records| records["Bonus"].to_f}
      .reduce(:+)

    pilot_new["Delivery Count"] = records
      .select {|records| records["Pilot"] == hsh["Pilot"]}
      .map {|records| records["Pilot"]}
      .count.to_f
    pilot_ary << pilot_new
  end
end
pilot_ary = pilot_ary.sort{|x,y| x["Bonus Total"].to_f <=> y["Bonus Total"].to_f}

# Get data for Employee Summary table
emp_sum_add_column = pilot_ary.last
emp_sum_add_column = emp_sum_add_column
	.map {|hsh| hsh.to_a}
	.map {|key, value| "'#{value.class.to_s.downcase.gsub('float', 'number')}', '#{key}'"}

emp_sum_add_rows = pilot_ary.map do |hsh|
	hsh.values
end


pilot_pie_title = "Sales by Pilot"
pilot_pie = pie_chart_prep(pilot_ary, "Delivery Total", "Pilot ", [], theme_color)

# Create hashes with planet summary values
planet_ary = []
records.each do |hsh|
  planet_new = {}
  planet_new["Destination "] = hsh["Destination"]
  if planet_ary.any? {|h| h["Destination "] == hsh["Destination"]}
  else
    planet_new = {}
    planet_new["Destination "] = hsh["Destination"]
    planet_new["Delivery Total"] = records
      .select {|records| records["Destination"] == hsh["Destination"]}
      .map {|records| records["Money"].to_f}
      .reduce(:+)

    planet_new["Bonus Total"] = records
      .select {|records| records["Destination"] == hsh["Destination"]}
      .map {|records| records["Bonus"].to_f}
      .reduce(:+)

    planet_new["Delivery Count"] = records
      .select {|records| records["Destination"] == hsh["Destination"]}
      .map {|records| records["Pilot"]}
      .count.to_f
    planet_ary << planet_new
  end
end
planet_ary = planet_ary.sort{|x,y| x["Bonus Total"].to_i <=> y["Bonus Total"].to_i}

planet_pie_title = "Sales by Planet"
planet_pie = pie_chart_prep(planet_ary, "Delivery Total", "Destination ", [], theme_color)


# ==================== replace
new_html = ERB.new(the_html).result(binding)

# ==================== write
File.open('index.html', 'wb') do |file|
  file.write new_html
  file.close
end

# open file when run
system 'open index.html'
