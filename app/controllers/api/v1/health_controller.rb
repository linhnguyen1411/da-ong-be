module Api
  module V1
    class HealthController < ApplicationController
      skip_before_action :verify_authenticity_token, if: :verify_authenticity_token

      def index
        checks = {
          status: 'ok',
          timestamp: Time.current.iso8601,
          uptime: get_uptime,
          database: check_database,
          memory: get_memory_usage
        }

        status_code = checks[:database][:status] == 'ok' ? :ok : :service_unavailable
        render json: checks, status: status_code
      end

      private

      def get_uptime
        if File.exist?('/proc/uptime')
          uptime_seconds = File.read('/proc/uptime').split.first.to_f
          {
            seconds: uptime_seconds.to_i,
            formatted: format_uptime(uptime_seconds)
          }
        else
          { seconds: 0, formatted: 'unknown' }
        end
      end

      def format_uptime(seconds)
        days = (seconds / 86400).to_i
        hours = ((seconds % 86400) / 3600).to_i
        minutes = ((seconds % 3600) / 60).to_i
        "#{days}d #{hours}h #{minutes}m"
      end

      def check_database
        start_time = Time.current
        ActiveRecord::Base.connection.execute('SELECT 1')
        query_time = ((Time.current - start_time) * 1000).round(2)
        {
          status: 'ok',
          response_time_ms: query_time
        }
      rescue => e
        {
          status: 'error',
          error: e.message
        }
      end

      def get_memory_usage
        if File.exist?('/proc/meminfo')
          meminfo = File.read('/proc/meminfo')
          total = meminfo.match(/MemTotal:\s+(\d+)\s+kB/)[1].to_i
          available = meminfo.match(/MemAvailable:\s+(\d+)\s+kB/)[1].to_i
          used = total - available
          {
            total_mb: (total / 1024.0).round(2),
            used_mb: (used / 1024.0).round(2),
            available_mb: (available / 1024.0).round(2),
            usage_percent: ((used.to_f / total) * 100).round(2)
          }
        else
          { status: 'unknown' }
        end
      end
    end
  end
end

