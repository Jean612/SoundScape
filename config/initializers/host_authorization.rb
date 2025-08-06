# Force disable host authorization for Render deployment
Rails.application.configure do
  config.hosts.clear
  config.host_authorization = false
end