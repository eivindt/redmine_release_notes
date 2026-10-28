require File.expand_path('../../../../../test/test_helper', __FILE__)

class ApiReleaseNotesTest < Redmine::ApiTest::Base
  fixtures :projects, :trackers, :projects_trackers, :issue_statuses,
           :issues, :enumerations, :users, :roles, :members, :member_roles,
           :enabled_modules, :custom_fields, :custom_values

  def setup
    super
    @field = IssueCustomField.create!(:name => 'Release notes',
                                      :field_format => 'list',
                                      :possible_values => ['Todo', 'Done', 'Not required'],
                                      :is_for_all => true,
                                      :tracker_ids => Tracker.pluck(:id))
    Setting.plugin_redmine_release_notes =
      Setting.plugin_redmine_release_notes.merge(:issue_custom_field_id => @field.id)
    @issue = Issue.find(1)
    @issue.custom_field_values = { @field.id => 'Todo' }
    @issue.save!
  end

  def test_create_responds_with_the_release_note
    post '/release_notes.json',
         :params => { :release_note => { :issue_id => @issue.id, :text => 'Fixed it' },
                      :mark_completed => '1' },
         :headers => credentials('jsmith')

    assert_response :created
    note = ActiveSupport::JSON.decode(response.body)['release_note']
    assert_equal @issue.id, note['issue_id']
    assert_equal 'Fixed it', note['text']
    assert_equal 'Done', note['status']
    assert_equal 'Fixed it', @issue.reload.release_note.text
  end

  def test_update_responds_with_the_release_note
    release_note = @issue.create_release_note!(:text => 'Draft')

    put "/release_notes/#{release_note.id}.json",
        :params => { :release_note => { :issue_id => @issue.id, :text => 'Final' } },
        :headers => credentials('jsmith')

    assert_response :ok
    note = ActiveSupport::JSON.decode(response.body)['release_note']
    assert_equal release_note.id, note['id']
    assert_equal 'Final', note['text']
    assert_equal 'Todo', note['status']
  end

  def test_create_without_text_responds_with_validation_errors
    post '/release_notes.json',
         :params => { :release_note => { :issue_id => @issue.id, :text => '' } },
         :headers => credentials('jsmith')

    assert_response :unprocessable_content
    assert ActiveSupport::JSON.decode(response.body)['errors'].any?
  end
end
