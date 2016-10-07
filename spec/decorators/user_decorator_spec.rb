require 'rails_helper'

RSpec.describe UserDecorator do
  let(:user) { create(:user, access_type: 'individual') }
  before(:all) do
    I18n.locale = :pt
  end

  describe "#contributions_text" do
    subject { user.reload.contributions_text }

    context "when the user has one contribution" do
      before { create(:contribution, state: 'confirmed', user: user) }

      it { is_expected.to eq("Apoiou somente este projeto até agora") }
    end

    context "when the user has two contribution" do
      before { create_list(:contribution, 2, state: 'confirmed', user: user) }

      it { is_expected.to eq("Apoiou este e mais 1 outro projeto") }
    end

    context "when the user has three contribution" do
      before { create_list(:contribution, 3, state: 'confirmed', user: user) }

      it { is_expected.to eq("Apoiou este e mais outros 2 projetos") }
    end
  end

  describe "#twitter_link" do
    subject { user.twitter_link }

    context "when user has no twitter account" do
      it { is_expected.to be_nil }
    end

    context "when user has twitter account" do
      it "should return the user's twitter link" do
        user.twitter = 'twitter_user'
        is_expected.to eq("http://twitter.com/twitter_user")
      end
    end
  end

  describe "#gravatar_url" do
    subject { user.gravatar_url }

    context "when user has no email" do
      it "should return nil" do
        user.email = nil

        is_expected.to be_nil
      end
    end

    context "when user has email" do
      it "should return a gravatar url" do
        user.email = 'email@email.com'

        is_expected.not_to be_nil
      end
    end
  end

  describe "#display_name" do
    subject { user.display_name }

    context "when we only have a full name" do
      it "should return the user full name" do
        user.name = nil
        user.full_name = "Full Name"

        is_expected.to eq("Full Name")
      end
    end

    context "when we have only a name" do
      it "should return the user name" do
        user.name = "name"

        is_expected.to eq("name")
      end
    end

    context "when name is empty string" do
      it "should return the full name" do
        user.name = ""
        user.full_name = "foo"

        is_expected.to eq('foo')
      end
    end

    context "when we have a name and a full name" do
      it "should return the name" do
        user.name = "name"
        user.full_name = "foo"

        is_expected.to eq('name')
      end
    end

    context "when we have no name" do
      it "should return 'Sem nome'" do
        user.name = nil

        is_expected.to eq(I18n.t('no_name', scope: 'user'))
      end
    end
  end

  describe "#display_image" do
    subject { user.display_image }

    context "when we have an uploaded image" do
      before do
        image = double(url: 'image.png')
        allow(image).to receive(:thumb_avatar).and_return(image)
        allow(user).to receive(:uploaded_image).and_return(image)
      end

      it "should return the uploaded image" do
        user.uploaded_image = 'image.png'

        is_expected.to eq('image.png')
      end
    end

    context "when we have an image url" do
      it "should return the image url" do
        user.image_url = 'image.png'

        is_expected.to eq('image.png')
      end
    end

    context "when we have an email" do
      it "should return a gravatar url" do
        user.image_url = nil
        user.email = 'diogob@gmail.com'

        is_expected.to include("https://gravatar.com/avatar/")
      end
    end
  end

  describe "#display_image_html" do
    let(:user) { build(:user, image_url: 'http://image.jpg', uploaded_image: nil )}
    let(:options) { {width: 300, height: 300} }
    let(:html_options) { "width: #{options[:width]}px; height: #{options[:height]}px" }
    let(:html_image_src) { "src=\"#{user.display_image}" }

    subject { user.display_image_html(options) }

    it { is_expected.to include(html_options, html_image_src) }
  end

  describe "#short_name" do
    subject { user.short_name }

    context "when name length is bigger than 20" do
      it "should return the first 20 name characters only" do
        user.name = "My Name Is Lorem Ipsum Dolor Sit Amet"

        is_expected.to eq("My Name Is Lorem ...")
      end
    end

    context "when name length is smaller than 20" do
      it "should return the entire name" do
        user.name = "My Name Is"

        is_expected.to eq("My Name Is")
      end
    end
  end

  describe "#medium_name" do
    subject { user.medium_name }

    context "when name length is bigger than 42" do
      it "should return the first 42 name characters only" do
        user.name = "My Name Is Lorem Ipsum Dolor Sit Amet And This Is a Bit Name I Think"

        is_expected.to eq("My Name Is Lorem Ipsum Dolor Sit Amet A...")
      end
    end

    context "when name length is smaller than 42" do
      it "should return the entire name" do
        user.name = "My Name Is Lorem Ipsum"

        is_expected.to eq("My Name Is Lorem Ipsum")
      end
    end
  end

  describe "#display_credits" do
    subject { user.display_credits }

    it { is_expected.to eq("R$ 0") }
  end

  xdescribe "#display_total_of_contributions" do
    subject { user = create(:user) }
    context "with confirmed contributions" do
      before do
        create(:contribution, state: 'confirmed', user: subject, value: 500.0)
      end
      its(:display_total_of_contributions) { should == 'R$ 500'}
    end
  end

  describe "#projects_count" do
    let(:project) { create(:project, user: user) }

    subject { user.reload.projects_count }

    context "when project's state is online" do
      it "should be equals 1" do
        project.state = 'online'

        is_expected.to eq(1)
      end
    end

    context "when project's state is waiting_funds" do
      it "should equals 1" do
        project.state = 'waiting_funds'

        is_expected.to eq(1)
      end
    end

    context "when project's state is successful" do
      it "should be equals 1" do
        project.state = 'successful'

        is_expected.to eq(1)
      end
    end

    context "when project's state is failed" do
      it "should equals 1" do
        project.state = 'failed'

        is_expected.to eq(1)
      end
    end

    context "when project's state is deleted" do
      it "should equals 0" do
        project.state = 'deleted'

        is_expected.to eq(1)
      end
    end
  end

  describe "#display_bank_account" do
    subject { user.reload.display_bank_account }

    context "when user has no bank account" do
      it "should return não preenchido" do
        is_expected.to eq(I18n.t('not_filled'))
      end
    end

    context "when user has bank account" do
      let(:bank) { create(:bank, code: 100) }
      let!(:bank_account) { create(:bank_account, bank: bank, user: user) }
      let(:account_name) { "100 - Foo" }
      let(:account_agency) { "AG. 1" }
      let(:account_number) { "CC. 1-1" }

      subject { user.reload.display_bank_account }

      it { is_expected.to include(account_name, account_agency, account_number) }
    end
  end

  describe "#display_bank_account_owner" do
    subject { user.reload.display_bank_account_owner }

    context "when user has no bank account" do
      it "should return nil" do
        is_expected.to be_nil
      end
    end

    context "when user has bank account" do
      let!(:bank_account) { create(:bank_account, user: user) }
      let(:bank_account_name) { "Foo" }
      let(:bank_account_cpf) { "CPF: 000" }

      it { is_expected.to include(bank_account_name, bank_account_cpf) }
    end
  end

  describe "#display_pending_documents" do
    subject { user.display_pending_documents }

    context "when user is legal entity" do
      let(:user) { create(:user, access_type: 'legal_entity') }

      it { is_expected.to be_nil }
    end

    context "when user is individual" do
      before { sign_in user }

      context "when user has no ID document" do
        it "should be pending documents" do
          user.original_doc12_url = nil

          is_expected.to be_kind_of(String)
        end
      end

      context "when user has no proof of residence" do
        it "should be pending documents" do
          user.original_doc13_url = nil

          is_expected.to be_kind_of(String)
        end
      end

      context "when user has ID document" do
        before { user.original_doc12_url = '903.123.209-43' }

        context "but has no proof of residence" do
          it "should be pending documents" do
            user.original_doc13_url = nil

            is_expected.to be_kind_of(String)
          end
        end

        context "and has proof of residence" do
          it "should not be pending documents" do
            user.original_doc13_url = 'proof of residence'

            is_expected.to be_nil
          end
        end
      end
    end
  end

  describe "#display_project_not_approved" do
    subject { user.display_project_not_approved }

    context "when user is individual" do
      it { is_expected.to be_nil }
    end

    context "when user is legal entity" do
      let(:user) { create(:user, access_type: 'legal_entity') }
      before { sign_in user }

      it { is_expected.to be_kind_of(String) }
    end
  end

  describe "#following_this_category" do
    subject { user.following_this_category?(category.id) }

    context "when there is category for user's project" do
      let(:category_follower) { create(:category_follower, user: user) }
      let(:category) { category_follower.category }

      it { is_expected.to be_truthy }
    end

    context "when there is no category for user's project" do
      let(:new_user) { create(:user) }
      let(:category_follower) { create(:category_follower, user: new_user) }
      let(:category) { category_follower.category }

      it { is_expected.to be_falsey }
    end
  end

  describe "#display_unsuccessful_project_count" do
    subject { user.reload.display_unsuccessful_project_count }

    context "when there is no failed contributed projects" do
      let(:contribution) { create(:contribution, user: user) }

      it { is_expected.to eq(0) }
    end

    context "when there is one failed contributed project" do
      before do
        contribution = create(:contribution, user: user)
        project = contribution.project
        project.state = 'failed'
        project.save!
      end

      it { is_expected.to eq(1) }
    end

    context "when there are many failed contributed projects" do
      before do
        contributions = create_list(:contribution, 8, user: user)
        contributions.each do |contribution|
          project = contribution.project
          project.state = 'failed'
          project.save!
        end
      end

      it { is_expected.to eq(8) }
    end
  end

  describe "#display_last_unsuccessful_project_expires_at" do
    subject { user.reload.display_last_unsuccessful_project_expires_at }

    context "when there is no failed contributed projects" do
      let(:contribution) { create(:contribution, user: user) }

      it { is_expected.to eq('null') }
    end

    context "when there is one failed contributed project" do
      let(:date) { DateTime.civil(2000, 2, 15, 1, 59, 59) }

      before do
        contribution = create(:contribution, user: user)
        project = contribution.project
        project.online_date = date
        project.online_days = 5
        project.state = 'failed'
        project.save!
      end

      it "should return online_date plus online_days" do
        is_expected.to eq((date+5).to_time.to_i)
      end
    end

    context "when there are many failed contributed project" do
      let(:date) { DateTime.civil(2000, 2, 15, 1, 59, 59) }

      before do
        create_list(:contribution, 7, user: user)

        contribution_last = create(:contribution, user: user)
        project = contribution_last.project
        project.online_date = date
        project.online_days = 5
        project.state = 'failed'
        project.save!
      end

      it "should display the last unsuccessful project's expire at" do
        is_expected.to eq((date+5).to_time.to_i)
      end
    end
  end

  describe "#to_analytics_json" do
    subject { user.to_analytics_json }

    it "should expect some user information" do
      user_information = {
        id: user.id,
        email: user.email,
        total_contributed_projects: user.total_contributed_projects,
        total_created_projects: user.projects.count,
        created_at: user.created_at,
        last_sign_in_at: user.last_sign_in_at,
        sign_in_count: user.sign_in_count,
        created_today: user.created_today?
      }.to_json

      is_expected.to eq(user_information)
    end
  end

  describe "#to_param" do
    subject { user.to_param }
    context "when user has name" do
      it "should return the user id and name" do
        is_expected.to eq("#{user.id}-#{user.display_name.parameterize}")
      end
    end

    context "when user has no name" do
      it "should return the user id only" do
        user.name = nil
        is_expected.to eq("#{user.id}")
      end
    end
  end

  describe "#display_user_projects_link" do
    subject { user.display_user_projects_link }

    context "when user has no projects" do
      it { is_expected.to be_nil }
    end

    context "when user has projects" do
      before do
        create_list(:project, 5, user: user)
        sign_in user
      end

      it { is_expected.to include("<a href=", "/users/", "#projects") }

      context "when font is smaller" do
        subject { user.display_user_projects_link('smaller') }

        it { is_expected.to include("fontsize-smaller", "dropdown-link", "w-dropdown-link") }
      end
    end
  end
end
