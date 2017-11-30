# Master

# 3.0.2

* Don't escape transaction when updating token to use less DB connections and avoid possible leaking.
* update bookingsync-api to fix `Net::HTTP::Persistent too many connection resets` error

# 3.0.1 (2017-07-04)

* Fix content type for request authorization flow

# 3.0.0 (2017-06-21)

* Add support for Rails 5.1
* Drop support for Rails prior to 5.0

# 2.0.2 (2017-06-14)

* Make internal API of APIClient more flexible

# 2.0.1 (2017-04-27)

* Cleanup update, mostly regarding Gemfiles

# 2.0.0 (2017-04-27)

* Bump omniauth-bookingsync to ~>0.5.0
* Drop rails 4.1 support
* Add ruby 2.3.3 in Travis

# 1.1.0 (2016-08-23)

* Bump omniauth-bookingsync to ~>0.4.0

# 1.0.2 (2015-10-28)

* Bump omniauth-bookingsync to ~>0.3.0

# 1.0.1 (2015-07-31)

* Cleanup deprecated warnings about routes mounting
* Update `bookingsync-api` which fix `addressable` dependency

# 1.0.0 (2015-07-31)

* BREAKING CHANGE: Rename account `synced_key` from `uid` to `synced_id`
* Update appraisals gemfiles to match version 0.5.0.

# 0.5.0 (2015-04-12)

* Use new thread to ensure refresh_token update during transaction.

# 0.4.6 (2015-02-18)

* Fix gem autoloading, allows proper chaining.

# 0.4.5 (2015-02-17)

* Ensure code included when use multiple inderdependent engines.

# 0.4.4 (2015-02-13)

* Don't capture all /auth/:provider/callback routes, only /auth/bookingsync/callback.

# 0.4.3 (2015-02-12)

* Fix infinite recursion when refreshing token.

# 0.4.1 (2015-02-12) (yanked)

* Fix Model#api to use the new APIClient class.

# 0.4.0 (2015-02-12) (yanked)

* Add BookingSync::Engine::APIClient that will automatically refresh tokens when the API
  returns 401.

# 0.3.0 (2015-01-14)

* BREAKING CHANGE: bookingsync-engine routes have to be mounted explicitly within the app with mount BookingSync::Engine => '/'

# 0.2.2 (2014-11-21)

* Ensure that account's UID is uniq

# 0.2.1 (2014-11-13)

* Require bookingsync-api 0.0.22 to support 403 errors

# 0.2.0 (2014-09-23)

* Return 401 Unauthorized when unauthorized and requested by Ajax call.

# 0.1.0 (2014-06-11)

* First public versioned release.
