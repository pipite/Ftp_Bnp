
# Interface LAB BNP

Script bash d'interface entre la LAB << BNP
pour importer des fichiers de la BNP depuis le serveur FTP de la BNP et les mettre a disposition sur le NAS de LAB.



## Documentation

Etape du script:

1) Connection FTP serveur de la BNP $ftp_server
2) Recuperation des fichiers de la BNP depuis $ftp_dir
3) Supression des fichiers du serveur FTP apres recuperation
4) Archivage des fichiers recuperes dans $local_archive
5) Depot des fichiers recuperes sur le NAS $nas_address dans $nas_share





## Prerequis
Ce script utilise le script encode.sh pour encoder les mot de passe afin qu'ils ne soient pas visible en clair dans les scripts. (l'encodage est très simple, et pas vraiment robuste!)

Pour encoder un mot de passe, et pouvoir remplir les variables avec un mot de passe encodé, utiliser en ligne de commande le script encode.sh suivi du mot de passe en clair. encode.sh vous donnera le mot de passe encodé pour pouvoir l'inscrire dans les variables.

exemple : encode.sh motdepasseenclair 
renvoi : lgwvkzhhvvmxozri

encode.sh est reversible.

exemple : encode.sh lgwvkzhhvvmxozri 
renvoi : motdepasseenclair





## Utilisation
Avant d'integrer le script ftp_bnp.sh dans une tâche planifié sur un serveur Linux LAB avec un compte de service approprié.

Verifier la validité des variables du serveur FTP de la BNP

    ftp_user = 'compte utilisateur FTP'
    ftp_password = 'mot de passe encodé'
    ftp_server = 'ip address ou URL du FTP de la BNP'
    ftp_dir = 'chemin du repository dans le FTP'

Verifier la validité et les droits d'accès du compte de service aux répertoires de dépot des fichiers sur le serveur ou est planifié la tâche.

    local_dir = 'chemin de dépot des import du serveur FTP '
    local_archive = "chemin des fichiers archive sur le serveur local"
    local_log = "chemin des fichiers LOG"

Verifier la validité des identifiants et des droits d'accès du compte de service sur les Chemin reseau du NAS.

    nas_mount = '/mnt/nas'
    nas_address = "nom réseau du NAS"
    nas_ftp_user = 'compte de service'
    nas_password = 'mot de passe encodé'
    nas_share = 'chemin du dépot sur le NAS'

Créer une tâche planifié dont le schedule dépend de la fréquence de mise à disposition des fichiers par la BNP.

Aucun parametre n'est nécessaire. Tout est dans les variables.

Ce script devra être modifié si des chemins, comptes ou password des comptes utilisés sont modifiés.







    

## Fichiers de LOG
2 fichiers de LOG sont générés dans le répertoire $local_log, et mis a jours à chaque exécution du script.

    log_file="ftp_bnp.log"
Contient la tracabilité des actions et éventuelles erreurs détecté pendant le processus de chaque exécution du script. (exemple d'un itération ci dessous)

    ------------------------------------------------
    Interface     = LAB BNP
    Date          = Fri Feb  7 02:17:21 PM CET 2025
    Server Ftp    = 127.0.0.1
    User FTP      = ftpuser
    FTP Dir       = FTP_ETL/IMPORT_BNP/download
    Local Dir     = ./recu
    Local Archive = ./archive
    NAS adress    = 192.168.1.73
    NAS share     = Download
    User NAS      = admin
    ------------------------------------------------
    Montage NAS sur /mnt/nas reussi
    Debut de traitement FTP
    Transferring file `FTP0DHGW'
    Finished transfer `FTP0DHGW' (5 B/s)
    Transferring file `fichier1.txt'
    Finished transfer `fichier1.txt' (5 B/s)
    Transferring file `fichier2.txt'
    Finished transfer `fichier2.txt' (5 B/s)
    3 fichier importe vers ./recu
    3 fichier supprime du depot FTP
    Archive et Copie des fichiers *
    Copy   ./recu/fichier1.txt dans ./archive/fichier1.txt.20250207_144345
    Delete /mnt/nas/fichier1.txt du NAS pour remplacement
    Move   ./recu/fichier1.txt  dans /mnt/nas/fichier1.txt
    Copy   ./recu/fichier2.txt dans ./archive/fichier2.txt.20250207_144345
    Delete /mnt/nas/fichier2.txt du NAS pour remplacement
    Move   ./recu/fichier2.txt  dans /mnt/nas/fichier2.txt
    Copy   ./recu/FTP0DHGW dans ./archive/FTP0DHGW.20250207_144345
    Move   ./recu/FTP0DHGW  dans /mnt/nas/FTP0DHGW.20250207_144345
    Archive et Copie des fichiers termine
    Deconnexion du NAS
    Traitement LAB BNP reussi
    ------------------------------------------------
log_err="ftp_bnp.err"

Contient la uniquement tracabilité erreurs détecté pendant le processus de chaque exécution du script. (exemple de 2 erreurs dans deux itération distinctes ci dessous)

    Fri Feb  6 02:19:21 PM CET 2025 : Le repertoire ./recus n'existe pas
    Fri Feb  6 02:19:21 PM CET 2025 :          
    ------------------------------------------------
    Fri Feb  6 02:19:21 PM CET 2025 : Traitement LAB BNP interrompu (1 erreur)
    Fri Feb  6 02:19:21 PM CET 2025 :  
    ------------------------------------------------

    Fri Feb  7 02:21:13 PM CET 2025 : Le serveur NAS 193.168.1.73 est injoignable
    Fri Feb  7 02:21:13 PM CET 2025 :
     ------------------------------------------------
    Fri Feb  7 02:21:13 PM CET 2025 : Traitement LAB BNP interrompu (1 erreur)
    Fri Feb  7 02:21:13 PM CET 2025 :
    ------------------------------------------------

Les erreurs tracés sont :

    Le repertoire $local_dir n'existe pas
    Le repertoire $local_archive n'existe pas
    Le serveur FTP $ftp_server est injoignable
    Le serveur NAS $nas_address est injoignable
    Erreur a la connexion du NAS sur $nas_mount
    LFTP Le Repertoire $ftp_dir est innaccessible
    LFTP a renvoye une erreur lors de l'appel FTP mirror --Remove-source-file
    Aucun fichier n'a pu etre importe
    Seulement $cpt/$avant importe dans $local_dir
    $apres fichier non supprime du serveur FTP
    Erreur de copie du fichier $local_dir/$name dans $local_archive/$tsname
    Erreur Suppression de l'ancien fichier $nas_mount/$nasdest impossible
    Erreur lors du deplacement $local_dir/$name vers $nas_mount/$nasdest
    Traitement $interface interrompu ($cpterr erreur)





