#!/bin/bash

PIWIK_PATH="__FINALPATH__/misc/geoip"

wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz -O $PIWIK_PATH/GeoLiteCity.dat.gz
gunzip $PIWIK_PATH/GeoLiteCity.dat.gz
mv -f $PIWIK_PATH/GeoLiteCity.dat $PIWIK_PATH/GeoIPCity.dat
