#!/bin/bash
export LANG=ja_JP.UTF-8
TODAY=`/bin/date +%F`
RUBY=/usr/local/bin/ruby1.9
BASE_DIR=/home/mirakui/projects/monotonous/mirakui_retro
BIN_DIR=${BASE_DIR}/bin
LOG_DIR=${BASE_DIR}/log

FETCH_CMD="$RUBY $BIN_DIR/fetch_logs.rb"

echo $FETCH_CMD

$FETCH_CMD

if [ $? != 0 ]; then
  echo "Fetch Error"
  exit 1
fi

$RUBY $BIN_DIR/parse_logs.rb > $LOG_DIR/twitter_log.mirakui.$TODAY

if [ $? != 0 ]; then
  echo "Parse Error"
  exit 2
fi

$RUBY $BIN_DIR/insert_schedules.rb $LOG_DIR/twitter_log.mirakui.$TODAY

if [ $? != 0 ]; then
  echo "Insert Error"
  exit 3
fi

echo "Batch Success"

