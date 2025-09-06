## How to run this

```sh
# install latest rails
gem install rails

# create new app
rails new my_new_app \
  --database=postgresql \
  --asset-pipeline=propshaft \
  --skip-action-mailbox \
  --skip-action-text \
  --skip-active-storage \
  --skip-jbuilder \
  --skip-javascript \
  --skip-hotwire \
  --skip-test \
  --edge \
  -m ~/.dotfiles/tag-ruby/rails_template/template.rb
```
