# Copyright (C) 2012-2013 Harry Garrood
# This file is a part of redmine_release_notes.

# redmine_release_notes is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.

# redmine_release_notes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.

# You should have received a copy of the GNU General Public License along with
# redmine_release_notes. If not, see <http://www.gnu.org/licenses/>.

Redmine::Plugin.register :redmine_release_notes do
  name 'Redmine release notes plugin'
  author 'Harry Garrood/Eivind Tagseth'
  description 'A plugin for managing release notes.'
  version '2.0.0'
  author_url 'https://github.com/hdgarrood'
  requires_redmine :version_or_higher => '7.0.0'

  # the partial won't be used, but can't be blank, because Redmine needs to
  # think this plugin is configurable
  settings :default => {
      :default_generation_format_id => 1,
      :issue_custom_field_id => 0,
      :field_value_todo => 'Todo',
      :field_value_done => 'Done',
      :field_value_not_required => 'Not required'
    },
    :partial => 'about_blank'

  project_module :release_notes do
    permission :release_notes,
      { :release_notes => [:index, :new, :generate] },
      :public => true
  end
end

# Patches to the Redmine core. init.rb is re-run inside to_prepare on
# every code reload, and the plugin's lib/ directory is on the autoload
# path, so the patches can be applied directly here.
RedmineReleaseNotes::IssuePatch.perform
RedmineReleaseNotes::VersionPatch.perform
RedmineReleaseNotes::SettingsControllerPatch.perform
RedmineReleaseNotes::IssuesControllerPatch.perform
unless IssuesController.include?(RedmineReleaseNotes::IssuesControllerPatch)
  IssuesController.include(RedmineReleaseNotes::IssuesControllerPatch)
end

# Referencing the hook listener forces the autoloader to load it so the
# view hooks are registered also in development mode
RedmineReleaseNotes::Hooks
