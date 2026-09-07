require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#format_datetime" do
    it "formats a UTC instant as Mexico City wall clock" do
      time = Time.utc(2026, 3, 16, 5, 30, 0)

      expect(helper.format_datetime(time)).to eq("15/03/2026 23:30")
    end

    it "returns N/A when the time is missing" do
      expect(helper.format_datetime(nil)).to eq("N/A")
    end
  end
end
