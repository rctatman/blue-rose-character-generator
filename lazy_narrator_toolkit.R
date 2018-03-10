# toolkit to help narrator generate character sheets

# package we'll use
library(tidyverse)
library(stringr)

# files with helpful info
callings <- read_csv("calling.csv")
destiny_and_fate <- read_csv("destiny_and_fate.csv")
roll_to_bonus <- read_csv("roll_to_bonus.csv")
stats_by_class <- read_csv("stats_by_class.csv")
talent_requirements <- read_csv("talent_requirements.csv")
# files with racial benefits tables
human_benefits_table <- read.csv("racial_benefits_tables/human.csv")
night_person_benefits_table <- read.csv("racial_benefits_tables/night_person.csv")
rhydan_benefits_table <- read.csv("racial_benefits_tables/rhydan.csv")
sea_folk_benefits_table <- read.csv("racial_benefits_tables/sea-folk.csv")
vata_benefits_table <- read.csv("racial_benefits_tables/vata.csv")

### rolling a character ###

# function that rolls 3 D6 & takes the sum
roll_stat <- function(){
  return(sum(sample(1:6, 3)))
}

# convert roll to appropriate bonus
stat_to_bonus <- function(roll){
  bonus <- roll_to_bonus$Bonus[roll_to_bonus$Roll == roll]
  return(bonus)
}

# This function rolls for a character & assigns stats in a 
# somewhat logical way depending on the intended class.
# Class must be one of adept, warrior or expert
character_stats <- function(class){
  
  # create data frame for our rolls
  rolls <- data_frame(rolls = 1:9, bonus = 1:9)
  
  # roll each stat
  for(i in 1:9){
    rolls$rolls[i] <- (roll_stat())
  }
  
  # convert to bonus
  for(i in 1:9){
    rolls$bonus[i] <- stat_to_bonus(rolls$rolls[i])
  }
  
  # get a sorted list of bonuses
  bonuses <- rolls %>%
    arrange(bonus) %>%
    select(bonus)
  
  # determine stat importance by intended class. The sample(9)
  # shuffles traits so, for instance, experts won't always have 
  # higher accuracy than any other stat
  if(class == "adept"){
    stat_importance <- stats_by_class %>%
      select(Stat, Adept) %>%
      arrange(sample(9)) %>%
      arrange(-Adept)
  }else if(class == "expert"){
    stat_importance <- stats_by_class %>%
      select(Stat, Expert) %>%
      arrange(sample(9)) %>%
      arrange(-Expert)
  }else if(class == "warrior"){
    stat_importance <- stats_by_class %>%
      select(Stat, Warrior) %>%
      arrange(sample(9)) %>%
      arrange(-Warrior)
  }else{
    return("Class must be 'adept', 'expert' or 'warrior'")
  }

  # assign bonuses, with primary class stats getting highst bonuses
  stats <- cbind(Stat = stat_importance$Stat, Bonus = bonuses)

  # sort stats alphabetically 
  stats <- stats%>%
      arrange(Stat)
  
  # return dataframe with character's stats :)
  return(stats)
}


### character traits (destiny, fate, calling) ###

# function to generate destiny, fate & calling
destiny_fate_calling <- function(){
  
  # randomly pick traits & whether 
  # destiny or fate is dominant
  calling <- sample(callings$Calling, 1)
  destiny <- sample(destiny_and_fate$Destiny, 1)
  fate <- sample(destiny_and_fate$Fate, 1)
  dominant <- sample(c("destiny","fate"), 1)

  # dataframe with all of our traits
  character_traits <- data_frame(traits = c("calling", "destiny", 
                                            "fate", "dominant"),
                                 quality = c(calling, destiny, 
                                             fate, dominant))
  
  return(character_traits)
}

### get racial bonuses ###
# includes defense & speed

# function to get racial bonuses, given race
racial_bonuses <- function(character_stats_input, race){
  if(race == "human"){
    return(human_stats(character_stats_input))    
  }else if(str_detect(race, "ight")){
    return(night_people_stats(character_stats_input))
  }else if(str_detect(race, "ea")){
    return(sea_folk_stats(character_stats_input))
  }else if(race == "rhydan"){
    return(rhydan_stats(character_stats_input))
  }else if(str_detect(race,"vata")){
    return(vata_stats(character_stats_input))
  }else(
    print("Please specify a valid race as a string.")
  )
}

