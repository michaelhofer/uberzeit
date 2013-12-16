require 'uber_zeit/bonus_calculators/base_nightly_window'

class UberZeit::BonusCalculators::NineOnDuty
  include UberZeit::BonusCalculators::BaseNightlyWindow

  FACTOR = 0.1
  ACTIVE = { ends: 6, starts: 23 }
end
