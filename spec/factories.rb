FactoryGirl.define do
  sequence :name do |n|
    "Foo bar #{n}"
  end

  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :uid do |n|
    "#{n}"
  end

  sequence :permalink do |n|
    "foo_page_#{n}"
  end

  factory :channel_partner do |f|
    f.url "http://google.com"
    f.image File.open("#{Rails.root}/spec/support/testimg.png")
    f.association :channel
  end

  factory :category_follower do |f|
    f.association :user
    f.association :category
  end

  factory :user do |f|
    f.name "Foo bar"
    f.password "123456"
    f.email { generate(:email) }
    f.bio "This is Foo bar's biography."

    factory :user_with_projects do
      transient do
        projects_count 1
      end

      after(:create) do |user, evaluator|
        create_list(:project, evaluator.projects_count, user: user)
      end
    end
  end

  factory :category do |f|
    f.name_pt { generate(:name) }
  end

  factory :project do |f|
    f.name "Foo bar"
    f.permalink { generate(:permalink) }
    f.association :user, factory: :user
    f.association :category, factory: :category
    f.about "Foo bar"
    f.headline "Foo bar"
    f.goal 10000
    f.online_date Time.now
    f.online_days 5
    f.more_links 'Ipsum dolor'
    f.first_contributions 'Foo bar'
    f.video_url 'http://vimeo.com/17298435'
    f.state 'online'

    factory :project_with_channel do
      after(:create) do |project|
        channel = create :channel
        project.channels << channel
      end
    end
  end

  factory :channels_subscriber do |f|
    f.association :user
    f.association :channel
  end

  factory :unsubscribe do |f|
    f.association :user, factory: :user
    f.association :project, factory: :project
  end

  factory :notification do |f|
    f.association :user, factory: :user
    f.association :contribution, factory: :contribution
    f.association :project, factory: :project
    f.template_name 'project_success'
    f.origin_name 'Foo Bar'
    f.origin_email 'foo@bar.com'
    f.locale 'pt'
  end

  factory :reward do |f|
    f.association :project, factory: :project
    f.minimum_value 10.00
    f.description "Foo bar"
    f.deliver_at 10.days.from_now
  end

  factory :contribution do |f|
    f.association :project, factory: :project
    f.association :user, factory: :user
    f.confirmed_at Time.now
    f.value 10.00
    f.project_value 10.00
    f.state 'confirmed'
    f.credits false
    f.payment_id '1.2.3'

    trait :confirmed do
      state 'confirmed'
    end

    trait :requested_refund do
      state 'requested_refund'
    end

    trait :pending do
      state 'pending'
    end

    trait :waiting_confirmation do
      state 'waiting_confirmation'
    end

    trait :canceled do
      state 'canceled'
    end

    trait :refunded do
      state 'refunded'
    end

    trait :refunded_and_canceled do
      state 'refunded_and_canceled'
    end

    trait :deleted do
      state 'deleted'
    end

    trait :invalid_payment do
      state 'invalid_payment'
    end
  end

  factory :payment_notification do |f|
    f.association :contribution, factory: :contribution
    f.extra_data {}
  end

  factory :authorization do |f|
    f.association :oauth_provider
    f.association :user
    f.uid 'Foo'
  end

  factory :oauth_provider do |f|
    f.name 'facebook'
    f.strategy 'GitHub'
    f.path 'github'
    f.key 'test_key'
    f.secret 'test_secret'
  end

  factory :configuration do |f|
    f.name 'Foo'
    f.value 'Bar'
  end

  factory :institutional_video do |f|
    f.title "My title"
    f.description "Some Description"
    f.video_url "http://vimeo.com/35492726"
    f.visible false
  end

  factory :project_post do |f|
    f.association :project, factory: :project
    f.association :user, factory: :user
    f.title "My title"
    f.comment "This is a comment"
    f.comment_html "<p>This is a comment</p>"
  end

  factory :channel do |f|
    f.association :category
    name "Test"
    email "email+channel@foo.bar"
    description "Lorem Ipsum"
    sequence(:permalink) { |n| "#{n}-test-page" }
  end

  factory :state do
    name "RJ"
    acronym "RJ"
  end

  factory :bank do
    name "Foo"
    sequence(:code) { |n| n.to_s.rjust(3, '0') }
  end

  factory :bank_account do |f|
    f.association :user, factory: :user
    f.association :bank, factory: :bank
    owner_name "Foo"
    owner_document "000"
    account_digit "1"
    agency "1"
    account "1"
  end

  factory :channel_post do |f|
    f.association :user, factory: :user
    f.association :channel, factory: :channel
    title "My title"
    f.body "This is a comment"
    f.body_html "<p>This is a comment</p>"
  end

  factory :recurring_contribution do |f|
    before(:create) do |contribution|
      channel = FactoryGirl.create(:channel, recurring: true)

      contribution.project = FactoryGirl.create(:project, channels: [channel])
    end

    f.association :user, factory: :user
    value 100
  end

  factory :project_image do |f|
    f.association :project, factory: :project
    f.caption 'Image caption'
    f.original_image_url 'http://juntos.com.vc/assets/juntos/logo-small.png'
  end

  factory :project_partner do |f|
    f.association :project, factory: :project
    f.link 'http://juntos.com.vc'
    f.original_image_url 'http://juntos.com.vc/assets/juntos/logo-small.png'
  end

  factory :page do |f|
    f.name Page.names.keys.sample
    f.content "Some random content"
  end

  factory :transparency_report do |f|
    f.attachment File.open("#{Rails.root}/spec/support/testimg.png")
    f.previous_attachment File.open("#{Rails.root}/spec/support/testimg.png")
  end
end
