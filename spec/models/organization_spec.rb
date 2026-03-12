require "rails_helper"

RSpec.describe Organization, type: :model do
  describe "validations" do
    subject { build(:organization) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }

    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }
    it { is_expected.to validate_length_of(:slug).is_at_most(63) }

    it { is_expected.to validate_presence_of(:owner_email) }
    it { is_expected.to validate_presence_of(:status) }

    describe "slug format" do
      it "accepts valid slugs" do
        subject.slug = "my-org-123"
        expect(subject).to be_valid
      end

      it "normalizes uppercase slugs by downcasing" do
        subject.slug = "My-Org"
        subject.validate
        expect(subject.slug).to eq("my-org")
        expect(subject.errors[:slug]).to be_empty
      end

      it "rejects slugs with spaces" do
        subject.slug = "my org"
        subject.validate
        expect(subject.errors[:slug]).to include("only lowercase letters, numbers, and hyphens")
      end

      it "rejects slugs with special characters" do
        subject.slug = "my_org!"
        subject.validate
        expect(subject.errors[:slug]).to include("only lowercase letters, numbers, and hyphens")
      end
    end

    describe "owner_email format" do
      it "accepts a valid email" do
        subject.owner_email = "owner@example.com"
        expect(subject).to be_valid
      end

      it "rejects an invalid email" do
        subject.owner_email = "not-an-email"
        subject.validate
        expect(subject.errors[:owner_email]).to be_present
      end
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, active: 1, suspended: 2) }

    it "defaults to pending" do
      org = Organization.new
      expect(org.status).to eq("pending")
    end

    it "provides scopes for each status" do
      active    = create(:organization, status: :active)
      pending   = create(:organization, :pending)
      suspended = create(:organization, :suspended)

      expect(Organization.active).to include(active)
      expect(Organization.active).not_to include(pending, suspended)

      expect(Organization.pending).to include(pending)
      expect(Organization.suspended).to include(suspended)
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:users).dependent(:destroy) }
    it { is_expected.to have_many(:raffles).dependent(:destroy) }
  end

  describe "#normalize_slug" do
    it "downcases the slug before validation" do
      org = build(:organization, slug: "My-Org")
      org.valid?
      expect(org.slug).to eq("my-org")
    end

    it "strips whitespace from the slug before validation" do
      org = build(:organization, slug: "  my-org  ")
      org.valid?
      expect(org.slug).to eq("my-org")
    end

    it "handles nil slug gracefully" do
      org = build(:organization, slug: nil)
      expect { org.valid? }.not_to raise_error
    end
  end

  describe "database constraints" do
    it "enforces slug uniqueness at the database level" do
      create(:organization, slug: "unique-slug")
      duplicate = build(:organization, slug: "unique-slug")
      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
