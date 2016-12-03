plugin_name = :redmine_one_issue_in_process_only

Redmine::Plugin.register plugin_name do
  name 'One Issue In Process Only'
  author 'Roman Shipiev'
  description 'For each assingned_to-user can be only one Issue in status "In Process"'
  version '0.0.1'
  url "https://github.com/shipiev/#{plugin_name}"
  author_url 'http://roman.shipiev.pro'

  settings default: {in_process_status_id: nil, on_hold_status_id: nil},
           partial: "settings/#{plugin_name}"
end

Rails.configuration.to_prepare do
  require_patch plugin_name, %w(issue)
end