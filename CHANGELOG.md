# master

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
