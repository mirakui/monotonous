#!/bin/sh
TODAY=`date +%F`
source $HOME/.rvm/scripts/rvm
cd $HOME/projects/monotonous/mirakui_retro
ruby bin/mirakui_retro.rb >> log/mirakui_retro.log.$TODAY
