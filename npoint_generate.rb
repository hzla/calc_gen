require_relative 'helpers'
require 'json'
require_relative 'inc_converter'


dex_data = File.readlines('../armips/data/mondata.s')
move_data = File.readlines('../armips/data/moves.s')
set_data = File.readlines('../armips/data/trainers/trainers.s')
ls_data = File.readlines('../armips/data/levelupdata.s')
tm_data = File.readlines('../armips/data/tmlearnset.txt')
tutor_data = File.readlines('../armips/data/tutordata.txt')
enc_data = File.readlines('../armips/data/encounters.s')

poks = {}
pok_names = {}
ordered_poks = []

npoint_moves = {}
move_names = {}
ordered_moves = []
ordered_growths = []
sets = {}

encounters = {}

current_pok = nil
stat_names = ["hp", "at", "df", "sp", "sa", "sd"]
growths = {"GROWTH_MEDIUM_FAST" => 0, "GROWTH_ERRATIC" => 1, "GROWTH_FLUCTUATING" => 2, "GROWTH_MEDIUM_SLOW" => 3, "GROWTH_FAST" => 4, "GROWTH_SLOW" => 5}

forms = form_info



i = 0
while i < dex_data.length
	
	line = dex_data[i].strip

	# set current mon 
	if line[0..6] == "mondata"
		# Remove comments
  		line = line.split('//').first.strip


		pok_variable_name = line.split("\"")[0].split(" ")[-1][0..-2]
		pok_name = line.split("\"")[-1].gsub("♂", "-M").gsub("♀", "-F")

		#handle megas
		if pok_variable_name.include?("_MEGA_")
			pok_name = pok_variable_name.split("SPECIES_MEGA_")[-1].downcase.capitalize + "-Mega"
			pok_name = pok_name.gsub("_y-Mega", "-Mega-Y").gsub("_x-Mega", "-Mega-X") #handle charizard/mewtwo
		end

		#attempt to guess form names
		if pok_name == "-----" && pok_variable_name != ""
			pok_name = pok_variable_name.split("SPECIES_")[-1].downcase.capitalize.gsub("_galarian", "-Galar").gsub("_alolan", "-Alola").gsub("_paldean", "-Paldea")
		end
		
		current_pok = pok_name
		poks[pok_name] = {}
		pok_names[pok_variable_name] = pok_name
		ordered_poks << pok_name
	end

	i += 1
	# skip lines until next pokemon is found
	next if !current_pok 

	

	# set stats if unset
	if line[0..3] == "base" && !poks[current_pok]["bs"]
		stat_values = line[10..-1].split(",").map(&:strip).map(&:to_i)
		poks[current_pok]["bs"] = {}
		(0..5).each do |n|
			poks[current_pok]["bs"][stat_names[n]] = stat_values[n]
		end
	end



	if line.include?("growthrate")
		growth = growths[line.split(" ")[1].strip]
		ordered_growths << growth
	end

	#set typing if unset
	if line[0..3] == "type" && !poks[current_pok]["types"]
		types = line[5..-1].split(",").map(&:strip).map do |type|
			type[5..-1].downcase.capitalize
		end
		poks[current_pok]["types"] = types.uniq.map do |type|
			type.include?("type_fairy") ? "Fairy" : type
		end
		
	end

	if line[0..3] == "abil" && !poks[current_pok]["abs"]
		abilities = line.split(" ABILITY_")[1..2].map do |ab|
			showdown_parse(ab.gsub(",",""))
		end

		poks[current_pok]["abs"] = abilities
		current_pok = nil
	end
end


i = 0
current_move = nil
while i < move_data.length
	line = move_data[i].split('/*').first.strip

	#set current move
	if line[0..7] == "movedata"
		move_variable_name = line.split("\"")[0].split(" ")[-1][0..-2]
		move_name = line.split("\"")[-1]
		current_move = move_name
		npoint_moves[move_name] = {}
		move_names[move_variable_name] = move_name
		ordered_moves << move_name
	end

	i += 1
	next if !current_move

	# set category 
	if line[0..2] == "pss" 
		category = line[10..-1].downcase.capitalize
		npoint_moves[current_move]["category"] = category
	end

	# set basePower
	if line[0..3] == "base" 
		bp = line[10..-1].strip.to_i
		npoint_moves[current_move]["basePower"] = bp
	end

	# set type
	if line[0..3] == "type" 
		type = line[10..-1].downcase.capitalize
		npoint_moves[current_move]["type"] = type.split(" ")[0].gsub("Y_type_implemented)", "Fairy")
	end
end


i = 0
current_set = nil
current_tr_title = nil
current_battle_type = nil
current_tr_id = nil
current_sub_index = 0
set_constants = {}
trainer_counts = {}

rival_index = 0
male_rival = "Ethan"
female_rival = "Lyra"
passerby_rival = "Silver"



