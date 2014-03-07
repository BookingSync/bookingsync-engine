[![Code Climate](https://codeclimate.com/github/BookingSync/bookingsync-engine.png)](https://codeclimate.com/github/BookingSync/bookingsync-engine)

# BookingSync Engine

## Instalation

To get started, add the `bookingsync-engine` gem to your Gemfile.

Then, generate a migration for the `Account` class:

```
$ rails g migration CreateAccounts provider:string uid:integer:index name:string oauth_access_token:string oauth_refresh_token:string oauth_expires_at:string
$ rake db:migrate
```

## Configuration

The engine is configured by the following ENV variables:

* `BOOKINGSYNC_URL` - the url of the website, should be
* `BOOKINGSYNC_APP_ID` - OAuth application id
* `BOOKINGSYNC_APP_SECRET` - OAuth application secret
* `BOOKINGSYNC_VERIFY_SSL` - Verify SSL (available only in development or test). Default to false

## Embedded vs Standalone apps

The engine is set up by default to work with Embedded app for the BookingSync
app store. This means that the OAuth flow will redirect using javascript
redirect to break out of the iframe.

**This default behavior breaks standalone applications**

For standalone applications, you must set the standalone mode by adding
the following code to an initializer:

```ruby
BookingSync::Engine.standalone!
```
