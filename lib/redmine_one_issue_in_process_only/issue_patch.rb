module RedmineOneIssueInProcessOnly::IssuePatch
  extend ActiveSupport::Concern

  included do
    attr_accessor :dont_repeat_youself
    after_save :in_process_to_on_hold, if: :in_process_status?, unless: :dont_repeat_youself
  end

  def in_process_to_on_hold
    # Сделано так, чтобы смена статуса отразилась в Журнале. Потом будет возможность посчитать реальное
    # затраченное время на задачу (с учетом рабочего расписания).
    Issue.where(assigned_to_id: User.current.id, status_id: in_process_status_id).where.not(id: id).each do |issue|
      issue.status_id = on_hold_status_id
      issue.dont_repeat_youself = true
      issue.save
    end
  end

  private

  def in_process_status?
    status_id == in_process_status_id
  end

  def in_process_status_id
    Setting.plugin_redmine_one_issue_in_process_only[:in_process_status_id].to_i
  end

  def on_hold_status_id
    Setting.plugin_redmine_one_issue_in_process_only[:on_hold_status_id].to_i
  end
end
