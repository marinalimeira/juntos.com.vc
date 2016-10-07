class User < ActiveRecord::Base
  include User::OmniauthHandler
  include User::UserScopes

  has_notifications
  acts_as_copy_target

  devise          :database_authenticatable,
                  :registerable,
                  :recoverable,
                  :rememberable,
                  :trackable,
                  :omniauthable

  delegate        :display_name,
                  :display_image,
                  :short_name,
                  :display_image_html,
                  :medium_name,
                  :display_credits,
                  :display_total_of_contributions,
                  :contributions_text,
                  :twitter_link,
                  :gravatar_url,
                  :display_bank_account,
                  :display_bank_account_owner,
                  :larger_display_image,
                  :projects_count,
                  :display_pending_documents,
                  :display_project_not_approved,
                  :following_this_category?,
                  :display_unsuccessful_project_count,
                  :display_last_unsuccessful_project_expires_at,
                  :to_analytics_json,
                  :to_param,
                  :display_user_projects_link,
                  to: :decorator

  attr_accessible :email, :password, :password_confirmation, :remember_me,
                  :name, :image_url, :uploaded_image, :bio, :newsletter, :full_name,
                  :address_street, :address_number, :address_complement, :address_city,
                  :address_neighbourhood, :address_state, :address_zip_code, :phone_number,
                  :cpf, :state_inscription, :locale, :twitter, :facebook_link, :other_link,
                  :moip_login, :deactivated_at, :reactivate_token, :bank_account_attributes,
                  :access_type, :responsible_name, :responsible_cpf, :mobile_phone, :gender,
                  :staffs, :job_title, :birth_date, :admin, :original_doc1_url,
                  :original_doc2_url, :original_doc3_url, :original_doc4_url,
                  :original_doc5_url, :original_doc6_url, :original_doc7_url,
                  :original_doc8_url, :original_doc9_url, :original_doc10_url,
                  :original_doc11_url, :original_doc12_url, :original_doc13_url

  enum access_type:  [:individual, :legal_entity]
  enum gender:       [:male, :female]

  STAFFS = {
    team:             0,
    financial_board:  1,
    technical_board:  2,
    advice_board:     3
  }

  mount_uploader :uploaded_image, UserUploader

  validates :bio, length: { maximum: 140 }
  validates :access_type, presence: true

  validates :email,
              presence: true,
              uniqueness: { message: I18n.t('activerecord.errors.models.user.attributes.email.taken') },
              format: { with: Devise.email_regexp }

  validates :password,
              presence: true, if: :password_required?,
              confirmation: true, if: :password_confirmation_required?,
              length: { within: Devise.password_length }

  belongs_to :channel
  belongs_to :country
  has_one    :user_total
  has_one    :bank_account
  has_many   :credit_cards
  has_many   :contributions
  has_many   :authorizations
  has_many   :channel_posts
  has_many   :channels_subscribers
  has_many   :projects
  has_many   :unsubscribes
  has_many   :project_posts
  has_many   :contributed_projects, -> { where(contributions: { state: 'confirmed' } ).uniq } ,through: :contributions, source: :project
  has_many   :category_followers
  has_many   :categories, through: :category_followers

  has_and_belongs_to_many :recommended_projects, join_table: :recommendations, class_name: 'Project'
  has_and_belongs_to_many :subscriptions, join_table: :channels_subscribers, class_name: 'Channel'

  accepts_nested_attributes_for :unsubscribes, allow_destroy: true rescue puts "No association found for name 'unsubscribes'. Has it been defined yet?"
  accepts_nested_attributes_for :bank_account, allow_destroy: true

  def self.find_active!(id)
    self.active.where(id: id).first!
  end

  def send_credits_notification
    self.notify(:credits_warning)
  end

  def change_locale(language)
    self.update_attributes locale: language if locale != language
  end

  def active_for_authentication?
    super && !deactivated_at
  end

  def reactivate
    self.update_attributes deactivated_at: nil
    self.update_attributes reactivate_token: nil
  end

  def deactivate
    self.notify(:user_deactivate)
    self.update_attributes deactivated_at: Time.now
    self.update_attributes reactivate_token: Devise.friendly_token
    self.contributions.update_all(anonymous: true)
  end

  def made_any_contribution_for_this_project?(project_id)
    contributions.available_to_count.where(project_id: project_id).present?
  end

  def credits
    user_total.try(:credits).to_f
  end

  def projects_in_reminder
    p = Array.new
    reminder_jobs = Sidekiq::ScheduledSet.new.select do |job|
      job['class'] == 'ReminderProjectWorker' && job.args[0] == self.id
    end
    reminder_jobs.each do |job|
      p << Project.find(job.args[1])
    end
    return p
  end

  def total_contributed_projects
    user_total.try(:total_contributed_projects).to_i
  end

  def has_no_confirmed_contribution_to_project(project_id)
    contributions.where(
      project_id: project_id
    ).with_states(
      [
        'confirmed',
        'waiting_confirmation'
      ]
    ).empty?
  end

  def created_today?
    self.created_at.to_date == Date.today && self.sign_in_count <= 1
  end

  def posts_subscription
    unsubscribes.posts_unsubscribe(nil)
  end

  def project_unsubscribes
    contributed_projects.map do |p|
      unsubscribes.posts_unsubscribe(p.id)
    end
  end

  def fix_twitter_user
    self.twitter.gsub!(/@/, '') if self.twitter
  end

  def fix_facebook_link
    if self.facebook_link && !self.facebook_link[/^https?:\/\//]
      self.facebook_link = ('http://' + self.facebook_link)
    end
  end

  def has_valid_contribution_for_project?(project_id)
    contributions.with_state(
      [
        'confirmed',
        'requested_refund',
        'waiting_confirmation'
      ]
    ).where(project_id: project_id).present?
  end

  def self.staff_array
    STAFFS.map do |name, value|
      [User.human_attribute_name("staff/#{name}"), value]
    end
  end

  def approved?
    individual_access_type? || (approved_at && approved_at > Time.now - 1.year)
  end

  def pending_documents?
    individual_access_type? && !(original_doc12_url? && original_doc13_url?)
  end

  def documents_list
    return [:original_doc12_url, :original_doc13_url] if individual_access_type?

    [
      :original_doc1_url, :original_doc2_url, :original_doc3_url,
      :original_doc4_url, :original_doc5_url, :original_doc6_url,
      :original_doc7_url, :original_doc8_url, :original_doc9_url,
      :original_doc10_url, :original_doc11_url, :original_doc12_url,
      :original_doc13_url
    ]
  end

  def self.staff_members_query
    STAFFS.values.map { |value| "staffs @> ARRAY[#{value}]" }.join(' OR ')
  end

  private

  def decorator
    @decorator ||= UserDecorator.new(self)
  end

  def password_required?
    !persisted? || !password || !password_confirmation
  end

  def password_confirmation_required?
    !new_record?
  end

  def individual_access_type?
    access_type == 'individual'
  end
end