# function to get two distinct benefits from a given benefit table
get_benefits_from_table <- function(table){
  # get two benefits from the table
  benefits <- sample(benefits_table$effect, 2)
  
  # make sure there are two unique benefits
  if(benefits[1] == benefits[2]){
    benefits <- sample(benefits_table$effect, 2)
  }
  
  # return benefits
  return(as.vector(benefits))
}

# check to see if a character doesn't fulfill stat
# requirements for any talents
check_talents <- function(input_stats){
  # merge character stats with requirements
  stats_with_reqs <- merge(input_stats,talent_requirements)
  # list of talents this character can't use
  cant_use <- stats_with_reqs$talent[stats_with_reqs$bonus < 
                                       stats_with_reqs$greater_than]
  # return a vector of talents this char can't use
  return(cant_use)
}

# human racial benefits, based on pre-rolled stats
human_stats <- function(input_stats){
  
  # add 1 to a random (any) trait
  free_stat <- paste("+1", sample(input_stats$Stat, 1))
  
  # pick a focus: Dexterity (Riding) or Constitution (Swimming)
  free_focus <- sample(c("Focus: Dexterity(riding)", 
                         "Focus: Constitution(swimming)"), 1)
  
  # speed = 10 + dex
  speed <- 10 + input_stats$bonus[input_stats$Stat == "Dexterity"]
  
  # defense = 10 + dex (plus sheild bonus)
  defense <- 10 + input_stats$bonus[input_stats$Stat == "Dexterity"]
  
  # two random human benefits
  benefits <- get_benefits_from_table(human_benefits_tablebenefits_table)
  
  # pull together all the racial benefits
  racial_benefits <- rbind(speed, defense, free_focus, free_stat, 
             benefit_1 = benefits[1], benefit_2 = benefits[2])
  
  return(racial_benefits)
}

night_people_stats <- function(input_stats){
  # add 1 to strength
  free_stat <- "+1 strength"
  
  # pick a focus: Constitution (Stamina) or Strength (Might).
  free_focus <- sample(c("Focus: Constitution(stamina)", 
                         "Focus: Strength(might)"),
                       1)
  
  # dark sight (30 yards in darkness), but are blinded
  # for one round when exposed to 
  racial_bonus <- "dark sight (30 yards in darkness), but you are blinded for one round when exposed to daylight"
  
  # speed = 10 + dex
  speed <- 10 + input_stats$bonus[input_stats$Stat == "Dexterity"]
  
  # defense = 10 + dex (plus sheild bonus)
  defense <- 10 + input_stats$bonus[input_stats$Stat == "Dexterity"]
  
  # roll twice on benfits table
  benefits <- get_benefits_from_table(night_person_benefits_table)
  
  # pull together all the racial benefits
  racial_benefits <- rbind(speed, defense, racial_bonus, 
                           free_focus, free_stat, 
                           benefit_1 = benefits[1], 
                           benefit_2 = benefits[2])
  
  return(racial_benefits)
}

rhydan_stats <- function(input_stats){
  # choisce of Intelligence (Natural
  # Lore) focus or any one Perception focus.
  free_focus <- sample(c("Focus: Intelligence(nautral lore)", 
                         "Focus: Perception(player's choice)"),
                       1)
  
  # Wepons groups: Natural Wepons, Brawling Wepons
  free_weapon_group_1 <- "Weapons group: natural weapons"
  free_weapon_group_2 <- "Weapons group: brawling weapons"
  
  # speed depends on type
  speed <- "Check type table (p. 38)"
  
  # defense = 10 + dex (plus sheild bonus)
  defense <- 10 + input_stats$bonus[input_stats$Stat == "Dexterity"]
  
  # novice degree of psychic talent. Arcanum:
  # Psychic Contact, Psychic Shield and Second Sight
  free_talent <- "Talent: Phychic(novice)"
  
  # roll twice on benefits table
  benefits <- get_benefits_from_table(rhydan_benefits_table)
  
  # pull together all the racial benefits
  racial_benefits <- rbind(speed, defense, free_focus, free_talent, 
                           free_weapon_group_1, free_weapon_group_2, 
                           benefit_1 = benefits[1], benefit_2 = benefits[2])
  
  return(racial_benefits)
}
 
