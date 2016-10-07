require 'rails_helper'

RSpec.describe User::UserScopes, type: :model do
  let(:user) { create(:user, name: 'Foo Bar', email: 'foo@bar.com') }

  describe ".active" do
    subject { User.active }

    context "when there is no deactivated user" do
      it { should eq [user] }
    end

    context "when there are deactivated users" do
      before do
        create_list(:user, 3, deactivated_at: Time.now)
      end

      it { should eq [user] }
    end
  end

  xdescribe ".with_user_totals" do
  end

  describe ".who_contributed_project" do
    let(:project) { create(:project, state: 'online') }
    let(:contribution) { create(:contribution, state: 'confirmed', project: project) }

    subject { User.who_contributed_project(project.id) }

    context "when there are pending projects" do
      before do
        create_list(:contribution, 3, state: 'pending', project: project)
      end

      it { should eq [contribution.user] }
    end

    context "when a single user has contributed on many projects" do
      before do
        create_list(:contribution, 4, state: 'confirmed', project: project, user: contribution.user)
      end

      it { should eq [contribution.user] }
    end
  end

  describe ".subscribed_to_posts" do
    subject { User.subscribed_to_posts }

    context "when a user has no project" do
      it { should eq [user] }
    end

    context "when a user has projects" do
      before { create_list(:project, 4, user: user) }

      it { should eq [user] }
    end
  end

  xdescribe ".subscribed_to_project" do
    let(:project) { create(:project) }
    let(:contribution) { create(:contribution, state: 'confirmed', project: project) }

    subject { User.subscribed_to_project(project) }

    context "when a user has no project" do
      it { should eq [contribution.user] }
    end
  end

  describe ".by_email" do
    subject do
      create(:user, email: 'another_email@bar.com')
      User.by_email 'foo@bar'
    end

    it { should eq [user] }
  end

  describe ".by_payer_email" do
    let(:payment_notification) { create(:payment_notification) }
    let(:payment_notification_second) { create(:payment_notification) }
    let(:payment_notification_third) { create(:payment_notification) }

    before do
      payment_notification.extra_data = { 'payer_email' => 'foo@bar.com' }
      payment_notification.save!

      payment_notification_second.extra_data = { 'payer_email' => 'another_email@bar.com' }
      payment_notification_second.save!

      payment_notification_third.extra_data = { 'payer_email' => 'another_email@bar.com' }
      payment_notification_third.save!
    end

    subject { User.by_payer_email('foo@bar.com') }

    it { should eq [payment_notification.contribution.user] }
  end

  describe ".by_name" do
    subject do
      create(:user, name: 'Baz Qux')
      User.by_name 'Bar'
    end

    it { should eq [user] }
  end

  describe ".by_id" do
    subject do
      create(:user)

      User.by_id user.id
    end

    it { should eq [user] }
  end

  describe ".by_key" do
    let(:contribution) { create(:contribution, user: user) }
    let(:contribution_second) { create(:contribution, user: user) }
    let(:contribution_third) { create(:contribution, user: user) }

    before do
      contribution.key = 'abc'
      contribution.save!

      contribution_second.key = 'abcde'
      contribution_second.save!

      contribution_third.key = 'def'
      contribution_third.save!
    end

    subject { User.by_key 'abc' }

    it { should eq [contribution.user] }
  end

  describe ".has_credits" do
    subject { User.has_credits }

    context "when he has credits in the user_total" do
      before do
        b = create(:contribution, state: 'confirmed', value: 100, project: failed_project)
        failed_project.update_attributes state: 'failed'
        @u = b.user
        b = create(:contribution, state: 'confirmed', value: 100, project: successful_project)
      end
      xit { is_expected.to eq([@u]) }
    end
  end

  describe ".only_organizations" do
    let!(:individual_users) { create_list(:user, 3, access_type: 'individual') }
    let!(:legal_entity_users) { create_list(:user, 3, access_type: 'legal_entity') }

    context "when user is individual" do
      it "should not return individual_users" do
        expect(User.only_organizations).not_to eq(individual_users)
      end
    end

    context "when user is legal entity" do
      it "should return legal_entity" do
        expect(User.only_organizations).to eq(legal_entity_users)
      end
    end
  end

  xdescribe ".already_used_credits" do
  end

  describe ".has_not_used_credits_last_month" do
    subject { User.has_not_used_credits_last_month }

    context "when he has used credits in the last month" do
      before do
        b = create(:contribution, state: 'confirmed', value: 100, credits: true)
        @u = b.user
      end
      xit { is_expected.to eq([]) }
    end
    context "when he has not used credits in the last month" do
      before do
        b = create(:contribution, state: 'confirmed', value: 100, project: failed_project)
        failed_project.update_attributes state: 'failed'
        @u = b.user
      end
      xit { is_expected.to eq([@u]) }
    end
  end

  describe ".to_send_category_notification" do
    let(:category) { create(:category) }
    let(:user_second) { create(:user) }
    let(:user_third) { create(:user) }

    before do
      create(:project, category: category, user: user)
      category.users << user_second
      category.users << user_third
      category.deliver_projects_of_week_notification
      category.users << user
    end

    subject { User.to_send_category_notification(category.id) }

    it { should eq [user] }

  end

  describe ".order_by" do
    let!(:user) { create(:user, name: 'Jose Moura') }
    let!(:user_second) { create(:user, name: 'Maria Josepha') }
    let!(:user_third) { create(:user, name: 'Foo Bar') }
    let!(:user_forth) { create(:user, name: 'Joao Francisco') }

    context "when order by name" do
      it "should return a name ordened list of users" do
        expect(User.order_by(:name)).to eq [user_third, user_forth, user, user_second]
      end
    end

    context "when order by id" do
      it "should return an id ordened list of users" do
        expect(User.order_by(:id)).to eq [user, user_second, user_third, user_forth]
      end
    end
  end

  describe ".with_visible_projects" do
    let(:user_second) { create(:user) }
    let(:user_third) { create(:user) }
    let(:user_forth) { create(:user) }
    let(:user_fifth) { create(:user) }
    let(:user_sixth) { create(:user) }
    let(:user_seventh) { create(:user) }

    let!(:non_visible_projects) {
      [
        create(:project, user: user, state: 'draft'),
        create(:project, user: user_second, state: 'rejected'),
        create(:project, user: user_third, state: 'deleted'),
        create(:project, user: user_forth, state: 'in_analysis')
      ]
    }
    let!(:visible_projects) {
      [
        create(:project, user: user_fifth, state: 'online'),
        create(:project, user: user_sixth, state: 'successful'),
        create(:project, user: user_seventh, state: 'waiting_funds')
      ]
    }

    it "should return only users who has visible projects" do
      expect(User.with_visible_projects).to eq [user_fifth, user_sixth, user_seventh]
    end
  end

  describe '.staff' do
    subject { User.staff }

    context 'when the user is a staff member' do
      let(:staff_member) { create :user, staffs: [1] }

      it { should include staff_member }
    end

    context 'when the user is not a staff member' do
      let(:non_staff_user) { create :user }

      it { should_not include non_staff_user }
    end

  end
end
