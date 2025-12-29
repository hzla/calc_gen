USAGE


Step 1: Ruby Installation

install ruby from https://www.ruby-lang.org/en/documentation/installation/

Step 2: Downloading and Pasting Calc Gen FOlder

download/clone this repo and put it inside inside the hg-engine folder

Step 3: Generating the Data

run: `ruby npoint_generate.rb` from inside this folder (calc_gen) to generate the json `npoint.json`

Step 4: Setting up Local Calc

download/clone the calc repo from https://github.com/hzla/Dynamic-Calc-decomps

in `backups/hgenginerom.js` paste the contents of `npoint.json` after `backup_data = ` 
DO NOT CHANGE THE FILE NAME
open `index.html` in your browser and add `?data=hgenginerom` to the url
you calc should be loaded

Step 5: Publishing

Once you have finished your rom hack and want to publish it online, you can either host the calc repo on github pages or send `npoint.json` to hzla on discord and I will upload it onto the main calc site. 






