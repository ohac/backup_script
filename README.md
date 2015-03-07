    gpg --import B8449253.asc
    gpg --import-ownertrust < otrust.txt
    sudo cp backup.service /etc/systemd/system/
    sudo cp backup.timer /etc/systemd/system/
    sudo systemctl enable /etc/systemd/system/backup.service 
    sudo systemctl enable /etc/systemd/system/backup.timer
    sudo systemctl start backup.timer
