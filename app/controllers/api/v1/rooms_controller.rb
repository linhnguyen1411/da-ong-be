module Api
  module V1
    class RoomsController < ApplicationController
      def index
        rooms = Room.active.ordered.includes(:room_images, :room_schedules)

        # Build room data with schedule status for the requested date
        room_schedules_map = {}
        room_in_use_map = {}
        current_time = Time.current
        
        if params[:date].present?
          # Parse date in Vietnam timezone to ensure correct comparison
          date_str = params[:date]
          date = begin
            Date.parse(date_str)
          rescue ArgumentError
            # If parsing fails, try to parse as ISO string
            Date.parse(date_str.split('T').first)
          end
          
          time = params[:time].present? ? Time.parse(params[:time]) : nil

          rooms.each do |room|
            # Query ALL active schedules for this room on the requested date (for booked_for_date flag)
            all_schedules = room.room_schedules
              .active
              .for_date(date)
              .order(:start_time)
            
            # If time is provided, filter schedules that overlap with the requested time
            # But still keep all_schedules for booked_for_date flag
            overlapping_schedules = if time.present?
              all_schedules.select do |schedule|
                # schedule.start_time và end_time là Time object, extract time part
                start_hour = schedule.start_time.hour
                start_min = schedule.start_time.min
                end_hour = schedule.end_time.hour
                end_min = schedule.end_time.min
                
                schedule_start = Time.zone.parse("#{date} #{start_hour}:#{start_min}:00")
                schedule_end = Time.zone.parse("#{date} #{end_hour}:#{end_min}:00")
                time_obj = Time.zone.parse("#{date} #{time.strftime('%H:%M')}")
                time_obj >= schedule_start && time_obj < schedule_end
              end
            else
              all_schedules
            end

            # Use all_schedules for booked_for_date flag (any schedule on this date = booked)
            # Use overlapping_schedules for bookings array (only show overlapping ones)
            schedules_to_show = overlapping_schedules
            schedules_for_flag = all_schedules

            # Store schedule info for this room
            if schedules_for_flag.any?
              room_schedules_map[room.id] = schedules_to_show.map do |schedule|
                booking_info = if schedule.booking
                  {
                    id: schedule.booking.id,
                    customer_name: schedule.booking.customer_name,
                    party_size: schedule.booking.party_size
                  }
                else
                  nil
                end
                
                {
                  id: schedule.id,
                  start_time: "#{schedule.start_time.hour.to_s.rjust(2, '0')}:#{schedule.start_time.min.to_s.rjust(2, '0')}",
                  end_time: "#{schedule.end_time.hour.to_s.rjust(2, '0')}:#{schedule.end_time.min.to_s.rjust(2, '0')}",
                  booking: booking_info
                }
              end
              
              # Check if room is currently in use (schedule today and within time range)
              if date == Date.current
                schedules_for_flag.each do |schedule|
                  # schedule.start_time và end_time là Time object, extract time part
                  start_hour = schedule.start_time.hour
                  start_min = schedule.start_time.min
                  end_hour = schedule.end_time.hour
                  end_min = schedule.end_time.min
                  
                  schedule_start = Time.zone.parse("#{date} #{start_hour}:#{start_min}:00")
                  schedule_end = Time.zone.parse("#{date} #{end_hour}:#{end_min}:00")
                  
                  if current_time >= schedule_start && current_time < schedule_end
                    room_in_use_map[room.id] = true
                    break
                  end
                end
              end
            end
          end
        end

        # Return ALL rooms with schedule status
        render json: rooms.map { |room|
          schedules_info = room_schedules_map[room.id] || []
          # Check if room has ANY schedule on this date (not just overlapping ones)
          # This ensures booked_for_date is true if there's any booking on the date
          room_has_schedule = if params[:date].present?
            date = begin
              Date.parse(params[:date])
            rescue ArgumentError
              Date.parse(params[:date].split('T').first)
            end
            room.room_schedules.active.for_date(date).any?
          else
            false
          end
          booked_for_date = room_has_schedule
          in_use = room_in_use_map[room.id] == true
          
          # Build bookings array from schedules (for backward compatibility)
          # Only show overlapping schedules in bookings array
          bookings_info = schedules_info.select { |s| s[:booking] }.map do |schedule|
            {
              id: schedule[:booking][:id],
              customer_name: schedule[:booking][:customer_name],
              booking_time: schedule[:start_time],
              party_size: schedule[:booking][:party_size]
            }
          end
          
          room.as_json(
            only: [:id, :name, :description, :capacity, :has_sound_system, :has_projector, :has_karaoke, :price_per_hour, :status, :position, :room_type],
            methods: [:images_urls, :images_urls_medium, :images_urls_thumb, :thumbnail_url, :thumbnail_url_medium, :thumbnail_url_thumb],
            include: { room_images: { only: [:id, :image_url, :caption] } }
          ).merge(
            booked_for_date: booked_for_date,
            in_use: in_use,
            bookings: bookings_info
          )
        }
      end

      def show
        room = Room.find(params[:id])
        render json: room.as_json(
          only: [:id, :name, :description, :capacity, :has_sound_system, :has_projector, :has_karaoke, :price_per_hour, :status, :position, :room_type],
          methods: [:images_urls, :images_urls_medium, :images_urls_thumb, :thumbnail_url, :thumbnail_url_medium, :thumbnail_url_thumb],
          include: :room_images
        )
      end
    end
  end
end
