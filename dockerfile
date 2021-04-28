# Generate a docker image with a fresh install of Rails 5.25
# with development tools.
# The rails install uses postgres.
#
FROM ruby:2.6-alpine

#
RUN apk add --update --no-cache \
  build-base \
  bash \
  curl \
  tree \
  postgresql-dev \
  nodejs-current \
  yarn \
  tzdata \
  git \
  keychain \
  neovim \ 
  sudo \
  openssh-client

# Set app_name for interpolation
ARG app_name=wca

# Sets environment variable
ENV app_name wca

# Add user with same name as app
RUN addgroup -g 1000 -S $app_name \
 && adduser -h /$app_name -s /bin/bash -u 1000 -S $app_name -G $app_name

# Make app user superuser. (Development only)
# Switch to app user
USER $app_name
WORKDIR $app_name
RUN mkdir -p .config/nvim
#ADD --chown=$app_name:$app_name ./.bundle .bundle
ADD --chown=$app_name:$app_name ./dev_docker/bashrc .bashrc
ADD --chown=$app_name:$app_name ./dev_docker/init.vim .config/nvim/init.vim
RUN sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
RUN sh -c "nvim +PlugInstall +qall "
RUN bundle init
RUN echo "gem 'rails', '~> 5.2.5'" >> Gemfile
RUN echo "export PATH=./bin:$PATH" >> .bashrc
USER $app_name
# "vendor everything"
RUN bundle config path vendor/bundle
#RUN gem install 'rails' --version '~> 5.2.5'

# Installs rails gem
RUN bundle install 

# Create rails app in current directory
RUN bundle exec rails new . --skip-bundle --skip-action-cable --skip-action-mailer --skip-action-mailbox --skip-action-text --skip-active-storage --skip-bootsnap --skip-javascript --skip-spring --skip-system-test --skip-webpack-install --skip-turbolinks --database  postgresql -f --skip-bundle

# update Gem depencies
RUN bundle update
USER $app_name
ADD --chown=$app_name:$app_name ./dev_docker/database.yml .config/database.yml
USER root
RUN echo 'wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel
USER $app_name
#RUN echo `bin/rails --version`
#RUN sudo apk add zsh
ADD --chown=$app_name:$app_name ./dev_docker/database.yml ./config/database.yml
RUN bundle update
#