## set data
while i < set_data.length
	line = set_data[i].strip

	if line.include?("equ")
		constant_name = line.split("equ")[0].strip
		begin
			constant_value = line.split("equ")[1].split(" ")[0].to_i
		rescue
			p "constant processing error: #{line}"
			constant_value = 0
		end
		set_constants[constant_name] = constant_value
	end


	if line[0..10] == "trainerdata" 
		current_tr_id = line.split(",")[0].split(" ")[-1].to_i
		tr_name = line.split("\"")[-1]


		# indicate starter choice for rival battles
		

		tr_class = set_data[i + 2].split("CLASS_")[-1].downcase.split("_").map(&:capitalize).join(" ").strip

		tr_class = "" if tr_class == tr_name

		tr_title = "#{tr_class} #{tr_name}"

		if tr_title.include?(male_rival) || tr_title.include?(male_rival) || tr_title.include?(passerby_rival)
			tr_title += " |Starter #{rival_index % 3 + 1}|"
			rival_index += 1
		end

		# cleanup trainer classes with numbers in them
		tr_title = tr_title.gsub(/ \d+ /, ' ')

		trainer_counts[tr_title] ||= 0
		trainer_counts[tr_title] += 1

		
		if trainer_counts[tr_title] > 1
			tr_title += "#{trainer_counts[tr_title]} "
		end

		current_tr_title = tr_title


		j = 0

		until set_data[i + j].include?("endentry")
			if set_data[i + j].include?("battletype")
				current_battle_type = set_data[i + j].include?("SINGLE") ? "Singles" : "Doubles"
			end
			j += 1
		end

		current_sub_index = 0
	end




	if line.include?("// mon")
		i += 1
		
		ivs = {}
		species = ""
		item = ""
		moves = []
		ability = ""
		nature = "Hardy"


		line = set_data[i]

		until line.include?("// mon")
			
			if line.include?("monwithform")
				form_index = line.split(",")[-1].strip.to_i
				species = pok_names[line.strip.split(" ")[1].strip.gsub(",","")]
				if forms[species]
					species = "#{species}-#{forms[species][form_index - 1]}"
				end
			end

			if line.include?("level ")
				level = parse_level set_constants, line
			end



			if line.include?("pokemon ")
				species = pok_names[line.strip.split(" ")[1].strip.gsub(",","")]
			end

			if line.include?("setivs ")
				ivs = {}
				iv_values = line.strip[7..-1].split(",").map(&:strip).map(&:to_i)
				(0..5).each do |n|
					ivs[stat_names[n]] = iv_values[n]
				end
			end

			if line.include?("item ITEM")
				item = showdown_parse line.gsub("item ", "").split("ITEM_")[-1].strip.gsub("Never Melt", "Never-Melt").gsub("Heavy Duty", "Heavy-Duty")
				item = "" if item == "0"
				if item[-3..-1] == "ite" && item != "Eviolite"
					species = "#{species}-Mega"
				end
				species = "#{species}-Mega-X" if item[-5..-1] == "ite X"
				species = "#{species}-Mega-Y" if item[-5..-1] == "ite Y"
			end


			if line.include?("move MOVE")
				move1 = move_names[parse_move(set_data[i].strip.split("move ")[1])]
				move2 = move_names[parse_move(set_data[i + 1].strip.split("move ")[1])]
				move3 = move_names[parse_move(set_data[i + 2].strip.split("move ")[1])]
				move4 = move_names[parse_move(set_data[i + 3].strip.split("move ")[1])]

				moves = [move1 || "", move2 || "", move3 || "", move4 || ""]
				i += 3
			end

			if line.include?("ability ABILITY")
				ability = parse_ability line
			end

			if line.include?("nature NATURE")
				nature = line.strip[14..-1].downcase.capitalize
			end

			i += 1
			line = set_data[i]
		end

		sets[species] ||= {}
		set_name = "Lvl #{level} #{current_tr_title}"
		sets[species][set_name] = {
			"ivs": ivs, 
			"item": item,
			"level": level,
			"moves": moves,
			"tr_id": current_tr_id,
			"nature": nature,
			"ability": ability,
			"sub_index": current_sub_index,
			"battle_type": current_battle_type,
		}
		current_sub_index += 1
	end



	# relies on consistent formatting
	# if line[0..4] == "level"
	# 	level = parse_level set_constants, line


	# 	# handle forms
	# 	if set_data[i + 1].include?("monwithform")
	# 		form_index = set_data[i + 1].split(",")[-1].strip.to_i
	# 		species = pok_names[set_data[i + 1].strip.split(" ")[1].strip.gsub(",","")]
	# 		if forms[species]
	# 			species = "#{species}-#{forms[species][form_index - 1]}"
	# 		end
			
	# 	else
	# 		species = pok_names[set_data[i + 1].strip.split(" ")[1].strip.gsub(",","")]
	# 	end
			
		
	# 	item = showdown_parse set_data[i + 2].gsub("item ", "").split("ITEM_")[-1].strip
	# 	item = "" if item == "0"

	# 	item = item.gsub("Never Melt", "Never-Melt").gsub("Heavy Duty", "Heavy-Duty")



	# 	# handle megas
	# 	if item[-3..-1] == "ite" && item != "Eviolite"
	# 		species = "#{species}-Mega"
	# 	end

	# 	species = "#{species}-Mega-X" if item[-5..-1] == "ite X"
	# 	species = "#{species}-Mega-Y" if item[-5..-1] == "ite Y"


	# 	begin
	# 		move1 = move_names[parse_move(set_data[i + 3].strip.split("move ")[1])]
	# 		move2 = move_names[parse_move(set_data[i + 4].strip.split("move ")[1])]
	# 		move3 = move_names[parse_move(set_data[i + 5].strip.split("move ")[1])]
	# 		move4 = move_names[parse_move(set_data[i + 6].strip.split("move ")[1])]

	# 		moves = [move1 || "", move2 || "", move3 || "", move4 || ""]
	# 	rescue
	# 		p "no moves detected for trainer #{tr_name}"
	# 		moves = ["", "", "", ""]
	# 	end

	# 	ability = parse_ability set_data[i + 7]

	# 	ivs = {}
	# 	iv_values = set_data[i+9].strip[7..-1].split(",").map(&:strip).map(&:to_i)
	# 	(0..5).each do |n|
	# 		ivs[stat_names[n]] = iv_values[n]
	# 	end

	# 	p set_data[i + 11]

	# 	nature = set_data[i + 11].strip[14..-1].downcase.capitalize

		

	# 	sets[species] ||= {}
	# 	set_name = "Lvl #{level} #{current_tr_title}"
	# 	sets[species][set_name] = {
	# 		"ivs": ivs, 
	# 		"item": item,
	# 		"level": level,
	# 		"moves": moves,
	# 		"tr_id": current_tr_id,
	# 		"nature": nature,
	# 		"ability": ability,
	# 		"sub_index": current_sub_index,
	# 		"battle_type": current_battle_type,
	# 	}
	# 	current_sub_index += 1
	# end 
	i += 1
	break if i >= 44644
