## How to run this

```sh
APP_NAME='my_new_app'

# Set up runtimes
RUBY_VERSION='3.4.7'
NODE_VERSION='24.11.1'

asdf plugin update ruby
asdf plugin update nodejs
asdf install
asdf local ruby $RUBY_VERSION

# update rubygems, install rails
gem update --system
gem install rails

# Set up .tool-versions
mkdir -p $APP_NAME
cd $APP_NAME
cat << EOF > .tool-versions
ruby $RUBY_VERSION
nodejs $NODE_VERSION
EOF
cd ..

# create new app
rails new $APP_NAME \
  --database=postgresql \
  --asset-pipeline=propshaft \
  --skip-action-mailbox \
  --skip-action-text \
  --skip-active-storage \
  --skip-jbuilder \
  --skip-javascript \
  --skip-kamal \
  --skip-hotwire \
  --skip-test \
  -m ~/.dotfiles/tag-ruby/rails_template/template.rb
```
