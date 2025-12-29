require 'pry'


def gender_table
  [0,1,0,1,0,1,0,1,1,0,1,0,0,1,0,0,0,1,1,0,0,1,1,0,0,1,1,0,0,0,1,0,0,1,0,1,1,0,0,0,1,0,0,1,0,1,0,1,0,0,1,0,0,0,1,0,1,0,0,0,0,1,1,0,0,0,0,1,0,0,1,0,0,0,1,0,1,1,0,0,1,0,1,0,1,1,0,1,1,2,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,1,1,0,0,0,0,2,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,1,1,0,0,0,0,2,2,1,1,0,1,2,2,0,0,0,2,1,0,0,2,2,0]
end

def parse_level(set_constants, level_data)
  level_data = level_data.split("level ")[-1].strip
  level_value = 1

  if is_int?(level_data)
    return Integer(level_data)
  else
    # If just a variable name
    if set_constants[level_data]
      return set_constants[level_data]
    end

    if level_data.include?("+")
      level_mod = level_data.split("+")[-1].strip
      constant_name = level_data.split("+")[0].strip
    elsif level_data.include?("-")
      level_mod = 0 - level_data.split("-")[-1].strip.to_i
      constant_name = level_data.split("-")[0].strip
    end

    if is_int?(level_mod)
      level_mod = Integer(level_mod)
    else
      level_mod = 0
    end

    if set_constants[constant_name]
      level_value = set_constants[constant_name] + level_mod
    end
  end

  level_value
end

def showdown_parse(str)
  substitutions = {
    "minds eye" => "Mind's Eye",
    "heavy duty" => "Heavy-Duty",
    "never melt" => "Never-Melt",
    "well baked" => "Well-Baked",
    "rks system" => "RKS System",
    "soul heart" => "Soul-Heart"
  }

  formatted_str = str.downcase.split("_").map(&:capitalize).join(" ")

  # Use a single regex to find all keys and replace them
  formatted_str.gsub(/\b(#{substitutions.keys.join('|')})\b/i) do |match|
    substitutions[match.downcase]
  end
end


def parse_ability(str)
  return false if !str.downcase.include?("ability")
  if str.include?(":")
    ability = str.split("? ")[-1].split(" : ")[0]
  else
    ability = str.split(" ")[1].strip
  end

  showdown_parse(ability.gsub("ABILITY_", ""))
end

def parse_move(str)
  if str.include?(":")
    move = str.split("? ")[-1].split(" : ")[0]
  else
    move = str
  end


  move
end

def self.get_nature_id level, species, difficulty, trainer_id, trainer_class, gender, ability
    seed = (level + species + difficulty + trainer_id).to_s(16)


    trainer_class.times do 
      seed = seed.to_i 16
      result = 0x41C64E6D * seed + 0x00006073
      seed = result.to_s(16)[-8..-1]
    end
    # binding.pry
    result = seed[0...-4]

    if result != ""
      mid_bytes = result[-4..-1]
    else
      mid_bytes = seed
    end
    low_bytes = gender == "male" ? "88" : "78"
    high_bytes = "00"

    pid =  high_bytes + mid_bytes + low_bytes

    ab = ability > 0 ? 1 : 0

    # add ab if hgss
    nature_id = ((pid.to_i(16).to_s[-2..-1].to_i) + ab) % 25

    nature_id
  end


def is_int?(str)
  Integer(str) rescue false
end


def self.form_info
    forms = {}
    forms["Deoxys"] = ['Attack', 'Defense', 'Speed']
    forms["Shaymin"] = ["Sky"]
    forms["Giratina"] = ["Origin"]
    forms["Rotom"] = ["Heat", "Wash", "Frost", "Fan", "Mow"]
    forms["Castorm"] = ["Sunny", "Rainy", "Snowy"]
    forms["Basculin"] = ["Blue-Striped"]
    forms["Darmanitan"] = ["Zen"]
    forms["Meloetta"] = ["Pirouette"]
    forms["Kyurem"] = ["White", "Black"]
    forms["Keldeo"] = ["Resolute"]
    forms["Tornadus"] = ["Therian"]
    forms["Thundurus"] = ["Therian"]
    forms["Landorus"] = ["Therian"]
    forms["Wormadam"] = ["Sandy", "Trash"]
    forms["Genesect"] = ["Douse", "Chill", "Burn", "Shock"]
    forms["Kyogre"] = ["Primal"]
    forms["Groudon"] = ["Primal"]
    ["Rattata", "Raticate", "Raichu", "Sandshrew", "Sandslash", "Vulpix","Ninetales", "Diglett", "Dugtrio","Meowth", "Persian", "Geodude", "Graveler", "Golem", "Grimer", "Muk", "Exeggutor", "Marowak"].each do |species|
      forms[species] ||= []
      forms[species] << "Alola"
    end

    ["Ponyta", "Rapidash", "Slowpoke", "Slowbro", "Farfetch’d", "Weezing", "Mr. Mime", "Articuno", "Zapdos", "Moltres", "Slowking", "Corsola", "Zigzagoon", "Linoone", "Darumaka", "Darmanitan","Yamask", "Stunfisk"].each do |species|
      forms[species] ||= []
      forms[species] << "Galar"
    end
    

    forms
end

class String
  def titleize
    if !self 
      return "-"
    end
    downcase.gsub("-", " ").split(/([ _-])/).map(&:capitalize).join
  end

  def is_integer?
    self.to_i.to_s == self
  end

  def clean
    self.gsub(/[^a-zA-Z0-9]/, '').downcase
  end

  def move_titleize
    if !self 
      return ""
    end
    downcase.split(/([ _-])/).map(&:capitalize).join
  end

  def name_titleize
    if !self 
      return ""
    end
    downcase.split(/(?<=[ _-])/).map(&:capitalize).join
  end

  def move_untitleize
    upcase
  end

  def squish!
    gsub!("\n", '')
    self
  end

  def smogonlize
    downcase.gsub("-", "").gsub(" ", "").gsub("'","")
  end
end


