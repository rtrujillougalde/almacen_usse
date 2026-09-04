require "rails_helper"

RSpec.describe "RSpec setup" do
  it "loads the Rails environment" do
    expect(Rails.env).to eq("test")
  end

  it "builds a user factory" do
    user = build(:user, :admin)
    expect(user).to be_valid
  end
end
