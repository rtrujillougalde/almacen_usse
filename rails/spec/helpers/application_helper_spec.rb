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

    it "takes the named formats from the locale file" do
      time = Time.utc(2026, 3, 16, 5, 30, 0)

      expect(helper.format_datetime(time, format: :date_only)).to eq("15/03/2026")
      expect(helper.format_datetime(time, format: :time_only)).to eq("23:30")
    end
  end

  describe "currency formatting" do
    it "reads the unit and precision from the locale file" do
      expect(helper.number_to_currency(1250.5)).to eq("$1,250.50")
    end
  end
end
