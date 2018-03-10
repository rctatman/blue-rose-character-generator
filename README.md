A simple R script &amp; files to automatically generate level 1 Blue Rose characters in a somewhat logical way, because I'm a lazy, lazy ~~GM~~ Narrator.

It ain't pretty, but it works.

## To use:

* Clone or download the repo. 
* If using R Studio, open the blue-rose.Rproj file as a project.
* Run the entire lazy_narrator_toolkit.R file
* You can then generate a level one character like so:

```R
# to generate a character of a random race & class (weighted towards
# humans for race and warriors & experts for class)
random_race <- pick_race()
random_class <- pick_class()
generate_character(race = random_race, class = random_class)

# generate a human warrior character
generate_character(race = "human", class = "warrior")
```
* It will return a list with the following items (existent but blank where applicable):
   * race                          
   * class                         
   * basic_stats                  
   * secondary_stats               
   * destiny_fate_calling (ignore "dominant" for player characters)
   * focuses
   * weapon_groups                 
   * talents                      
   * other_bonuses        
* You can save your characters by assigning your generated characters to a variable and then saving them like so:

```R
# generate character sheet for level 1 Vata Adept & 
# save to the current working directory as a file "sample_character_sheet.txt"
sample_character <- generate_character(race = "vata", class = "adept")
capture.output(sample_character, file = "sample_character_sheet.txt")
```

## To do:

* Auto-generate background if required.
* Create an actual character class, like a grownup.
* Generate higher-level characters (will require a lot of making on talents & specializations tabular).
* When generating Rhydan, select species and modify attributes based on that.
* Add a name generator (based on race/background?)
* Interleave focuses in basic stats.

## Known bugs

* Sometimes generates `Talent: Natural weapons` for non-Rhydan characters. Still trying to hunt this one down.
* Occasionally generates an `NA` talent if the character doesn't fulfill the stat requirements for any of their racial/class starting talents.