sea_folk_stats <- function(input_stats){
  # +1 to constituation
  free_stat <- "+1 constitution"
  
  # speed = 10 + dex
  speed <- 10 + input_stats$bonus[input_stats$Stat == "Dexterity"]
  
  # defense = 10 + dex (plus sheild bonus)
  defense <- 10 + input_stats$bonus[input_stats$Stat == "Dexterity"]
  
  # dark sight (20 yards in darkness)
  racial_bonus <- "dark sight (20 yards in darkness)"
  
  # can hold breath 60 rounds + 6 * con
  breath_bonus <- 60 + (6 * input_stats$bonus[input_stats$Stat == "Constitution"])
  racial_bonus_2 <- paste("can hold your breath", breath_bonus,"rounds")
  
  # roll twice on benefits table
  benefits <- get_benefits_from_table(sea_folk_benefits_table)
  
  # pull together all the racial benefits
  racial_benefits <- rbind(speed, defense, racial_bonus, 
                           racial_bonus_2, free_stat, 
                           benefit_1 = benefits[1], 
                           benefit_2 = benefits[2])
  
  return(racial_benefits)
} 

vata_stats <- function(input_stats){
  # novice degree of Animism, Healing, 
  # Meditative, Psychic, Shaping, or Visionary
  
  # make sure this character can use their talents
  talent_list <- c("Talent: Animism(novice)", "Talent: Healing(novice)", 
                  "Talent: Meditative(novice)", "Talent: Psychic(novice)", 
                  "Talent: Shaping(novice)", "Talent: Visionary(novice)")
  # talents they can't use
  cant_use <- check_talents(input_stats)
  # remove from the list of talents
  talent_list <- talent_list[!str_detect(tolower(talent_list), cant_use)]
  
  # select a random talent
  talent <- sample(talent_list, 1)
  free_talent <- paste(talent, "(novice)")
  
  # speed = 10 + dex
  speed <- 10 + input_stats$bonus[input_stats$Stat == "Dexterity"]
  
  # defense = 10 + dex (plus sheild bonus)
  defense <- 10 + input_stats$bonus[input_stats$Stat == "Dexterity"]

  # dark sight (20 yards ofr vata'an, 30 for vata'sha),
  # vata'sha are blinded for one round in sudden daylight
  racial_bonus <- "dark sight (20 yards for vata'an, 30 for vata'sha), vata'sha are blinded for one round in sudden daylight"
  
  # Your Constitution ability is considered 2 points
  #  higher for any of the recovery formulas
  racial_bonus_2 <- "constitution ability is considered 2 points higher for any of the recovery formulas"
  
  # roll twice on benefits table
  benefits <- get_benefits_from_table(vata_benefits_table)
  
  # pull together all the racial benefits
  racial_benefits <- rbind(speed, defense, racial_bonus, 
                           racial_bonus_2, free_talent, 
                           benefit_1 = benefits[1], 
                           benefit_2 = benefits[2])
  
  # return the racial benefits
  return(racial_benefits)
} 


### class bonuses ###

# function to generate class bonuses based on race & class
class_bonuses <- function(input_stats, class, race = "human"){
  class <- tolower(class)
  
  # return bonuses based on class
  if(class == "adept"){
    return(adept_bonuses(input_stats))
  }else if(class == "expert"){
    return(expert_bonuses(input_stats))
  }else if(class == "warrior"){
    return(warrior_bonuses(input_stats, race))
  }else{
    print("Please enter a valid class: adept, expert or warrior.")
  }
}

# get adept bonuses
adept_bonuses <- function(input_stats){
  
  # starting health
  health <- 20 + input_stats$bonus[input_stats$Stat == "Constitution"] + sample(6,1)
  
  # weapons groups
  free_weapon_group_1 <- "Weapons group: staves"
  free_weapon_group_2 <- "Weapons group: brawling weapons"
  
  # talents. One random novice talent:
  arcane_talents <- c("Animism", "Arcane Training", "Healing",
                      "Meditative", "Shaping", "Psychic",
                      "Visionary", "Wild Arcane")
  
  # talents they can't use
  cant_use <- check_talents(input_stats)
  # remove from the list of talents
  arcane_talents <- arcane_talents[!str_detect(tolower(arcane_talents), cant_use)]
  
  selected_talents <- sample(arcane_talents, 2)
  free_talent_1 <- paste("Talent: ", selected_talents[1], "(novice)")
  free_talent_2 <- paste("Talent: ", selected_talents[1], "(novice)")
  
  # third free non-magical talent
  starting_talents <- c("Linguistics", "Lore", "Medicine", "Observation")
  # remove unusable talents from the list of talents
  starting_talents <- starting_talents[!str_detect(tolower(starting_talents), cant_use)]
  
  free_talent_3 <- paste("Talent: ", sample(starting_talents, 1), "(novice)")
  
  # special class bonus
  class_bonus <- "may use the Skillful Channeling arcane stunt for 1 SP instead of 2 & when using Powerful Channeling you get +1 free SP (must spend at least 1 SP)"
  
  # return class bonuses
  return(rbind(health, free_weapon_group_1, free_weapon_group_2, 
               free_talent_1, free_talent_2, free_talent_3,
               class_bonus))
}

