# Master

# 6.0.1 (2021-07-16)

* Allow to specify iframe redirect option via `BOOKINGSYNC_IFRAME` environment variable

# 6.0.0 (2021-02-25)

* Support omniauth `~> 2.0` version to fix CVE-2015-9284
* Add support for customization of account's bookingsync_id_key (`synced_id` is kept as default)

# 5.1.0 (2020-04-01)

* Add configuration for token refresh timeout and retry count

# 5.0.0 (2020-04-01)

* Add support for Rails 6.0
* Drop support for Ruby prior to 2.5 (to satisfy Rails 6 requirements)

# 4.0.3 (2019-07-18)

* Revert setting `refresh_token!` private

# 4.0.2 (2019-07-17)

* Fix module lookup

# 4.0.1 (2019-07-17)

* Fix `AuthHelpers` include when `helper_method` is missing

# 4.0.0 (2019-04-24)

* Add support for multi application setup
* BREAKING CHANGE: Account models method `from_omniauth` now takes the host as second argument
* BREAKING CHANGE: Rename BookingSync::Engine::Model in BookingSync::Engine::Models::Account
* BREAKING CHANGE: Drop support of Ruby 2.2
* Relax omniauth-bookingsync requirements to >= 0.5.0

# 3.0.2 (2017-11-30)

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
