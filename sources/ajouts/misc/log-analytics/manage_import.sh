#!/bin/bash

# OPTIONS DE TRACKING (1 pour activer, 0 pour désactiver)
ENABLE_STATIC=1			# Track static files (images, css, js, etc.)
ENABLE_BOTS=1			# Track bots. All bot visits will have a Custom Variable set with name='Bot' and value='$Bot_user_agent_here$'
ENABLE_HTTP_ERRORS=1	# Track HTTP errors (status code 4xx or 5xx)
ENABLE_HTTP_REDIRECTS=1	# Track HTTP redirects (status code 3xx except 304)

DOMAIN="__DOMAIN__"
PIWIK_PATH="__PIWIK_PATH__"
PIWIK_DIR="__FINALPATH__"

# Récupération des identifiants de la bdd de piwik
db_user=$(cat $PIWIK_DIR/config/config.ini.php | grep username | cut -d "\"" -f 2)
db_pwd=$(cat $PIWIK_DIR/config/config.ini.php | grep password | cut -d "\"" -f 2)

# Traitement de chaque domaine de Yunohost
for DOMAIN_TRACK in `ls -1d /etc/nginx/conf.d/*.d/ | cut -d "/" -f 5`
do
	# Retire .d à la fin du nom de domaine.
	DOMAIN_TRACK=$(basename $DOMAIN_TRACK .d)
	echo "Domaine traité: $DOMAIN_TRACK"

	# Récupération de l'ID correspondant au domaine
	IDSITE=$(mysql -h localhost -u $db_user -p$db_pwd -s $db_user -e "SELECT idsite FROM piwik_site WHERE main_url LIKE \"%$DOMAIN_TRACK%\"" | sed -n 1p)

	# Récupération du token auth du premier admin trouvé.
	TOKEN=$(mysql -h localhost -u $db_user -p$db_pwd -s $db_user -e "SELECT token_auth FROM piwik_user WHERE superuser_access=1" | sed -n 1p)

	if [[ -n $IDSITE ]]	# Continue uniquement si l'ID est renseigné dans la base de donnée
	then
		for TYPE_LOG in 'access' 'error'
		do
			# Appel du script d'extraction du log, chargé de dissocier la partie non lue du log
			$PIWIK_DIR/misc/log-analytics/extract_log.sh /var/log/nginx/$DOMAIN_TRACK-$TYPE_LOG.log
			# Appel du script python
			if [ $ENABLE_STATIC = 1 ]
			then
				ENABLE_STATIC="--enable-static"
			else
				ENABLE_STATIC=" "
			fi
			if [ $ENABLE_BOTS = 1 ]
			then
				ENABLE_BOTS="--enable-bots"
			else
				ENABLE_BOTS=" "
			fi
			if [ $ENABLE_HTTP_ERRORS = 1 ]
			then
				ENABLE_HTTP_ERRORS="--enable-http-errors"
			else
				ENABLE_HTTP_ERRORS=" "
			fi
			if [ $ENABLE_HTTP_REDIRECTS = 1 ]
			then
				ENABLE_HTTP_REDIRECTS="--enable-http-redirects"
			else
				ENABLE_HTTP_REDIRECTS=" "
			fi
 			$PIWIK_DIR/misc/log-analytics/import_logs.py --url=https://$DOMAIN$PIWIK_PATH/local_alias $PIWIK_DIR/misc/log-analytics/log_rewrite.log --idsite=$IDSITE --token-auth=$TOKEN --log-format-name=ncsa_extended $ENABLE_STATIC $ENABLE_BOTS $ENABLE_HTTP_ERRORS $ENABLE_HTTP_REDIRECTS -d
		done
	fi
done
