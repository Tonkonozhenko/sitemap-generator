#!/bin/bash

sudo apt-get update
sudo apt-get install curl git redis-server redis-tools -y

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable

if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  # First try to load from a user install
  source "$HOME/.rvm/scripts/rvm"
  echo "using user install $HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  # Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"
  echo "using root install /usr/local/rvm/scripts/rvm"
else
  echo "ERROR: An RVM installation was not found.\n"
fi

rvm requirements
rvm install 2.2
rvm use 2.2 --default

cd /vagrant

cp .env.example .env

bundle install
bundle exec rackup -p 3000 -o 0.0.0.0 -P ./.pid -D
bundle exec sidekiq -c 100 -C sidekiq.yml -r ./parser_worker.rb -L sidekiq.log -d