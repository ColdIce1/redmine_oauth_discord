#!/bin/sh
cd /usr/local/redmine

echo "Running post-create.sh"

bundle install 
bundle exec rake redmine:plugins:migrate
bundle exec rake redmine:plugins:migrate RAILS_ENV=test

bundle exec rails c  << EOF
    user = User.where(id: 1).first
    user.must_change_passwd = 0
    user.save!
EOF

initdb() {
    bundle exec rake db:create
    bundle exec rake db:migrate
    bundle exec rake redmine:plugins:migrate

    bundle exec rake db:drop RAILS_ENV=test
    bundle exec rake db:create RAILS_ENV=test
    bundle exec rake db:migrate RAILS_ENV=test
    bundle exec rake redmine:plugins:migrate RAILS_ENV=test

    bundle exec rails c  << EOF
        user = User.where(id: 1).first
        user.must_change_passwd = 0
        user.save!
EOF
}

export DB=postgres
initdb

export DB=mysql
initdb