# class bonuses for experts
expert_bonuses <- function(input_stats){
  
  # starting health
  health <- 25 + input_stats$bonus[input_stats$Stat == "Constitution"] + sample(6,1)
  
  # weapons groups
  free_weapon_group_1 <- "Weapons group: bows"
  free_weapon_group_2 <- "Weapons group: brawling weapons"
  free_weapon_group_3 <- "Weapons group: light blades"
  free_weapon_group_4 <- "Weapons group: staves"
  
  # starting talents
  starting_talents <- c("Animal Training", "Arcane Potential", "Carousing", 
                        "Contacts", "Intrigue", "Linguistics", "Medicine", 
                        "Oratory", "Performance", "Scouting", "Thievery")
  # talents they can't use
  cant_use <- check_talents(input_stats)
  # remove from the list of talents
  starting_talents <- starting_talents[!str_detect(tolower(starting_talents), cant_use)]
  # select appropriate talent
  free_talent <- paste("Talent: ", sample(starting_talents, 1), "(novice)")
  
  # starting bonuses
  expert_bonus_1 <- "once per round, add 1d6 to the damage of a sucessful attack if your dex > your target's"
  expert_bonus_2 <- "you are trained in Light Armor w/out need of the Armor Training talent"

  # return all our bonuses
  return(rbind(health, free_weapon_group_1, free_weapon_group_2, 
               free_weapon_group_3, free_weapon_group_4, free_talent,
               expert_bonus_1, expert_bonus_2))
}

# warrior bonuses are different for rhydan
warrior_bonuses <- function(input_stats, race){

  # starting health
  health <- 30 + input_stats$bonus[input_stats$Stat == "Constitution"] + sample(6,1)
  
  # all warriors start with brawling weapons
  free_weapon_group_1 <- "Weapons group: brawling weapons"
  
  # randomly pick three other weapons from starting list
  starting_weapons <- tolower(c("Axes", "Bludgeons", "Bows", "Heavy Blades",
  "Light Blades", "Polearms", "Staves"))
  starting_weapons_sample <- sample(starting_weapons, 3)
  
  free_weapon_group_2 <- paste("Weapons group:",starting_weapons_sample[1])
  free_weapon_group_3 <- paste("Weapons group:",starting_weapons_sample[2])
  free_weapon_group_4 <- paste("Weapons group:",starting_weapons_sample[3])
  
  # all style starting talents (warrior should start with one)
  style_talents <- c("Archery Style", "Dual Weapon Style", 
                     "Single  Weapon Style", "Thrown Weapon Style", 
                     "Two-Handed Style", "Unarmed Style", 
                     "Weapon and Shield Style")
  
  # non-style starting talents
  non_style_talents <- c("Arcane Potential", "Carousing",  "Quick Reflexes")
  # talents they can't use
  cant_use <- check_talents(input_stats)
  # remove from the list of talents
  non_style_talents <- non_style_talents[!str_detect(tolower(non_style_talents), 
                                                     cant_use)]
  
  
  # get rhydan warrior stats (slightly different)
  if(race == "rhydan"){
    free_talent_1 <- "Talent: Tooth and Claw(novice)"
    free_talent_2 <- paste("Talent:", sample(non_style_talents, 1), "(novice)")
    
    return(rbind(health, free_talent_1, free_talent_2, free_talent_3))
  }
 
  ## remove styles character can't actually learn
  # no archery if they don't know bows
  if(!"bows" %in% starting_weapons_sample){
    style_talents <- style_talents[style_talents != "Archery Style"] 
  }
  # no two-handed if they don't know the wepons or have the strength
  if(!sum(c("axes", "bludgeons", "heavy blades", "polearms") %in% starting_weapons_sample &&
         !(input_stats$bonus[input_stats$Stat == "Strength"] > 2))){
    style_talents <- style_talents[style_talents != "Two-Handed Style"] 
  }
  # no thrown weapons if you don't know a throwable wepon
  if(!sum(c("axes", "light blades", "polearms") %in% starting_weapons_sample)){
    style_talents <- style_talents[style_talents != "Thrown Weapon Style"] 
  }
  # can't use one weapon if you can't see good? I guess??
  if(!(input_stats$bonus[input_stats$Stat == "Perception"] > 1)){
    style_talents <- style_talents[style_talents != "Single  Weapon Style"] 
  }
  # can't use two wepons if your dex isn't high enough
  if(!(input_stats$bonus[input_stats$Stat == "Dexterity"] > 1)){
    style_talents <- style_talents[style_talents !=  "Dual Weapon Style"] 
  }
  # can't use weapon & sheild if you're not strong enough
  if(!(input_stats$bonus[input_stats$Stat == "Strength"] > 1)){
    style_talents <- style_talents[style_talents != "Weapon and Shield Style"] 
  }

  # get non-rhydan talents (may pick 2 styles if avalible)
  if(sample(3, 1) == 1){
    free_talent_1 <- paste("Talent:", sample(style_talents, 1), "(novice)")
    free_talent_2 <- paste("Talent:", sample(non_style_talents, 1), "(novice)")
  }else{
    # sample two possible (for this character) styles
    style_talents_sample <- sample(style_talents, 2)
    
    free_talent_1 <- paste("Talent:", style_talents_sample[1], "(novice)")
    free_talent_2 <- paste("Talent:", style_talents_sample[2], "(novice)")
  }
  
  # everybody gets armor training
  free_talent_3 <- "Talent: Armor Training(novice)"
  
  # and return all our bonuses
  return(rbind(health, free_weapon_group_1, free_weapon_group_2,
               free_weapon_group_3, free_weapon_group_4,  
               free_talent_1, free_talent_2, free_talent_3))
}