end



i = 0
current_pok = ""
current_ls = []


ordered_items = get_constants "../asm/include/items.inc", "ITEM"
ordered_abilities = get_constants "../asm/include/abilities.inc", "ABILITY"
includes = {"poks" => ordered_poks, "moves" => ordered_moves, "abilities" => ordered_abilities, "items" => ordered_items, "growths" => ordered_growths}

while i < ls_data.length
	line = ls_data[i].strip

	if line.include?("levelup")
		pok_variable_name = line.split(" ")[1]
		pok_name = pok_names[pok_variable_name] 

		if !pok_name
			break
		end

		current_ls = []
		current_pok = pok_name
	end

	if line.include?("learnset MOVE")
		move_variable_name = line.split(" ")[1][0..-2]
		lvl_learned = line.split(", ")[-1].to_i
		current_ls << [lvl_learned, move_names[move_variable_name]]
	end

	if line.include?("terminate")
		poks[current_pok]["learnset_info"] ||= {}
		poks[current_pok]["learnset_info"]["ls"] = current_ls 
	end

	i += 1
end


i = 0
current_tm = ""
while i < tm_data.length
	line = tm_data[i].strip

	if line.include?("MOVE_")
		move_variable_name = line.split(" ")[1]
		move_name = move_names[move_variable_name] 

		current_tm = move_name
	end

	if line.include?("SPECIES_")
		pok_variable_name = line.strip
		pok_name = pok_names[pok_variable_name]
		begin
			poks[pok_name]["learnset_info"]["tms"] ||= []
		rescue
			# p "Could not find #{pok_name}"
			i += 1
			next
		end
		poks[pok_name]["learnset_info"]["tms"] << current_tm
	end

	i += 1
end

i = 0
current_tutor = ""
while i < tutor_data.length
	line = tutor_data[i].strip

	if line.include?("MOVE_")
		move_variable_name = line.split(" ")[1]
		move_name = move_names[move_variable_name] 

		current_tutor = move_name
	end

	if line.include?("SPECIES_")
		pok_variable_name = line.strip
		pok_name = pok_names[pok_variable_name]
		begin
			poks[pok_name]["learnset_info"]["tutors"] ||= []
		rescue
			# p "Could not find #{pok_name}"
			i += 1
			next
		end
		poks[pok_name]["learnset_info"]["tutors"] << current_tutor
	end

	i += 1
end


npoint_data = {"poks" => poks, "moves" => npoint_moves, "formatted_sets" => sets, "includes" => includes}
File.write("./npoint.json", JSON.pretty_generate(npoint_data))










