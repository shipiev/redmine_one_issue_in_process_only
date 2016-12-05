plugin_name = 'redmine_one_issue_in_process_only'

require plugin_name

Redmine::Plugin.register plugin_name.to_sym do
  name 'One Issue In Process Only'
  author 'Roman Shipiev'
  description 'For each assingned_to-user can be only one Issue in status "In Process"'
  version "#{plugin_name.camelize}::VERSION".constantize
  url "https://github.com/shipiev/#{plugin_name}"
  author_url 'http://roman.shipiev.pro'

  settings default: {'in_process_status_id' => nil, 'on_hold_status_id' => nil, 'isnt_parent_issue_in_process' => nil},
           partial: "settings/#{plugin_name}"
end

Rails.configuration.to_prepare do
  require_patch plugin_name, %w(issue)
end