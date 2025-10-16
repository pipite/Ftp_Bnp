#!/bin/bash

# ---------------       Interface LAB BNP       ------------------------  
# - Connection FTP serveur de la BNP $ftp_server
# - Recuperation des fichiers de la BNP depuis $ftp_dir
# - Supression des fichiers du serveur FTP apres recuperation
# - Archivage des fichiers recuperes dans $local_archive
# - Depot des fichiers recuperes sur le NAS $nas_address dans $nas_share
# - 2 Fichier de log dans le repertoire $local_log
#      1 fichier de log general tracant toutes les manips log_file = "ftp_bnp.log"
#      1 fichier de log tracant uniquement les errreurs   log_err  = "ftp_bnp.err"
# -                     !!! Password cryptes !!!
# Depot gitlab : LAB - BNP
# Prerequis : utilise le script encode.sh : Depot gitlab : Encode
#             Renseigner les bon comptes, repertoire et serveurs dans les variables
#             Accorder les bons droits
# Usage : ftp_bnp.sh, pas de parametre.
#   2025/02/07 : Conversion de ftp_bnp.py >> ftp_bnp.sh : b.tran 
# ----------------------------------------------------------------------

# Variables utilisateur
interface="LAB BNP"
log_file="ftp_bnp.log"
log_err="ftp_bnp.err"
wildcard='*'

# Variables serveur FTP
ftp_user='administrateur'
ftp_password='@Wnrm7991'
ftp_server='10.160.198.130'
ftp_dir='FTP_ETL/IMPORT_BNP/download'

# Repertoires locaux
local_dir='U:/BNP_LAB'
local_archive="U:/BNP_LAB/OLD"
local_log="./LOG"

# Chemin reseau et identifiants pour le NAS
nas_mount='/mnt/nas'
nas_address="vlabheb105.lab.local"
nas_ftp_user='LAB\svc-schedule'
nas_password='6#@3a-606gH-Yl#6m-#IY4Z'
nas_share='StockagePDF/LAB_PRD/OEBS_IMPORT/1301/OIE009/in'

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#    Debug FTP Local & NAS local
#    lignes a commenter
# creer 3 fichier dans le depot FTP local
echo "bbbb" > /home/ftpuser/FTP_ETL/IMPORT_BNP/download/fichier2.txt
echo "aaaa" > /home/ftpuser/FTP_ETL/IMPORT_BNP/download/fichier1.txt
echo "cccc" > /home/ftpuser/FTP_ETL/IMPORT_BNP/download/FTP0DHGW
ftp_user='ftpuser'
ftp_password='ugkfhvi'
ftp_server='127.0.0.1' 
local_dir='./recu'
local_archive='./archive'
nas_address="192.168.1.73"
nas_user='admin'
nas_password='!Avorklklolnri8484'
nas_share='Download'
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# Ecriture du fichier log
exec 1>>"$local_log/$log_file"

#---------------------------------
# Fonction
separator="------------------------------------------------"
print_LOG() { echo -e "$1"; }
print_ERR() { 
    echo -e "$1" 
    if [ -z "$1" ]; then
        echo " " >> "$local_log/$log_err"
    else
        echo -e "$(date) : $1" >> "$local_log/$log_err" 
    fi
}

terminate() {
     errorcode=$2

    if [ "$errorcode" = "0" ]; then print_LOG "$1"; else print_ERR "$1"; fi
    
    if mount | grep -q "$nas_mount"; then
        print_LOG "Deconnexion du NAS"
        umount $nas_mount
    fi
    if mount | grep -q "$nas_mount"; then
        print_ERR "Erreur lors de la deconnection du NAS"
        errorcode=1
    fi
    if [ "$errorcode" = "0" ]; then
        print_LOG "Traitement $interface reussi" 
        print_LOG "$separator"
        print_LOG ""
    else
        # Log des erreurs dans le fichier $local_log/$log_err
        print_ERR "$separator"
        print_ERR "Traitement $interface interrompu ($cpterr erreur)"
        print_ERR "$separator"
        print_ERR ""
    fi
    kill $$
}

# ---------------------------------
# ---------     Main    -----------
# ---------------------------------
# Journalisation
print_LOG "$separator"
print_LOG "Interface     = $interface"
print_LOG "Date          = $(date)"
print_LOG "Server Ftp    = $ftp_server"
print_LOG "User FTP      = $ftp_user"
print_LOG "FTP Dir       = $ftp_dir"
print_LOG "Local Dir     = $local_dir"
print_LOG "Local Archive = $local_archive"
print_LOG "NAS adress    = $nas_address"
print_LOG "NAS share     = $nas_share"
print_LOG "User NAS      = $nas_user"
print_LOG "$separator"

cpterr=0
nas_password=$(./encode.sh $nas_password) 
ftp_password=$(./encode.sh $ftp_password) 

