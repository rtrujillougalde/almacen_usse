# frozen_string_literal: true

namespace :shared_production do
  desc "Prepare a shared live MySQL without recreating inventory tables"
  task prepare: :environment do
    result = SharedProduction::Prepare.call
    if result.skipped?
      puts result.reason
    else
      puts "Shared production prepare complete."
    end
  end
end
