require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:organization).optional }

    it "allows nil organization for super_admin" do
      user = build(:user, :super_admin)
      expect(user).to be_valid
    end
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to have_secure_password }

    describe "email format" do
      it "rejects invalid email" do
        user = build(:user, email: "invalid")
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end

      it "accepts valid email" do
        user = build(:user, email: "user@example.com")
        expect(user).to be_valid
      end
    end

    describe "email uniqueness per organization" do
      let(:organization) { create(:organization) }

      it "rejects duplicate email in same organization" do
        create(:user, organization: organization, email: "dup@example.com")
        user = build(:user, organization: organization, email: "dup@example.com")
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end

      it "allows same email in different organizations" do
        org_a = create(:organization)
        org_b = create(:organization)
        create(:user, organization: org_a, email: "same@example.com")
        user = build(:user, organization: org_b, email: "same@example.com")
        expect(user).to be_valid
      end

      it "is case-insensitive" do
        create(:user, organization: organization, email: "user@example.com")
        user = build(:user, organization: organization, email: "USER@EXAMPLE.COM")
        expect(user).not_to be_valid
      end
    end

    describe "password length" do
      it "rejects password shorter than 8 characters" do
        user = build(:user, password: "short")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it "accepts password with 8+ characters" do
        user = build(:user, password: "longpassword")
        expect(user).to be_valid
      end
    end
  end

  describe "email normalization" do
    it "downcases email before validation" do
      user = create(:user, email: "USER@EXAMPLE.COM")
      expect(user.reload.email).to eq("user@example.com")
    end

    it "strips whitespace from email" do
      user = create(:user, email: "  user@example.com  ")
      expect(user.reload.email).to eq("user@example.com")
    end
  end

  describe "role enum" do
    it { is_expected.to define_enum_for(:role).with_values(participant: 0, admin: 1, super_admin: 2) }

    it "defaults to participant" do
      user = create(:user)
      expect(user.role).to eq("participant")
    end
  end

  describe "soft delete" do
    it "is kept by default" do
      user = create(:user)
      expect(User.kept).to include(user)
    end

    it "is excluded from kept scope after discard" do
      user = create(:user)
      user.discard
      expect(User.kept).not_to include(user)
    end
  end
end