### generate a character ###

# randomly pick a race (most likely to pick human)
pick_race <- function(){
  races <- c(rep("human", 8), "night person", "sea person", "rhydan", "vata")
  return(sample(races, 1))
}

# randomly pick a starting class (unlikely to pick adept,
# on the logic that they're fairly rare in this world)
pick_class <- function(){
  classes <- c("adept",rep("expert", 3),rep("warrior", 3))
  return(sample(classes, 1))  
}

# function to generate a reasonable but random level 1 character based on a race and class
generate_character <- function(race, class){
  # generate character stats
  char_stats <- character_stats(class)
  
  # destiny fate and calling
  destiny_fate_calling <- destiny_fate_calling()
  
  # get racial & class bonuses
  race_bonuses <- racial_bonuses(char_stats, race)
  class_bonuses <- class_bonuses(char_stats, class, race)
  
  # combine race & class bonuses
  all_bonuses <- rbind(race_bonuses, class_bonuses)
  
  # all stat increases
  stat_increases <- all_bonuses[str_detect(all_bonuses, "plus one")]
  if(length(stat_increases) > 0){
    # get a list of stats
    all_stats <- stats_by_class$Stat %>% tolower() 
    
    # calculated the increase for each stat
    stat_increases <- str_count(stat_increases, all_stats)
    
    # update character's stats
    char_stats <- char_stats %>%
      mutate(bonus = bonus + stat_increases)
  }
  
  # get health, speed & defense
  health <- all_bonuses[dimnames(all_bonuses)[[1]] == "health"]
  speed <- all_bonuses[dimnames(all_bonuses)[[1]] == "speed"]
  defense <- all_bonuses[dimnames(all_bonuses)[[1]] == "defense"]
  
  # all secondary stats
  secondary_stats <- rbind(health, speed, defense)
  
  # all foci
  focuses <- unique(all_bonuses[str_detect(all_bonuses, "Focus")])
  
  # all weapon groups
  weapon_groups <- unique(all_bonuses[str_detect(all_bonuses, "group")])
  
  # all talents
  talents <- unique(all_bonuses[str_detect(all_bonuses, "alent:")])
  
  # all racial bonuses
  bonuses <- all_bonuses[str_detect(dimnames(all_bonuses)[[1]], "bonus")]
  
  # final output
  character_sheet <- list(race = race, 
                          class = class,
                          basic_stats = char_stats, 
                          secondary_stats = secondary_stats, 
                          destiny_fate_calling = as.data.frame(destiny_fate_calling), 
                          "focuses(+2 on relevent rolls)" = focuses, 
                          weapon_groups = weapon_groups,  
                          talents = talents, 
                          other_bonuses = bonuses)
  
  return(character_sheet)
}

# one fully random character, coming right up! :)
random_race <- pick_race()
random_class <- pick_class()
generate_character(race = random_race, class = random_class)

# save a file with a human expert
char <- generate_character(race = "human", class = "expert")
capture.output(char, file = "sample_character_sheet.txt")
