[![Code Climate](https://codeclimate.com/github/BookingSync/bookingsync-engine.png)](https://codeclimate.com/github/BookingSync/bookingsync-engine)
[![Build Status](https://travis-ci.org/BookingSync/bookingsync-engine.png?branch=master)](https://travis-ci.org/BookingSync/bookingsync-engine)

# BookingSync Engine

## Requirements

This engine requires Rails `>= 4.0.0` and Ruby `>= 2.0.0`.

## Documentation

[API documentation is available at rdoc.info](http://rdoc.info/github/BookingSync/bookingsync-engine/master/frames).

## Instalation

BookingSync Engine works with Rails 4.0 onwards and Ruby 2.0 onwards. To get started, add it to your Gemfile with:

```ruby
gem 'bookingsync-engine'
```

Then, generate a migration to add OAuth fields for the `Account` class:

```console
rails g migration AddOAuthFieldsToAccounts provider:string uid:integer:index \
  name:string oauth_access_token:string oauth_refresh_token:string \
  oauth_expires_at:string
```

and migrate:

```console
rake db:migrate
```

And include `BookingSync::Engine::Account` in your `Account` model:

```ruby
class Account < ActiveRecord::Base
  include BookingSync::Engine::Model
end
```

## Configuration

The engine is configured by the following ENV variables:

* `BOOKINGSYNC_URL` - the url of the website, should be
* `BOOKINGSYNC_APP_ID` - OAuth application id
* `BOOKINGSYNC_APP_SECRET` - OAuth application secret
* `BOOKINGSYNC_VERIFY_SSL` - Verify SSL (available only in development or test, but not required). Default to false
* `BOOKINGSYNC_SCOPE` - Space separated list of required scopes. Defaults to nil, which means the public scope.

## Embedded vs Standalone apps

The engine is set up by default to work with Embedded app for the [BookingSync](http://www.bookingsync.com) app store. This means that the OAuth flow will redirect using javascript
redirect to break out of the iframe.

### Embedded apps

Embedded apps will need to allow BookingSync to load them in an
[iframe](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe). Redirect uri and Admin url are **required** for this type of application.

**This only has to be applied to the part of the application used in BookingSync**

You can use the following helper in your controller to do just that:

```ruby
after_action :allow_bookingsync_iframe
```

### Standalone apps

Standalone applications will be working outside of [BookingSync](http://www.bookingsync.com) website. While it's not the recommended approach, some applications can benefit from this.

To make your application standalone, you must set the standalone mode by adding
the following code to an initializer:

```ruby
BookingSync::Engine.standalone!
```

## Authentication in apps

BookingSync Engine will create some helpers to use inside your controllers and views. To set up a controller with BookingSync account authentication, just add this before_filter:

```ruby
before_filter :authenticate_account!
```
It will make sure an account is authenticated (using OAuth).


To retrieve the current signed-in account, this helper is available:

```ruby
current_account
```

## Securing applications

### Session cookies

You should make sure session cookies for you application have the `secure`
flag. This will be done by Rails automatically if you have configured
your environment with `config.force_ssl = true`. If not, you can change your
`session_store.rb` initializer:

```ruby
Rails.application.config.session_store :cookie_store,
  key: '_your-app_session', secure: true
```
