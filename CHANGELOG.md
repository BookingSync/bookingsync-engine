# master

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
