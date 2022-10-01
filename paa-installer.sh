#!/bin/bash

#initializing variables
DEFAULT_DOMAIN=example.com
DEFAULT_DOMAIN_DIR=/home/example/public_html/
GIT_RSA_PATH=/root/.ssh/paa_id_rsa
PANEL_DETAILS_FILE_PATH=/root/.paaDetails
DEFAULT_USER=example
DEFAULT_USER_GROUP=example
DATABASE_NAME=example
DATABASE_USER=example
SERVER_IP=$(hostname -I | cut -f1 -d ' ')
APP_WEB_URL="http://$SERVER_IP"
MYSQL_PASSWORD=$(echo $RANDOM | md5sum | head -c 20)

mkdir /root/.ssh/

#initializing functions
logInfo() {
  message=$1
  echo -e "\e[37m$message"
}

logGreen() {
  message=$1
  echo -e "\e[32m$message"
}

logCyan() {
  message=$1
  echo -e "\e[36m$message"
}

emptySpace() {
  echo ''
  echo ''
}

function escape_slashes() {
  sed 's/\//\\\//g'
}

updateEnvVar() {
  local OLD_LINE_PATTERN=$1
  shift
  local NEW_LINE=$1
  shift
  local FILE=$1

  local NEW=$(echo "${NEW_LINE}" | escape_slashes)
  sed -i.bak '/^'"${OLD_LINE_PATTERN}"'/s/.*/'"${NEW}"'/' "${FILE}"
  mv -f "${FILE}.bak" /tmp/
}

emptySpace
logGreen 'PAA Installation Script'
emptySpace

logInfo 'Supports only CentOS 7 systems'
logInfo 'It will install Virtualmin and Configure default domain'
emptySpace

logCyan 'We need Root Password to continue'
logCyan 'If you have root password enter below, otherwise click CTRL+C to cancel then run "passwd" to create root password, then re-run installer'
emptySpace

logInfo ''

unset ROOT_PASSWORD
echo -n "Enter root password:"
read -r ROOT_PASSWORD

emptySpace
logInfo 'Updating system packages'
emptySpace

yum -y update

emptySpace
logInfo 'Installing dependencies'
emptySpace

yum -y install wget perl nano tmux curl git

emptySpace
logInfo 'Downloading Virtualmin'
emptySpace

wget -q http://software.virtualmin.com/gpl/scripts/install.sh

emptySpace
logInfo 'Installing Virtualmin, be ready to answer virtualmin installation questions'
emptySpace

chmod u+x ./install.sh
sh ./install.sh --hostname "$DEFAULT_DOMAIN" --force

emptySpace
logGreen 'Virtualmin installed, starting to install PHP 7.4'
emptySpace

logInfo 'Installing dependencies for PHP install'
emptySpace

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -y install yum-utils

emptySpace
logInfo 'Beginning PHP installation'
emptySpace

yum-config-manager --enable remi-php74
yum -y update
yum -y install php php-cli
yum -y install php-{cli,pdo,fpm,zip,gd,gnupg,xml,process,mysqlnd,opcache,mbstring,intl,bcmath}

emptySpace
logGreen 'Completing PHP installation'
emptySpace

logInfo 'Updating MariaDB to 10.5'
emptySpace

#uninstall previous
systemctl stop mariadb
yum -y remove "mariadb-*"
yum remove galera-4
yum remove galera
rpm --query --all | grep -i -E "mariadb|galera"

#install latest
wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
echo "d4e4635eeb79b0e96483bd70703209c63da55a236eadd7397f769ee434d92ca8 mariadb_repo_setup" |
  sha256sum -c -
chmod +x mariadb_repo_setup
./mariadb_repo_setup \
  --mariadb-server-version="mariadb-10.5"
yum -y install MariaDB-server MariaDB-backup
systemctl enable mariadb
systemctl start mariadb

emptySpace
logGreen 'Virtualmin has been configured with PHP and MariaDB'
emptySpace

logInfo 'Starting Domain Configuration'
emptySpace

#create domain
virtualmin create-domain --domain "$DEFAULT_DOMAIN" --pass "$ROOT_PASSWORD" --desc "Default Server" --unix --dir --webmin --web --limits-from-plan --mysql --mysql-pass "$MYSQL_PASSWORD"

systemctl restart httpd

#set php version, php options and website options
virtualmin modify-web --domain "$DEFAULT_DOMAIN" --mode fpm --no-php-timeout --default-website --document-dir "public_html/public"
virtualmin modify-web --domain "$DEFAULT_DOMAIN" --php-version "7.4"

emptySpace
logGreen 'Domain has been created'
emptySpace

logInfo 'Installing PAA Script'
emptySpace

touch $GIT_RSA_PATH
echo '' >$GIT_RSA_PATH

