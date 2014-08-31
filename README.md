A Ruby client for accessing your Trackvia application data.

## Installation

Add to your application's Gemfile:

  gem 'trackvia-client'

Then execute:

  bundle install

## Usage

Start by trying to authenticate your user and make a simple request:

  @client = Trackvia::Client.new(user_key: "abcd1234")
  @client.authorize('username', 'password')
  apps = @client.getApps

Obtain a 'user_key' by signing up at Trackvia's Developer Portal:

  https://developer.trackvia.com

The client interface is more fully explained in the Ruby Docs and
integration test hosted on Github.

  http://rubygems.org/gems/trackvia-client

Source code:

  https://github.com/Trackvia/API-SDK-Ruby

Direct link to Ruby docs:

  http://rubydoc.info/gems/trackvia-client/0.0.1/frames

### Logging

Client logs are stored in:

  trackvia-client.log

Automatic log-file rotation occurs every 7 days.

HTTP logging is managed by rest-client, saved to a file specified by whatever file
name is assigned to the environment variable, RESTCLIENT_LOG.

  export RESTCLIENT_LOG=/path/to/your/logfile

