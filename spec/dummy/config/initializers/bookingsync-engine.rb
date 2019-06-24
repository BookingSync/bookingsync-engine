# temporarily change default to make sure initializer override works great
BookingSyncEngine.module_eval do
  self.bookingsync_id_key = :customized_key
end

# and now override to fix breaking specs
BookingSyncEngine.setup do |setup|
  setup.multi_app_model = -> { ::MultiApplicationsAccount }

  setup.bookingsync_id_key = :synced_id
end