cat >$GIT_RSA_PATH <<-"EOF"
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-128-CBC,CE0EBE84A51D358752350670BB45B97F

dXohHNYePMhTEajEd9v9/5JjfDrjLpoKQFKcvsKWhE2snHjxhqcphwbK50VrWgJA
1lHOFBfp55PpZRPIOU5b1rGEo3tc14DAoHq3d8ymCzankW2jjtw1zyQxOfNA0G4P
zaq7G66gQNcPiGDGiyQ5vWpn3UYXjJ5jjxLFQ4j0dWWyuzX8DwwBPUyoO3j7GIV4
pTgk211sotW9nUc2cuIYo+6510KkGjnoCg3wIj+nKghLCDqJoBotZnxX5m3vtR8p
zhxM0g9LarTXEG3fnRbcdP2NguQeugUd6O6M2BP3bVvEYMCyWQRrACX0dCNLHPZa
tjI68ktA9spzIfouVZENbvqSguQSsVF0brJKu/jySNB/CZPy/lGUYQg9zv5XOQkG
ot9yHZhsSUI1ppOhmm5QeUCf6fdirwQs5vZ0Kx1sWu8VLqvOB2xFx83E0Fh999QJ
O6vKYfKhDsJg0ZeH+/UGfWkiSHJdNMVbvL2Au3vjeGLKAbOERpCbS2NdFSLY/SB2
zdOMdOvqJS2S1cYkr3ZFKYTxq1RT/8ST4myeZsF8Zjy8r9eTu95xwtZJz5Woa6xB
TREnegeCX/dDME1ceodsgnuWIyoBnAPvI8V7Fidxfu8VX/kBuuFrI7GevQomVRbR
nSJ/uLWbaDN3Id9D0OOSLVSqHRc9BqG/t8ZG/1S5E5v558FKME87uE94tBe9y9sk
9kcGyBL3a30u31fM6PcG407SFRqp9wQZFCinH8sCKD/ioArZtb0fzrFaWt/tYo+E
Td8UVaKDGwFIYj9I4ac3KVw0B0cUA+2a0mCMPHSpayqyQH2PguhMjkDdve3t3BJ/
sN9JIvQHpttloeveuO+ZDHOSHM3W48LNH06/2FIjuqyRGqwPBFVnyuixJ5hKJ6+l
9Hjev0JMp0uirqobF9puQ5+2Hm7ndAsNgc2tUT41Jdir3J+KqmTrsqSAqRHL05/w
gH4O1CQOMQP6BdEM7Y5cO3Bf2dCC4H3bgyzYSfFhjoWx7z0RhQr9ir/d5GjFT5GJ
7icmtDQgXg/dosnH/0LENlJSs4nzIabJsgvyjLcJk3fJwDX2WKLhXM4cbcnGnMIQ
NC51ok9SE1xGP0gvagWINT9WPTLoa4ZBXvQsG3gr0vr2XxrKsEFve6ZDe5nQYEO5
PzJ7sLKV4StpUCbw8g4h8hEVZAXt5txiTSregXmWqtv7c+0DNkC5DP0N71FfXQ0Z
Qe4XtV3op+d/WQmv86bFmgEty4FHSKe3ywotX0qE3r90HbSCp/1J/mO0Iz5AfY+C
56K20Die6OWyG9KvsdZBi41rNMf3CA4quqesCbJmCKWxKwLxx5CJUFADFpXnMB2Q
nMF2uE/owx2zWShfddvOJhMRpnMgyurZHurUNXC07dMdwuDJ6fzVXS9NvAWGIRnm
k/5BnGcz7YN3uNUWbUYG7zYZHOODRKnSzmQwFAcv3HNV1XS5IjkOGPr50nBZN5DQ
tCxwiruE3gXAEomMhQ6WSGr+z5wYzT4DXznMdSbhWDk0dQlnUJC4f6xMCYL+W0tZ
BYx+oP7mlPHNNtV4jlyAGXB2BVY5M91Flx1O83CYyLgdIliS/UxV6Hu3qrUObKkg
-----END RSA PRIVATE KEY-----
EOF

emptySpace
logCyan 'Now enter Git SSH Password'
logInfo ''

chmod 0600 $GIT_RSA_PATH
eval $(ssh-agent -s)
ssh-add -k $GIT_RSA_PATH

cd $DEFAULT_DOMAIN_DIR

rm -rf $DEFAULT_DOMAIN_DIR*

git init
git remote add origin git+ssh://git@bitbucket.org/teamoxiodev/to-google-paa-scrapper.git
git pull origin single-thread
git branch
git checkout single-thread
git branch
git pull origin single-thread

emptySpace
logGreen 'Git Configured'
emptySpace

REQUIRED_PKG="composer"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
logInfo Checking for $REQUIRED_PKG: "$PKG_OK"
if [ "" = "$PKG_OK" ]; then
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
  php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { logInfo 'Installer verified'; } else { logInfo 'Installer corrupt'; unlink('composer-setup.php'); } logInfo PHP_EOL;"
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  php -r "unlink('composer-setup.php')"
fi

