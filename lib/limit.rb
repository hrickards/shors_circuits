module Rack
  module Throttle
    class HourlyRuns < Hourly
      def allowed?(request)
        # Rate limit requests to run circuits
        return true unless request.path_info.include? "run"
        super request
      end
    end
    class IntervalRuns < Interval
      def allowed?(request)
        # Rate limit requests to run circuits
        return true unless request.path_info.include? "run"
        super request
      end
    end
  end
end
