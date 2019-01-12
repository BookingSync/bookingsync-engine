[![Code Climate](https://codeclimate.com/github/BookingSync/bookingsync-engine.png)](https://codeclimate.com/github/BookingSync/bookingsync-engine)
[![Build Status](https://travis-ci.org/BookingSync/bookingsync-engine.png?branch=master)](https://travis-ci.org/BookingSync/bookingsync-engine)

# BookingSync Engine

## Requirements

This engine requires Rails `>= 5.0.0` and Ruby `>= 2.3.0`.

## Documentation

[API documentation is available at rdoc.info](http://rdoc.info/github/BookingSync/bookingsync-engine/master/frames).

## Installation

BookingSync Engine works with Rails 4.2 onwards and Ruby 2.2 onwards. To get started, add it to your Gemfile with:

```ruby
gem 'bookingsync-engine'
```

Then bundle install:

```ruby
bundle install
```

Then mount BookingSync Authorization routes inside `routes.rb`:
```ruby
mount BookingSync::Engine => '/'
```

This will add the following routes:

* `/auth/bookingsync/callback`
* `/auth/failure`
* `/signout`


BookingSync Engine uses the `Account` model to authenticate each BookingSync Account, if you do not have an `Account` model yet, create one:

```console
rails g model Account
```

### For single application setup

Then, generate a migration to add OAuth fields for the `Account` class:

```console
rails g migration AddOAuthFieldsToAccounts provider:string synced_id:integer:index \
  name:string oauth_access_token:string oauth_refresh_token:string \
  oauth_expires_at:string
```

and migrate:

```console
rake db:migrate
```

Also include `BookingSync::Engine::Models::Account` in your `Account` model:

```ruby
class Account < ActiveRecord::Base
  include BookingSync::Engine::Models::Account
end
```

When saving new token, this gem uses a separate thread with new db connection to ensure token save (in case of a rollback in the main transaction).


### For multi application setup

Then, generate a migration to add OAuth fields for the `Account` class:

```console
rails g migration AddOAuthFieldsToAccounts provider:string synced_id:integer:index \
  name:string oauth_access_token:string oauth_refresh_token:string \
  oauth_expires_at:string  host:string:uniq:index
```

Add manually `null: false` to the `host` field on the newly created migration file, then migrate:

```console
rake db:migrate
```

Also include `BookingSync::Engine::Models::MultiApplicationsAccount` in your `Account` model:

```ruby
class Account < ActiveRecord::Base
  include BookingSync::Engine::Models::MultiApplicationsAccount
end
```

When saving new token, this gem uses a separate thread with new db connection to ensure token save (in case of a rollback in the main transaction). To make room for the new connections, it is recommended to increase db `pool` size by 2-3.


You also need to create applications

```console
rails g model Application
```

Then, generate a migration to add credentials fields for the `Application` class:

```console
rails g migration AddCredentialsFieldsToApplications host:string:uniq:index client_id:text:uniq:index \
  client_secret:text:uniq:index
```

Add `null: false` to this 3 attributes, then migrate:

```console
rake db:migrate
```

Also include `BookingSync::Engine::Models::Application` in your `Application` model:

```ruby
class Application < ActiveRecord::Base
  include BookingSync::Engine::Models::Application
end
```

## Configuration

The engine is configured by the following ENV variables:

* `BOOKINGSYNC_URL` - the url of the website, should be
* `BOOKINGSYNC_APP_ID` - BookingSync Application's Client ID
* `BOOKINGSYNC_APP_SECRET` - BookingSync Application's Client Secret
* `BOOKINGSYNC_VERIFY_SSL` - Verify SSL (available only in development or test). Default to false
* `BOOKINGSYNC_SCOPE` - Space separated list of required scopes. Defaults to nil, which means the public scope.

You might want to use [dotenv-rails](https://github.com/bkeepers/dotenv)
to make ENV variables management easy.

## Embedded vs Standalone apps

The engine is set up by default to work with Embedded app for the [BookingSync](http://www.bookingsync.com) app store. This means that the OAuth flow will redirect using javascript
redirect to break out of the iframe.

### Embedded apps

Embedded apps will need to allow BookingSync to load them in an
[iframe](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe).

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

BookingSync Engine will create some helpers to use inside your controllers and views.

### Ensure authentication

To set up a controller with BookingSync account authentication, just add this `before_action`:

```ruby
before_action :authenticate_account!
```
It will make sure an account is authenticated (using OAuth2).

### New authorization process

If the user is not currently authenticated, 3 responses can be expected:

#### 1) Through Ajax requests

By Ajax request, we consider them when the `X-Requested-With` header contains `XMLHttpRequest`.

In this case, the authorization path will be returned a plain text with a **401 Unauthorized** status.

#### 2) Embedded Application

Embedded applications will be given a script tag forcing them to change their parent location to the authorization path. This is necessary so the authorization happens in the main window, not within an iFrame.

#### 3) Standalone Application

Standalone applications will simply be redirected to the authorization path.

### Accessing the current account

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

## Contributing

We would love to see you contributing. Please, just follow the guidelines from [https://github.com/BookingSync/contributing](https://github.com/BookingSync/contributing)

### Testing

By default, your tests will run against the Rails version used in the main Gemfile.lock, to test against all supported Rails version, please run the tests with Appraisals with: `appraisal rake spec`
