#!/bin/sh
TODAY=`date +%F`
source $HOME/.rvm/scripts/rvm
cd $HOME/projects/monotonous/mirakui_retro
/home/mirakui/.rvm/bin/rvm ruby-1.9.3-p362 do ruby bin/mirakui_retro.rb >> log/mirakui_retro.log.$TODAY