/usr/bin/php /usr/local/bin/composer install

cd $DEFAULT_DOMAIN_DIR
cp .env.example .env

#generate laravel key
/usr/bin/php ./artisan key:generate

envFilePath="$DEFAULT_DOMAIN_DIR.env"
#update env variables
updateEnvVar APP_URL "APP_URL=$APP_WEB_URL" "$envFilePath"
updateEnvVar DB_DATABASE "DB_DATABASE=$DATABASE_NAME" "$envFilePath"
updateEnvVar DB_USERNAME "DB_USERNAME=$DATABASE_USER" "$envFilePath"
updateEnvVar DB_PASSWORD "DB_PASSWORD=$MYSQL_PASSWORD" "$envFilePath"

/usr/bin/php ./artisan migrate --seed

emptySpace
logInfo 'Updating Permissions'
emptySpace

cd "$DEFAULT_DOMAIN_DIR"
chown -R $DEFAULT_USER:"$DEFAULT_USER_GROUP" *

#installing phpmyadmin
virtualmin install-script --domain "$DEFAULT_DOMAIN" --type phpmyadmin --version "5.2.0" --path /hexy1234

emptySpace
logInfo 'Installing Node Dependencies and Starting PM2'
emptySpace

wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
source ~/.bashrc

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

nvm install v14.5.0

npm install pm2@latest -g
pm2 startup

cd "$DEFAULT_DOMAIN_DIR"
cd node

mkdir work
mkdir puppeteer_data

npm install

pm2 start index.js --name=paaNode
pm2 save

emptySpace
logGreen 'PM2 Started'
emptySpace

logInfo 'Updating Permissions'
emptySpace

cd "$DEFAULT_DOMAIN_DIR"
chown -R $DEFAULT_USER:"$DEFAULT_USER_GROUP" *

emptySpace
logInfo 'Adding Cron Jobs'
emptySpace

#adding cron jobs

#adding in root user
crontab -l >cronBackup
echo "0,5,10,15,20,25,30,35,40,45,50,55 * * * * sudo sh /home/example/public_html/checkPm2.sh" >>cronBackup
crontab cronBackup
rm -f cronBackup
#adding for default user
crontab -u "$DEFAULT_USER" -l >userCronBackup
echo "* * * * * /usr/bin/php /home/example/public_html/artisan check-jobs" >>userCronBackup
crontab -u "$DEFAULT_USER" userCronBackup
rm -f userCronBackup

emptySpace
logGreen 'Cron Jobs has been added'
emptySpace
logInfo ''

#additional settings
webmin set-config --force --module virtual-server --option wizard_run --value 1
yum -y install postfix
virtualmin-config-system -i Postfix

emptySpace
logInfo 'Setting Puppeteer'
emptySpace

yum install -y alsa-lib.x86_64 atk.x86_64 cups-libs.x86_64 gtk3.x86_64 ipa-gothic-fonts libXcomposite.x86_64 libXcursor.x86_64
yum install -y libXdamage.x86_64 libXext.x86_64 libXi.x86_64 libXrandr.x86_64 libXScrnSaver.x86_64 libXtst.x86_64 pango.x86_64
yum install -y xorg-x11-fonts-100dpi xorg-x11-fonts-75dpi xorg-x11-fonts-cyrillic xorg-x11-fonts-misc xorg-x11-fonts-Type1
yum install -y xorg-x11-utils libnss3.so libatk-bridge-2.0.so.0
yum update -y nss
yum install -y at-spi2-atk libdrm.so.2 pulseaudio libdrm libgbm

cd "$DEFAULT_DOMAIN_DIR"
cd node

npm install

pm2 restart paaNode
pm2 save

cd "$DEFAULT_DOMAIN_DIR"

emptySpace
logInfo 'Puppeteer has been configured'
emptySpace

logGreen 'Everything is setup. Thank you for using the PAA Installation Script'
emptySpace

logInfo "Details are below, these are also saved in file at $PANEL_DETAILS_FILE_PATH"
emptySpace

#write details in file

touch $PANEL_DETAILS_FILE_PATH
echo '' >$PANEL_DETAILS_FILE_PATH

cat >$PANEL_DETAILS_FILE_PATH <<EOL
Webmin: https://${SERVER_IP}:10000

Username: root
Password: ${ROOT_PASSWORD}

Website: ${APP_WEB_URL}

PhpMyAdmin: ${APP_WEB_URL}/hexy1234

MySql Username: ${DATABASE_USER}
MySql Password: ${MYSQL_PASSWORD}
EOL

cat $PANEL_DETAILS_FILE_PATH

emptySpace
logInfo ''

sudo su
exit
