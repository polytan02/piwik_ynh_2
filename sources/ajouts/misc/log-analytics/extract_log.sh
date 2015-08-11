#!/bin/bash

PIWIK_PATH="__FINALPATH__"
LOG_FILE_SOURCE="$1"
LOG_FILE_CIBLE="$PIWIK_PATH/misc/log-analytics/log_rewrite.log"
LAST_ENTRY_FILE="$PIWIK_PATH/misc/log-analytics/$(basename $1 .log)_last_entry"
LAST_ENTRY="$(cat $LAST_ENTRY_FILE)"
LAST_ENTRY_OK=0

echo -n > $LOG_FILE_CIBLE	# Efface le contenu du nouveau log à destination de piwik

while [ $LAST_ENTRY_OK -eq 0 ]	#Boucle tant que la dernière entrée du précédent log n'est pas trouvée ou invalidée.
do
    if [ -z "$LAST_ENTRY" ]	# Test si la variable est vide
    then	#Si LAST_ENTRY est vide, inutile de chercher la dernière ligne. Elle n'est pas connue.
		LAST_ENTRY_OK=1	# Force la variable pour ignorer la dernière entrée
    fi
    while read LIGNE	#Lecture du log.
    do
		if [ $LAST_ENTRY_OK -eq 0 ]	# Si la dernière ligne de log n'a pas encore été trouvée.
		then
			if [[ "$LIGNE" == "$LAST_ENTRY" ]]	#Si la ligne de log lue correspond à la dernière ligne cherchée!
			then
				LAST_ENTRY_OK=1		# Dernière ligne du précédent log trouvée.
			fi
		else
			echo "$LIGNE" >> $LOG_FILE_CIBLE
			if [[ ! -z "$LIGNE" ]]
			then	#Si la ligne lue n'est pas vierge
				PRE_LAST="$LIGNE"	#Duplique dans une seconde variable, afin d'éviter de garder la dernière ligne vierge du log.
			fi
		fi
    done < "$LOG_FILE_SOURCE"
    if [ $LAST_ENTRY_OK -eq 0 ]	# Si a la fin de la boucle, la dernière entrée n'a toujours pas été trouvée, il est probable qu'un logrotate soit passé par là!
    then
		LAST_ENTRY_OK=1	# Force la variable pour ignorer la dernière entrée
    fi
done

echo "$PRE_LAST" > $LAST_ENTRY_FILE	#Copie la dernière ligne dans le fichier last_entry afin de stocker la dernière ligne de log lue.
