## How to run this

```sh
APP_NAME='my_new_app'

# Set up runtimes
RUBY_VERSION='4.0.5'
NODE_VERSION='26.3.1'

mise use -g ruby@$RUBY_VERSION nodejs@$NODE_VERSION

# update rubygems, install rails
gem update --system
gem install rails

# Pin runtimes for the new app
mkdir -p $APP_NAME
printf "ruby %s\nnodejs %s\n" "$RUBY_VERSION" "$NODE_VERSION" > $APP_NAME/.tool-versions

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
