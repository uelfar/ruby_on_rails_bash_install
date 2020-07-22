#!/bin/bash
#
# Install Rails 5.2.4 & Ruby 2.6.4 server environment
# Created by Astm Ali | https://github.com/astmdesign , modified by u.elfar@gmail.com
#
clear

echo "----------------apt-get update & install -------------------------"

sudo apt-get update
sudo apt-get install git -y
sudo apt-get install -y build-essential libssl-dev libreadline-dev ruby-dev zlib1g-dev liblzma-dev
sudo apt-get install -y libyaml-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev
sudo apt-get install -y software-properties-common libffi-dev yarn libmagickwand-dev
sudo apt-get install nodejs -y
sudo apt-get install imagemagick -y
sudo apt-get install -y graphviz graphviz-dev libgraphviz-dev
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
sudo apt-get install -y apt-transport-https ca-certificates
sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger bionic main > /etc/apt/sources.list.d/passenger.list'
sudo apt-get update
sudo apt-get install -y nginx-extras passenger
sudo apt-get install postgresql postgresql-contrib libpq-dev -y
sudo apt-get install libnginx-mod-http-passenger
sudo apt-get install -y python-pydot python-pydot-ng graphviz python3-pip python3-pydot graphviz
pip3 install  graphviz
sudo npm install yarn -g
sudo apt install npm -y

sudo apt-get install -y nodejs-dev node-gyp libssl1.0-dev
sudo apt-get install nodejs -y

sudo service nginx start
# For digitalocean notifications
#sudo apt-get -y purge do-agent
#sudo apt-get -y install do-agent



echo "$(tput setaf 201)--------------------------------"
echo "Install Rails 5.2.4 & Ruby 2.6.4 server environment As $(whoami) user"
echo "-------------------------------- $(tput setaf 0)"

# Define my variables
echo "------------------define variables--------------------------------"
export ruby_version="2.6.4"
export deployer_user="deployer"
export postgres_user="postgres"
export domain="$(dig +short myip.opendns.com @resolver1.opendns.com)"
export app_name="project"
#please make sure to edit them in postgre commands too below 
export db_user="project" 
export db_name="project_develop" 
export shared_folder_path="/home/$deployer_user/$app_name/shared"



#creating users 
 echo -e "\n$(tput setaf 1)################## Add $deployer_user user ################## $(tput setaf 0)"
 if  grep "$deployer_user" /etc/passwd
 then
	 echo "user $deployer_user  exists !! "
 else
        sudo adduser --disabled-password  "$deployer_user"
        adduser "$deployer_user" sudo
 fi

#please make sure to edit them in postgre variables too 
sudo runuser -l $postgres_user -c 'createuser --pwprompt project'
sudo runuser -l $postgres_user -c 'createdb -O project project_develop'



