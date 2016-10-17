require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user)               { create(:user) }
  let(:unfinished_project) { create(:project, state: 'online') }
  let(:successful_project) { create(:project, state: 'online') }
  let(:failed_project)     { create(:project, state: 'online') }
  let(:facebook_provider)  { create :oauth_provider, name: 'facebook' }

  describe '::STAFFS' do
    it 'defines a constant' do
      expect(described_class.const_defined?(:STAFFS)).to be_truthy
    end
  end

  describe "associations" do
    it { is_expected.to belong_to :channel }
    it { is_expected.to belong_to :country }
    it { is_expected.to have_one  :user_total }
    it { is_expected.to have_one  :bank_account }
    it { is_expected.to have_many :credit_cards }
    it { is_expected.to have_many :contributions }
    it { is_expected.to have_many :authorizations }
    it { is_expected.to have_many :channel_posts }
    it { is_expected.to have_many :channels_subscribers }
    it { is_expected.to have_many :projects }
    it { is_expected.to have_many :unsubscribes }
    it { is_expected.to have_many :project_posts }
    it { is_expected.to have_many :contributed_projects }
    it { is_expected.to have_many :category_followers }
    it { is_expected.to have_many :categories }
    it { is_expected.to have_many :notifications }
    it { is_expected.to have_and_belong_to_many :subscriptions }
  end

  describe "validations" do
    subject { user }

    describe "presence validations" do
      it { is_expected.to validate_presence_of(:email) }
      it { is_expected.to validate_presence_of(:access_type) }
      it { is_expected.to validate_presence_of(:password) }
    end

    describe "length validations" do
      it { is_expected.to ensure_length_of(:bio).is_at_most(140) }
      it { is_expected.to ensure_length_of(:password).is_at_least(6).is_at_most(128) }
    end

    describe "uniqueness validations" do
      it { is_expected.to validate_uniqueness_of(:email) }
    end

    describe "format validations" do
      it { is_expected.to allow_value('foo@bar.com').for(:email) }
      it { is_expected.not_to allow_value('foo').for(:email) }
      it { is_expected.not_to allow_value('foo@bar').for(:email) }
    end
  end

  describe '.staff_array' do
    let(:attributes) do
      [
        User.human_attribute_name('staff/team'),
        User.human_attribute_name('staff/financial_board'),
        User.human_attribute_name('staff/technical_board'),
        User.human_attribute_name('staff/advice_board'),
      ]
    end

    let(:expected_array) do
      attributes.each_with_index.map { |name, index| [name, index] }
    end

    subject { described_class.staff_array }

    it { is_expected.to match expected_array }
  end

  describe ".find_active!" do
    it "should raise error when user is inactive" do
      @inactive_user = create(:user, deactivated_at: Time.now)
      expect(-> { User.find_active!(@inactive_user.id) } ).to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should return user when active" do
      expect(User.find_active!(user.id)).to eq user
    end
  end

  describe ".create" do
    subject do
      User.create! do |u|
        u.email = 'diogob@gmail.com'
        u.password = '123456'
        u.twitter = '@dbiazus'
        u.facebook_link = 'facebook.com/test'
      end
    end
    its(:twitter) { should == 'dbiazus' }
    its(:facebook_link) { should == 'http://facebook.com/test' }
  end

  describe "#change_locale" do
    let(:user) { create(:user, locale: 'pt') }

    context "when user already has a locale" do
      before do
        expect(user).not_to receive(:update_attributes).with(locale: 'pt')
      end

      it { user.change_locale('pt') }
    end

    context "when locale is diff from the user locale" do
      before do
        expect(user).to receive(:update_attributes).with(locale: 'en')
      end

      it { user.change_locale('en') }
    end
  end

  describe "#notify" do
    before do
      user.notify(:heartbleed)
    end

    it "should create notification" do
      notification = UserNotification.last
      expect(notification.user).to eq user
      expect(notification.template_name).to eq 'heartbleed'
    end
  end

  describe "#reactivate" do
    before do
      user.deactivate
      user.reactivate
    end

    it "should set reatiactivate_token to nil" do
      expect(user.reactivate_token).to be_nil
    end

    it "should set deactivated_at to nil" do
      expect(user.deactivated_at).to be_nil
    end
  end

  describe "#deactivate" do
    before do
      @contribution = create(:contribution, user: user, anonymous: false)
      user.deactivate
    end

    it "should send user_deactivate notification" do
      expect(UserNotification.last.template_name).to eq 'user_deactivate'
    end

    it "should set all contributions as anonymous" do
      expect(@contribution.reload.anonymous).to eq(true)
    end

    it "should set reatiactivate_token" do
      expect(user.reactivate_token).to be_present
    end

    it "should set deactivated_at" do
      expect(user.deactivated_at).to be_present
    end
  end

  describe "#total_contributed_projects" do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    subject { user.total_contributed_projects }

    before do
      create(:contribution, state: 'confirmed', user: user, project: project)
      create(:contribution, state: 'confirmed', user: user, project: project)
      create(:contribution, state: 'confirmed', user: user, project: project)
      create(:contribution, state: 'confirmed', user: user)
      user.reload
    end

    it { is_expected.to eq(2) }
  end

  describe "#created_today?" do
    subject { user.created_today? }

    context "when user is created today and not sign in yet" do
      before do
        allow(user).to receive(:created_at).and_return(Date.today)
        allow(user).to receive(:sign_in_count).and_return(0)
      end

      it { is_expected.to eq(true) }
    end

    context "when user is created today and already signed in more that once time" do
      before do
        allow(user).to receive(:created_at).and_return(Date.today)
        allow(user).to receive(:sign_in_count).and_return(2)
      end

      it { is_expected.to eq(false) }
    end

    context "when user is created yesterday and not sign in yet" do
      before do
        allow(user).to receive(:created_at).and_return(Date.yesterday)
        allow(user).to receive(:sign_in_count).and_return(1)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe "#to_analytics_json" do
    subject { user.to_analytics_json }
    it do
      is_expected.to eq({
        id: user.id,
        email: user.email,
        total_contributed_projects: user.total_contributed_projects,
        total_created_projects: user.projects.count,
        created_at: user.created_at,
        last_sign_in_at: user.last_sign_in_at,
        sign_in_count: user.sign_in_count,
        created_today: user.created_today?
      }.to_json)
    end
  end

  describe "#credits" do
    before do
      @u = create(:user)
      create(:contribution, state: 'confirmed', credits: false, value: 100, user_id: @u.id, project: successful_project)
      create(:contribution, state: 'confirmed', credits: false, value: 100, user_id: @u.id, project: unfinished_project)
      create(:contribution, state: 'confirmed', credits: false, value: 200, user_id: @u.id, project: failed_project)
      create(:contribution, state: 'confirmed', credits: true, value: 100, user_id: @u.id, project: successful_project)
      create(:contribution, state: 'confirmed', credits: true, value: 50, user_id: @u.id, project: unfinished_project)
      create(:contribution, state: 'confirmed', credits: true, value: 100, user_id: @u.id, project: failed_project)
      create(:contribution, state: 'requested_refund', credits: false, value: 200, user_id: @u.id, project: failed_project)
      create(:contribution, state: 'refunded', credits: false, value: 200, user_id: @u.id, project: failed_project)
      failed_project.update_attributes state: 'failed'
      successful_project.update_attributes state: 'successful'
    end

    subject { @u.credits }

    xit { is_expected.to eq(50.0) }
  end

  describe "#update_attributes" do
    context "when I try to update moip_login" do
      before do
        user.update_attributes moip_login: 'test'
      end

      it("should perform the update") { expect(user.moip_login).to eq('test') }
    end
  end

  describe "#recommended_project" do
    subject { user.recommended_projects }

    before do
      other_contribution = create(:contribution, state: 'confirmed')
      create(:contribution, state: 'confirmed', user: other_contribution.user, project: unfinished_project)
      create(:contribution, state: 'confirmed', user: user, project: other_contribution.project)
    end

    it { is_expected.to eq([unfinished_project]) }
  end

  describe "#posts_subscription" do
    subject { user.posts_subscription }

    context "when user is subscribed to all projects" do
      it { is_expected.to be_new_record }
    end

    context "when user is unsubscribed from all projects" do
      before { @u = create(:unsubscribe, project_id: nil, user_id: user.id) }

      it { is_expected.to eq(@u) }
    end
  end

  describe "#project_unsubscribes" do
    subject { user.project_unsubscribes }

    before do
      @p1 = create(:project)
      create(:contribution, user: user, project: @p1)
      @u1 = create(:unsubscribe, project_id: @p1.id, user_id: user.id )
    end

    it { is_expected.to eq([@u1]) }
  end

  describe "#contributed_projects" do
    subject { user.contributed_projects }

    before do
      @p1 = create(:project)
      create(:contribution, user: user, project: @p1)
      create(:contribution, user: user, project: @p1)
    end

    it { is_expected.to eq([@p1]) }
  end

  describe "#fix_facebook_link" do
    subject { user.facebook_link }

    context "when user provides invalid url" do
      let(:user) { create(:user, facebook_link: 'facebook.com/foo') }

      it { is_expected.to eq('http://facebook.com/foo') }
    end

    context "when user provides valid url" do
      let(:user) { create(:user, facebook_link: 'http://facebook.com/foo') }

      it { is_expected.to eq('http://facebook.com/foo') }
    end
  end

  describe "#made_any_contribution_for_this_project?" do
    let(:project) { create(:project) }
    subject { user.made_any_contribution_for_this_project?(project.id) }

    context "when user have contributions for the project" do
      before do
        create(:contribution, project: project, state: 'confirmed', user: user)
      end

      it { is_expected.to eq(true) }
    end

    context "when user don't have contributions for the project" do
      it { is_expected.to eq(false) }
    end
  end

  describe "#following_this_category?" do
    let(:category) { create(:category) }
    let(:category_extra) { create(:category) }
    let(:user) { create(:user) }
    subject { user.following_this_category?(category.id) }

    context "when is following the category" do
      before do
        user.categories << category
      end

      it { is_expected.to eq(true) }
    end

    context "when not following the category" do
      before do
        user.categories << category_extra
      end

      it { is_expected.to eq(false) }
    end

    context "when not following any category" do
      it { is_expected.to eq(false) }
    end
  end

  describe '#documents_list' do
    subject { user.documents_list }

    context 'when user is a legal entity' do
      let(:user) { create :user, access_type: 'legal_entity' }
      let(:legal_entity_documents) do
        (1..13).map { |n| "original_doc#{n}_url".to_sym }
      end

      it { is_expected.to match_array legal_entity_documents }
    end

    context 'when user is an individual' do
      let(:user) { create :user, access_type: 'individual' }
      let(:individual_documents) { [:original_doc12_url, :original_doc13_url] }

      it { is_expected.to match_array individual_documents }
    end
  end
end
