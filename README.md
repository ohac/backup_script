    gpg --keyserver hkp://subkeys.pgp.net --recv-key xxxxxxxx
    #gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-key xxxxxxxx
    #gpg --keyserver hkp://keyserver.kjsl.com:80 --recv-key xxxxxxxx
    cat >otrust.txt
    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx:6:
    ^D
    gpg --import-ownertrust < otrust.txt

systemd

    sudo cp backup.service /etc/systemd/system/
    sudo cp backup.timer /etc/systemd/system/
    sudo systemctl enable /etc/systemd/system/backup.service 
    sudo systemctl enable /etc/systemd/system/backup.timer
    sudo systemctl start backup.timer

cron

    crontab -l
    30 1 * * * /home/foo/backup_script/backup.sh