# Login with the deployer user if it not db user
if [[ $(whoami) == "$deployer_user" ]]
then
	echo -e "\n$(tput setaf 1)################## Install Rbenv ################## $(tput setaf 0)"
	cd
	rm -rf ~/.rbenv
	git clone https://github.com/rbenv/rbenv.git ~/.rbenv
	echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
	echo 'eval "$(rbenv init -)"' >> ~/.bashrc
	export PATH="$HOME/.rbenv/bin:$PATH"
	eval "$(rbenv init -)"

	git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
	echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
	source ~/.bashrc
	export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
	rbenv rehash

	echo -e "\n$(tput setaf 1)################## Checking the Rbenv  version ################## $(tput setaf 0)"
	rbenv -v

	echo -e "\n$(tput setaf 1)################## Installing Ruby ################## $(tput setaf 0)"
	sudo apt-get update
	rbenv install $ruby_version
	rbenv global $ruby_version

	echo -e "\n$(tput setaf 1)################## Checking Ruby versions  ################## $(tput setaf 0)"
	rbenv versions

	echo -e "\n$(tput setaf 1)################## Checking Ruby Global version  ################## $(tput setaf 0)"
	ruby -v

	echo -e "\n$(tput setaf 1)################## Installing NodeJS  ################## $(tput setaf 0)"

	echo -e "\n$(tput setaf 1)################## Checking NodeJs version  ################## $(tput setaf 0)"
	nodejs -v

	echo -e "\n$(tput setaf 1)################## Installing Bundler ################## $(tput setaf 0)"
	# disable parsing gem documentation
	echo "gem: --no-document" > ~/.gemrc
	gem uninstall bundler
	gem install bundler -v 1.17.3
	gem install bundler
	gem update --system

	echo -e "\n$(tput setaf 1)################## Installing Graphviz for ERD Gem ################## $(tput setaf 0)"

	echo -e "\n$(tput setaf 1)################## Checking Gem version ################## $(tput setaf 0)"
	gem -v

	echo -e "\n$(tput setaf 1)################## List installed Bundlers ################## $(tput setaf 0)"
	gem list | grep bundler

	echo -e "\n$(tput setaf 1)################## Checking default Bundler version ################## $(tput setaf 0)"
	bundler -v

	echo -e "\n$(tput setaf 1)################## Installing Rails ################## $(tput setaf 0)"
	gem install rails -v 5.2.4
	rbenv rehash

	echo -e "\n$(tput setaf 1)################## Checking Rails version ################## $(tput setaf 0)"
	rails -v

	echo -e "\n$(tput setaf 1)################## Install Nginx & Passenger  ################## $(tput setaf 0)"



	# default -> /etc/nginx/sites-available/default
	# Config nginx: sudo vim /etc/nginx/sites-enabled/default
	nginx_default="server {
			location /cable {
				passenger_app_group_name fms;
				passenger_force_max_concurrent_requests_per_process 0;
			}
	    listen 80;
	    listen [::]:80 ipv6only=on;
	    # SSL configuration
	    #
	    # listen 443 ssl default_server;
	    # listen [::]:443 ssl default_server;
	    server_name $domain;
	    passenger_enabled on;
	    rails_env    staging;
	    root         /home/$deployer_user/$app_name/current/public;
	    # redirect server error pages to the static page /50x.html
	    error_page   500 502 503 504  /50x.html;
	    location = /50x.html {
	      root   html;
	    }
	}"

	touch "/home/$deployer_user/default"
	sudo echo "$nginx_default" > "/home/$deployer_user/default"
	sudo mv "/home/$deployer_user/default" /etc/nginx/sites-available/default

	# Config nginx: sudo vim /etc/nginx/nginx.conf by Uncomment this line: include /etc/nginx/passenger.conf;
	sudo sh -c 'echo "
    user www-data;
    worker_processes auto;
    pid /run/nginx.pid;
    events {
      worker_connections 768;
      # multi_accept on;
    }
	  http {
		  ##
		  # Basic Settings
		  ##
		  sendfile on;
		  tcp_nopush on;
		  tcp_nodelay on;
		  keepalive_timeout 65;
		  types_hash_max_size 2048;
		  # server_tokens off;
		  # server_names_hash_bucket_size 64;
		  # server_name_in_redirect off;
		  include /etc/nginx/mime.types;
		  default_type application/octet-stream;
		  ##
		  # SSL Settings
		  ##
		  ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
		  ssl_prefer_server_ciphers on;
		  ##
		  # Logging Settings
		  ##
		  access_log /var/log/nginx/access.log;
		  error_log /var/log/nginx/error.log;
		  ##
		  # Gzip Settings
		  ##
		  gzip on;
		  gzip_disable "msie6";
		  # gzip_vary on;
		  # gzip_proxied any;
		  # gzip_comp_level 6;
		  # gzip_buffers 16 8k;
		  # gzip_http_version 1.1;
		  # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
		  ##
		  # Phusion Passenger config
		  ##
		  # Uncomment it if you installed passenger or passenger-enterprise
		  ##
		  include /etc/nginx/passenger.conf;
		  ##
		  # Virtual Host Configs
		  ##
		  include /etc/nginx/conf.d/*.conf;
		  include /etc/nginx/sites-enabled/*;
		}
		# mail {
		# # See sample authentication script at:
		# # http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
		#
		# # auth_http localhost/auth.php;
		# # pop3_capabilities "TOP" "USER";
		# # imap_capabilities "IMAP4rev1" "UIDPLUS";
		#
		# server {
		# 	listen     localhost:110;
		#   protocol   pop3;
		#   proxy      on;
		# }
		#
		# server {
		#  	listen     localhost:143;
		#  	protocol   imap;
		#  	proxy      on;
		#  }
		#}
	" > /etc/nginx/nginx.conf'

	# Config nginx: sudo vim /etc/nginx/passenger.conf by Replace passenger_ruby line with this one passenger_ruby /home/deployer/.rbenv/shims/ruby;
	nginx_passenger="
	passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;
	# passenger_ruby /usr/bin/passenger_free_ruby;
	passenger_ruby /home/$deployer_user/.rbenv/shims/ruby;"

	touch "/home/$deployer_user/passenger.conf"
	sudo echo "$nginx_passenger" > "/home/$deployer_user/passenger.conf"
	sudo mv "/home/$deployer_user/passenger.conf" /etc/nginx/passenger.conf

  # Checking nginx # if fail dubeg using: sudo journalctl -xe
  sudo service nginx configtest
	# restart nginx
	sudo service nginx restart

	echo -e "\n$(tput setaf 1)################## Checking Nginx version ################## $(tput setaf 0)"
	nginx -v

	echo -e "\n$(tput setaf 1)################## Checking Nginx status  ################## $(tput setaf 0)"
	sudo service nginx status

	echo -e "\n$(tput setaf 1)################## Create app folders  ################## $(tput setaf 0)"
	mkdir -p "/home/$deployer_user/$app_name"
	mkdir -p "$shared_folder_path/config"
	mkdir -p "$shared_folder_path/log"
	mkdir -p "$shared_folder_path/tmp/pids"
	mkdir -p "$shared_folder_path/tmp/cache"
	mkdir -p "$shared_folder_path/tmp/sockets"
	mkdir -p "$shared_folder_path/vendor/bundle"
	mkdir -p "$shared_folder_path/public/system"
	mkdir -p "$shared_folder_path/public/uploads"
	touch "$shared_folder_path/config/database.yml"
	touch "$shared_folder_path/config/secrets.yml"
	touch "$shared_folder_path/.env"

	env_credentials="
	POSTGRES_DB=$db_name
	POSTGRES_USER=$db_user
	POSTGRES_PASSWORD=123456
	POSTGRES_HOST=localhost
	RAILS_ENV=production
	SECRET_KEY_BASE=
	URL=$domain"
	sudo echo "$env_credentials" > "$shared_folder_path/.env"

	database_credentials="production:
	  adapter: postgresql
	  host: <%= ENV['POSTGRES_HOST']%>
	  database: <%= ENV['POSTGRES_DB'] %>
	  username: <%= ENV['POSTGRES_USER'] %>
	  password: <%= ENV['POSTGRES_PASSWORD'] %>
	  encoding: unicode
	  pool: 5"
	sudo echo "$database_credentials" > "$shared_folder_path/config/database.yml"

	secrets_credentials="production:
	  secret_key_base: <%= ENV['SECRET_KEY_BASE'] %>"

	sudo echo "$secrets_credentials" > "$shared_folder_path/config/secrets.yml"


	echo -e "\n$(tput setaf 1)################## Checking PostgreSQL version ################## $(tput setaf 0)"
	pg_config --version

	echo -e "\n$(tput setaf 1)################## Checking PostgreSQL status  ################## $(tput setaf 0)"
	sudo service postgresql start
	sudo service postgresql status

	echo -e "\n$(tput setaf 1)################## Checking PostgreSQL user ################## $(tput setaf 0)"
	tail -n 5 /etc/passwd

	echo -e "\n$(tput setaf 1)################## Add $deployer_user user publick key ################## $(tput setaf 0)"
	mkdir -p "/home/$deployer_user/.ssh"
	touch "/home/$deployer_user/.ssh/authorized_keys"
	touch "/home/$deployer_user/.ssh/known_hosts"
	sudo cp -r /root/.ssh/authorized_keys "/home/$deployer_user/.ssh/authorized_keys"


	echo -e "\n$(tput setaf 1)################## Summary  ################## $(tput setaf 0)"
	echo "Git version:"
	git version
	echo "Rbenv version:"
	rbenv -v
	echo "Ruby version:"
	ruby -v
	echo "Nodejs version:"
	nodejs -v
	echo "Bundler version:"
	bundler -v
	echo "Gem version:"
	gem -v
	echo "Rails version:"
	rails -v
	echo "Nginx version:"
	nginx -v
	echo "PostgreSQL version:"
	pg_config --version

	echo -e "\n$(tput setaf 1) Login as postgres user: use su postgres to login with it $(tput setaf 0)"
	sudo su - "$postgres_user"
fi

# First add the .env creadintails before using capistrano in deploy
# Generate sercret key locally and add it to .env file on the server
# Enter your app folder   /home/$deployer_user/$app_name
# sudo apt install ruby-bundler -y
# run: bundle exec rake secret
# copy the output
# go to $shared_folder_path/.env
# set the production secret_key_base
# Restart the passenger app  touch $shared_folder_path/tmp/restart.txt
# passenger-config restart-app /home/deploy/devops

# bundle exec rake db:migrate  RAILS_ENV=production
# bundle exec rake db:seed RAILS_ENV=production
echo "please add load_module /usr/lib/nginx/modules/ngx_http_passenger_module.so; in  /etc/nginx/nginx.conf"
echo "please edit and comment  /etc/nginx/conf.d/mod-http-passenger.conf & restart nginx"
echo -e "\n$(tput setaf 21)################## Open on your browser $(dig +short myip.opendns.com @resolver1.opendns.com)  ################## $(tput setaf 0)"

