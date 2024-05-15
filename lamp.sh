#!/bin/bash

# Define variables for paths and IP address
LARAVEL_DIR="/var/www/html/laravel"
LARAVEL_CONF="/etc/apache2/sites-available/laravel.conf"
VIRTUAL_HOST="192.168.33.8"

# Update all package index and upgrade packages
sudo apt update && sudo apt upgrade -y || exit 1
echo "***** Successfully upgraded packages *****"

# Update the PHP repository
sudo add-apt-repository -y ppa:ondrej/php || exit 1
echo "***** Successfully updated php repo *****"

# Install Apache
sudo apt install -y apache2
sudo systemctl enable apache2
echo "***** Done with Apache installation *****"

# Install MySQL
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password'
sudo apt install -y mysql-server
echo "***** Done with MySQL installation *****"

# Install PHP 8.2 and 8.3 with necessary extensions
sudo apt install -y php libapache2-mod-php php-mysql php8.2 php8.2-curl php8.2-dom php8.2-xml php8.2-mysql php8.2-sqlite3 php8.3 php8.3-curl php8.3-dom php8.3-xml php8.3-mysql php8.3-sqlite3 git || exit 1
echo "***** Done with PHP 8.2 and 8.3 installation *****"

# Run MySQL secure installation
expect <<EOF
spawn sudo mysql_secure_installation
expect "Would you like to setup VALIDATE PASSWORD component?"
send "y\r"
expect {
    "Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG" {
        send "1\r"
        exp_continue
    }
    "Remove anonymous users?" {
        send "y\r"
        exp_continue
    }
    "Disallow root login remotely?" {
        send "n\r"
        exp_continue
    }
    "Remove test database and access to it?" {
        send "y\r"
        exp_continue
    }
    "Reload privilege tables now?" {
        send "y\r"
        exp_continue
    }
}
EOF
echo "***** Done with MySQL secure installation *****"

# Restart Apache
sudo systemctl restart apache2
echo "Done with Apache restart"

# Clone Laravel repository
sudo git clone https://github.com/laravel/laravel $LARAVEL_DIR
echo "***** Done with cloning Laravel repository *****"

# Change directory to Laravel folder
cd $LARAVEL_DIR
echo "Changed directory to $LARAVEL_DIR"

# Install Composer
sudo apt install -y composer
echo "***** Done with installing Composer *****"

# Upgrade Composer to version 2
sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php --install-dir /usr/bin --filename composer
echo "***** Done with upgrading Composer to version 2 *****"

# Use Composer to install dependencies
yes | sudo composer install
echo "***** Done installing Composer dependencies *****"

# Copy Laravel configuration file and set permissions
sudo cp .env.example .env
sudo chown www-data:www-data .env
sudo chmod 640 .env
echo "***** Done copying Laravel configuration file and setting permissions *****"

# Create virtual host in /etc/apache2/sites-available
sudo tee $LARAVEL_CONF >/dev/null <<EOF
<VirtualHost *:80>
    ServerName $VIRTUAL_HOST
    ServerAlias *
    DocumentRoot $LARAVEL_DIR/public

    <Directory $LARAVEL_DIR>
        AllowOverride All
    </Directory>
</VirtualHost>
EOF
echo "***** Done creating virtual host in /etc/apache2 *****"

# Generate application key and run migrations
sudo php artisan key:generate && sudo php artisan migrate --force || exit 1
echo "***** Done generating application key and running migrations *****"

# Change ownership permissions
sudo chown -R www-data:www-data $LARAVEL_DIR/database/ $LARAVEL_DIR/storage/logs/ $LARAVEL_DIR/storage $LARAVEL_DIR/bootstrap/cache || exit 1
echo "***** Done changing ownership permissions *****"

# Set file permissions
sudo chmod -R 775 $LARAVEL_DIR/database/ $LARAVEL_DIR/storage/logs/ $LARAVEL_DIR/storage || exit 1
echo "***** Done setting file permissions *****"

# Disable default and enable laravel configuration file
sudo a2dissite 000-default.conf && sudo a2ensite laravel.conf || exit 1
echo "***** Laravel configuration file enabled *****"

# Restart Apache
sudo systemctl restart apache2 || exit 1
echo "***** LAMP stack deployment completed successfully *****"
