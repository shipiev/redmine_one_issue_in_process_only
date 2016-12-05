module RedmineOneIssueInProcessOnly::IssuePatch
  extend ActiveSupport::Concern

  included do
    before_save :save_current_status_id
    after_save :in_process_to_on_hold,
               if: -> { in_process_status? && @prev_status_id == in_process_status_id },
               unless: :isnt_parent_issue_in_process
    validate :status_cant_be_in_process, if: :isnt_parent_issue_in_process
  end

  private

  def in_process_to_on_hold
    Issue
        .where(assigned_to_id: User.current.id, status_id: in_process_status_id)
        .where.not(id: id)
        .each do |issue|
          issue.update_attributes(status_id: on_hold_status_id)
        end
  end

  def save_current_status_id
    @prev_status_id = status_id_change&.last
  end

  def status_cant_be_in_process
    if in_process_status?
      errors.add(:status_id, :status_cant_be_in_process, status: status.name)
    end
  end

  def in_process_status?
    status_id == in_process_status_id
  end

  def in_process_status_id
    Setting.plugin_redmine_one_issue_in_process_only['in_process_status_id'].to_i
  end

  def on_hold_status_id
    Setting.plugin_redmine_one_issue_in_process_only['on_hold_status_id'].to_i
  end

  def isnt_parent_issue_in_process
    !!Setting.plugin_redmine_one_issue_in_process_only['isnt_parent_issue_in_process'] && children?
  end
end
