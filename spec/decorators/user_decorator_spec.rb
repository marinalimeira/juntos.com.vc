require 'rails_helper'

RSpec.describe UserDecorator do
  let(:user) { create(:user, access_type: 'individual') }
  before(:all) do
    I18n.locale = :pt
  end

  describe "#contributions_text" do
    context "when the user has one contribution" do
      before { create(:contribution, state: 'confirmed', user: user) }

      it { expect(user.reload.contributions_text).to eq("Apoiou somente este projeto até agora") }
    end

    context "when the user has two contribution" do
      before { create_list(:contribution, 2, state: 'confirmed', user: user) }

      it { expect(user.reload.contributions_text).to eq("Apoiou este e mais 1 outro projeto") }
    end

    context "when the user has three contribution" do
      before { create_list(:contribution, 3, state: 'confirmed', user: user) }

      it { expect(user.reload.contributions_text).to eq("Apoiou este e mais outros 2 projetos") }
    end
  end

  describe "#twitter_link" do
    context "when user has no twitter account" do
      it { expect(user.twitter_link).to be_nil }
    end

    context "when user has twitter account" do
      it "should return the user's twitter link" do
        user.twitter = 'twitter_user'
        expect(user.twitter_link).to eq("http://twitter.com/twitter_user")
      end
    end
  end

  describe "#gravatar_url" do
    context "when user has no email" do
      it "should return nil" do
        user.email = nil

        expect(user.gravatar_url).to be_nil
      end
    end

    context "when user has email" do
      it "should return a gravatar url" do
        user.email = 'email@email.com'

        expect(user.gravatar_url).not_to be_nil
      end
    end
  end

  describe "#display_name" do
    context "when we only have a full name" do
      it "should return the user full name" do
        user.name = nil
        user.full_name = "Full Name"

        expect(user.display_name).to eq("Full Name")
      end
    end

    context "when we have only a name" do
      it "it should return the user name" do
        user.name = "name"

        expect(user.display_name).to eq("name")
      end
    end

    context "when name is empty string" do
      it "should return the full name" do
        user.name = ""
        user.full_name = "foo"

        expect(user.display_name).to eq('foo')
      end
    end

    context "when we have a name and a full name" do
      it "should return the name" do
        user.name = "name"
        user.full_name = "foo"

        expect(user.display_name).to eq('name')
      end
    end

    context "when we have no name" do
      it "should return 'Sem nome'" do
        user.name = nil
        expect(user.display_name).to eq(I18n.t('no_name', scope: 'user'))
      end
    end
  end

  describe "#display_image" do
    context "when we have an uploaded image" do
      before do
        image = double(url: 'image.png')
        allow(image).to receive(:thumb_avatar).and_return(image)
        allow(user).to receive(:uploaded_image).and_return(image)
      end

      it "should return the uploaded image" do
        user.uploaded_image = 'image.png'

        expect(user.display_image).to eq('image.png')
      end
    end

    context "when we have an image url" do
      it "should return the image url" do
        user.image_url = 'image.png'

        expect(user.display_image).to eq('image.png')
      end
    end

    context "when we have an email" do
      it "should return a gravatar url" do
        user.image_url = nil
        user.email = 'diogob@gmail.com'

        expect(user.display_image).to include("https://gravatar.com/avatar/")
      end
    end
  end

  describe "#display_image_html" do
    let(:user) { build(:user, image_url: 'http://image.jpg', uploaded_image: nil )}
    let(:options) { {width: 300, height: 300} }

    it do
      user.display_image_html(options)

      expect(
        user.display_image_html(options)
        ).to include(
          "<div class=",
          "width: #{options[:width]}px; height: #{options[:height]}px",
          "src=\"#{user.display_image}"
        )
    end
  end

  describe "#short_name" do
    context "when name length is bigger than 20" do
      it "should return the first 20 name characters only" do
        user.name = "My Name Is Lorem Ipsum Dolor Sit Amet"

        expect(user.short_name).to eq("My Name Is Lorem ...")
      end
    end

    context "when name length is smaller than 20" do
      it "should return the entire name" do
        user.name = "My Name Is"

        expect(user.short_name).to eq("My Name Is")
      end
    end
  end

  describe "#medium_name" do
    context "when name length is bigger than 42" do
      it "should return the first 42 name characters only" do
        user.name = "My Name Is Lorem Ipsum Dolor Sit Amet And This Is a Bit Name I Think"

        expect(user.medium_name).to eq("My Name Is Lorem Ipsum Dolor Sit Amet A...")
      end
    end

    context "when name length is smaller than 42" do
      it "should return the entire name" do
        user.name = "My Name Is Lorem Ipsum"

        expect(user.medium_name).to eq("My Name Is Lorem Ipsum")
      end
    end
  end

  describe "#display_credits" do
    it { expect(user.display_credits).to eq("R$ 0") }
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

    context "when project's state is online" do
      it "should be equals 1" do
        project.state = 'online'

        expect(user.reload.projects_count).to eq(1)
      end
    end

    context "when project's state is waiting_funds" do
      it "should equals 1" do
        project.state = 'waiting_funds'

        expect(user.reload.projects_count).to eq(1)
      end
    end

    context "when project's state is successful" do
      it "should be equals 1" do
        project.state = 'successful'

        expect(user.reload.projects_count).to eq(1)
      end
    end

    context "when project's state is failed" do
      it "should equals 1" do
        project.state = 'failed'

        expect(user.reload.projects_count).to eq(1)
      end
    end

    context "when project's state is deleted" do
      it "should equals 0" do
        project.state = 'deleted'

        expect(user.reload.projects_count).to eq(1)
      end
    end
  end

  describe "#display_bank_account" do
    context "when user has no bank account" do
      it "should return não preenchido" do
        expect(user.display_bank_account).to eq(I18n.t('not_filled'))
      end
    end

    context "when user has bank account" do
      let(:bank) { create(:bank, code: 100) }
      let!(:bank_account) { create(:bank_account, bank: bank, user: user) }

      it "should return bank account details" do
        expect(
          user.reload.display_bank_account
          ).to include(
            "100 - Foo",
            "AG. 1",
            "CC. 1-1"
          )
      end
    end
  end

  describe "#display_bank_account_owner" do
    context "when user has no bank account" do
      it "should return nil" do
        expect(user.display_bank_account_owner).to be_nil
      end
    end

    context "when user has bank account" do
      let!(:bank_account) { create(:bank_account, user: user) }

      it "should return bank account name and CPF" do
        expect(
          user.reload.display_bank_account_owner
          ).to include(
            "Foo",
            "/ CPF: 000"
          )
      end
    end
  end

  describe "#display_pending_documents" do
    context "when user is legal entity" do
      let(:user) { create(:user, access_type: 'legal_entity') }

      it { expect(user.display_pending_documents).to be_nil }
    end

    context "when user is individual" do
      before { sign_in user }

      context "when user has no ID document" do
        it "should be pending documents" do
          user.original_doc12_url = nil

          expect(user.display_pending_documents).to be_kind_of(String)
        end
      end

      context "when user has no proof of residence" do
        it "should be pending documents" do
          user.original_doc13_url = nil

          expect(user.display_pending_documents).to be_kind_of(String)
        end
      end

      context "when user has ID document" do
        before { user.original_doc12_url = '903.123.209-43' }

        context "but has no proof of residence" do
          it "should be pending documents" do
            user.original_doc13_url = nil

            expect(user.display_pending_documents).to be_kind_of(String)
          end
        end

        context "and has proof of residence" do
          it "should not be pending documents" do
            user.original_doc13_url = 'proof of residence'

            expect(user.display_pending_documents).to be_nil
          end
        end
      end
    end
  end

  describe "#display_project_not_approved" do
    context "when user is individual" do
      it { expect(user.display_project_not_approved).to be_nil }
    end

    context "when user is legal entity" do
      let(:user) { create(:user, access_type: 'legal_entity') }
      before { sign_in user }

      it { expect(user.display_project_not_approved).to be_kind_of(String) }
    end
  end
end