# Verification "a priori" des prérequis avant telechargement
# Verification de l'existance des repertoires locaux
if [ ! -d "$local_dir" ]; then cpterr=1;terminate "Le repertoire $local_dir n'existe pas" 1; fi
if [ ! -d "$local_archive" ]; then cpterr=1;terminate "Le repertoire $local_archive n'existe pas" 1; fi
# Verification du ping du serveur FTP
ping -c 1 -W 2 "$ftp_server" > /dev/null 2>&1
if [ $? -ne 0 ]; then cpterr=1; terminate "Le serveur FTP $ftp_server est injoignable" 1; fi
# Verification du ping du serveur NAS
ping -c 1 -W 2 "$nas_address" > /dev/null 2>&1
if [ $? -ne 0 ]; then cpterr=1; terminate "Le serveur NAS $nas_address est injoignable" 1; fi
# Montage du NAS
if [ ! -d "$nas_mount" ]; then
    mkdir -p "$nas_mount"
    chmod 755 "$nas_mount"
fi
if mountpoint -q "$nas_mount"; then 
    cpterr=1
    print_LOG  "Le point de montage $nas_mount existe deja"
else
    options="uid=$(id -u),gid=$(id -g),file_mode=0770,dir_mode=0770"
    mount -t cifs "//$nas_address/$nas_share" "$nas_mount" -o username=$nas_user,password=$nas_password,$options
    if mount | grep -q "$nas_mount"; then 
        print_LOG "Montage NAS sur $nas_mount reussi"
    else 
        let "cpterr+=1"
        terminate "Erreur a la connexion du NAS sur $nas_mount" 1 
    fi
fi

# Si on parvient ici, le serveur FTP repond au ping et le nas est bien monte sur $nas_mount
# On peut donc lancer le traitement

# Recuperation des fichiers sur serveur FTP
#1) verifier login
lftp -c "open -u '$ftp_user,$ftp_password' $ftp_server; cd './' " || ( cpterr=1; terminate "Erreur LFTP $ftp_server login/password" 1; )

#2) verifier repertoire du depot FTP
avant=$(lftp -c "open -u '$ftp_user,$ftp_password' $ftp_server; cls -1 $ftp_dir/* | wc -l") || ( cpterr=1; terminate "Erreur LFTP Le Repertoire $ftp_dir est innaccessible" 1; )
if [ "$avant" = "0" ]; then terminate "Pas de fichier a traiter" 0; fi

#3) importer et effacer : !!! N'utilise pas la variable wildcard et prend tous les fichiers, wildcard = * en dur !!!
print_LOG "Debut de traitement FTP"
lftp -c "open -u '$ftp_user,$ftp_password' $ftp_server; mirror --Remove-source-files -v /$ftp_dir $local_dir -v 3" || 
    ( cpterr=1; print_ERR "Erreur LFTP a renvoye une erreur lors de l'appel FTP mirror --Remove-source-file"; )
# Si des fichiers ont ete importe, on les traite

#4) verifier que le nombre de fichier recu correspond au nombre de fichier sur le serveur FTP
cpt=$(find "$local_dir" -maxdepth 1 -type f -name "$wildcard" | wc -l)
# si aucun fichier n'a ete importe, on stoppe en erreur
if [ "$cpt" = "0" ]; then let "cpterr+=1"; terminate "Aucun fichier n'a pu etre importe" 1; fi
if [ "$cpt" = "$avant" ]; then print_LOG "$cpt fichier importe vers $local_dir"; else print_ERR "Seulement $cpt/$avant importe dans $local_dir"; fi;
# Si il manque des fichiers, on traite les fichiers importe 

#5) verifier effacement sur serveur FTP
apres=$(lftp -c "open -u '$ftp_user,$ftp_password' $ftp_server; cls -1 $ftp_dir/* | wc -l")
if [ "$apres" = "0" ]; then print_LOG "$avant fichier supprime du depot FTP"; else print_ERR "Erreur: $apres fichier non supprime du serveur FTP"; fi
# Si des fichiers n'ont pas pu etre supprime du serveur FTP, on traite quand meme

# Copie des fichiers sur le NAS
print_LOG "Archive et Copie des fichiers $wildcard"
shopt -s nullglob #ignore les repertoires
for file in "$local_dir"/$wildcard; do
    name=$(basename "$file")
    timestamp=$(date +"%Y%m%d_%H%M%S")
    tsname="$name.$timestamp"

    # Archivage local
     # Les actions ci dessous sont passante meme si erreur
   cp -f $file $local_archive/$tsname && 
        print_LOG "Copy   $local_dir/$name dans $local_archive/$tsname" ||
        ( let "cpterr+=1"; print_ERR "Erreur de copie du fichier $local_dir/$name dans $local_archive/$tsname."; continue )

    # Copie dans le NAS
    if [ "$name" = "FTP0DHGW" ]; then nasdest=$tsname; else nasdest=$name; fi
    # Supression du fichier destination si existant avant deplacement
    if [ -e "$nas_mount/$nasdest" ]; then 
        rm $nas_mount/$nasdest &&
            print_LOG "Delete $nas_mount/$nasdest du NAS pour remplacement" || 
            ( let "cpterr+=1"; print_ERR "Erreur Suppression de l'ancien fichier $nas_mount/$nasdest impossible" )
    fi
    mv -f $file $nas_mount/$nasdest && 
        print_LOG "Move   $local_dir/$name  dans $nas_mount/$nasdest" || 
        ( let "cpterr+=1"; print_ERR "Erreur lors du deplacement $local_dir/$name vers $nas_mount/$nasdest"  )
    
done

terminate "Archive et Copie des fichiers termine" 0
