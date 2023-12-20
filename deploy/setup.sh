#!/usr/bin/env bash

set -e

# TODO: Set to URL of git repo.
PROJECT_GIT_URL='https://github.com/sanjithhithub/demo.git'

PROJECT_BASE_PATH='/usr/local/apps/venv'

echo "Installing dependencies..."
apt-get update
apt-get install -y python3-dev python3-venv sqlite python-pip supervisor nginx git

# Create project directory
mkdir -p "$PROJECT_BASE_PATH"
git clone "$PROJECT_GIT_URL" "$PROJECT_BASE_PATH"

# Create virtual environment
python3 -m venv "$PROJECT_BASE_PATH/env"

# Activate virtual environment
source "$PROJECT_BASE_PATH/env/bin/activate"

# Install python packages
pip install -r "$PROJECT_BASE_PATH/requirements.txt"
pip install uwsgi==2.0.21

# Run migrations and collectstatic
cd "$PROJECT_BASE_PATH"
python manage.py migrate
python manage.py collectstatic --noinput

echo "DONE! :)"

# Configure supervisor
cp $PROJECT_BASE_PATH/deploy/supervisor_healthapp.conf /etc/supervisor/conf.d/healthapp.conf
supervisorctl reread
supervisorctl update
supervisorctl restart healthapp

echo "DONE! :)"

# Configure nginx
cp $PROJECT_BASE_PATH/deploy/nginx_healthapp.conf /etc/nginx/sites-available/healthapp.conf
# rm /etc/nginx/sites-enabled/default || true
ln -s /etc/nginx/sites-available/healthapp.conf /etc/nginx/sites-enabled/healthapp.conf
systemctl restart nginx.service

echo "DONE! :)"