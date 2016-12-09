module RedmineOneIssueInProcessOnly::IssuePatch
  extend ActiveSupport::Concern

  included do
    before_save :build_time_entry, if: -> { create_time_entry? }
    after_save :in_process_to_on_hold,
               if: -> { in_process_status? },
               unless: :isnt_parent_issue_in_process?
    validate :status_cant_be_in_process, if: :isnt_parent_issue_in_process?
    validates :assigned_to_id, presence: true, if: -> { in_process_status? }
  end

  private

  def in_process_to_on_hold
    Issue
        .where(assigned_to_id: assigned_to_id, status_id: in_process_status_id)
        .where.not(id: id)
        .each do |issue|
          init_journal(
              User.current,
              l(:issue_change_status, scope: 'issue.messages', id: id, status_name: status.name))

          issue.update_attributes(status_id: on_hold_status_id)
        end
  end

  def build_time_entry
    if last_in_process
        time_entries
          .build(
              hours: time_entry_hours,
              user: time_entry_user,
              spent_on: time_entry_spent_on,
              comments: time_entry_comments,
              activity_id: time_entry_activity_id)

        time_entry_journal
          .details
          .build(property: 'attr', prop_key: 'time_entries', value: ('%.2f' % time_entry_hours))
    end
  end

  def time_entry_journal
    if current_journal
      current_journal.notes = [time_entry_comments, current_journal.notes].join("\n\n")
      current_journal
    else
      init_journal(User.current, time_entry_comments)
    end
  end

  def time_entry_comments
    l(:build_time_entry, scope: 'issue.messages',
      user: time_entry_user,
      start_at: format_time(time_entry_spent_on),
      current_at: format_time(current_at),
      hours: ('%.2f' % time_entry_hours)
    )
  end

  def current_at
    Time.current
  end

  def time_entry_spent_on
    @time_entry_spent_on ||= last_in_process.created_on
  end

  def time_entry_user
    @time_entry_user ||= assigned_to_id_changed? ? last_in_process.user : assigned_to
  end

  def time_entry_hours
    @time_entry_hours ||= (current_at - time_entry_spent_on) / 3600
  end

  def last_in_process
    sql = <<-SQL
journal_details.property = 'attr' AND (
  (journal_details.prop_key = 'status_id' AND journal_details.value = :in_process_status_id) OR
  (journal_details.prop_key = 'assigned_to_id' AND journal_details.value = :assigned_to_id))
SQL
    @last_in_process ||=
        journals
            .joins(:details)
            .where(sql, assigned_to_id: "#{User.current.id}", in_process_status_id: in_process_status_id)
            .order('journal_details.id')
            .last
  end

  def status_cant_be_in_process
    if in_process_status?
      errors.add(:status_id, :status_cant_be_in_process, status: status.name)
    end
  end

  def in_process_status?
    status_id == in_process_status_id
  end

  def was_in_process_status?
    status_id_change.try(:first) == in_process_status_id
  end

  def in_process_status_id
    Setting.plugin_redmine_one_issue_in_process_only['in_process_status_id'].to_i
  end

  def on_hold_status_id
    Setting.plugin_redmine_one_issue_in_process_only['on_hold_status_id'].to_i
  end

  def time_entry_activity_id
    Setting.plugin_redmine_one_issue_in_process_only['default_time_entry_activity_id'] || TimeEntryActivity.default.try(:id)
  end

  def isnt_parent_issue_in_process?
    !!Setting.plugin_redmine_one_issue_in_process_only['isnt_parent_issue_in_process'] && children?
  end

  def create_time_entry?
    !!Setting.plugin_redmine_one_issue_in_process_only['create_time_entry'] &&
        (was_in_process_status? || assigned_to_id_changed? && in_process_status?)
  end

end
