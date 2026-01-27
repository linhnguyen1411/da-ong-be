module Loyalty
  class Config
    def self.vnd_per_point
      (ENV['LOYALTY_VND_PER_POINT'].presence || '100000').to_i
    end

    def self.points_per_point
      (ENV['LOYALTY_POINTS_PER_POINT'].presence || '1').to_i
    end

    def self.visit_bonus_points
      (ENV['LOYALTY_VISIT_BONUS_POINTS'].presence || '0').to_i
    end
  end
end


