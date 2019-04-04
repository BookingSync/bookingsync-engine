BookingSyncEngine.setup do |setup|
  setup.multi_app_model = -> { ::MultiApplicationsAccount }
end
