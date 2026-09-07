require "rails_helper"

RSpec.describe "application time zone" do
  it "uses Mexico City for Time.current, Date.current, and Active Record" do
    expect(Time.zone.tzinfo.name).to eq("America/Mexico_City")
    expect(Time.current.time_zone.tzinfo.name).to eq("America/Mexico_City")
    expect(Time.zone.now.utc_offset).to eq(ActiveSupport::TimeZone["Mexico City"].now.utc_offset)
  end
end
