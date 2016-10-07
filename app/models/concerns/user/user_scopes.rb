module User::UserScopes
  extend ActiveSupport::Concern

  included do
    scope :active, ->{ where('deactivated_at IS NULL') }
    scope :with_user_totals, -> {
      joins("LEFT OUTER JOIN user_totals ON user_totals.user_id = users.id")
    }

    scope :who_contributed_project, ->(project_id) {
      where("id IN (SELECT user_id FROM contributions WHERE contributions.state = 'confirmed' AND project_id = ?)", project_id)
    }

    scope :subscribed_to_posts, -> {
       where("id NOT IN (
         SELECT user_id
         FROM unsubscribes
         WHERE project_id IS NULL)")
     }

    scope :subscribed_to_project, ->(project_id) {
      who_contributed_project(project_id).
      where("id NOT IN (SELECT user_id FROM unsubscribes WHERE project_id = ?)", project_id)
    }

    scope :by_email, ->(email){ where('email ~* ?', email) }
    scope :by_payer_email, ->(email) {
      where('EXISTS(
        SELECT true
        FROM contributions
        JOIN payment_notifications ON contributions.id = payment_notifications.contribution_id
        WHERE contributions.user_id = users.id AND payment_notifications.extra_data ~* ?)', email)
    }
    scope :by_name, ->(name){ where('users.name ~* ?', name) }
    scope :by_id, ->(id){ where(id: id) }
    scope :by_key, ->(key){ where('EXISTS(SELECT true FROM contributions WHERE contributions.user_id = users.id AND contributions.key ~* ?)', key) }
    scope :has_credits, -> { where('user_totals.credits > 0') }
    scope :only_organizations, -> { where(access_type: 1) }
    scope :already_used_credits, -> {
      has_credits.
      where("EXISTS (SELECT true FROM contributions b WHERE b.credits AND b.state = 'confirmed' AND b.user_id = users.id)")
    }
    scope :has_not_used_credits_last_month, -> { has_credits.
      where("NOT EXISTS (SELECT true FROM contributions b WHERE current_timestamp - b.created_at < '1 month'::interval AND b.credits AND b.state = 'confirmed' AND b.user_id = users.id)")
    }

    scope :to_send_category_notification, -> (category_id) {
      where("NOT EXISTS (
            select true from category_notifications n
            where n.template_name = 'categorized_projects_of_the_week' AND
            n.category_id = ? AND
            (n.created_at AT TIME ZONE '#{Time.zone.tzinfo.name}' + '7 days'::interval) >= current_timestamp AT TIME ZONE '#{Time.zone.tzinfo.name}' AND
            n.user_id = users.id)", category_id)
    }
    scope :order_by, ->(sort_field){ order(sort_field) }
    scope :with_visible_projects, -> { joins(:projects).where.not(projects: {state: ['draft', 'rejected', 'deleted', 'in_analysis']}) }

    scope :staff, -> { where(staff_members_query) }
  end
end
