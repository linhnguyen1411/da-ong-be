module Api
  module V1
    class RoomsAvailabilityController < ApplicationController
      # GET /api/v1/rooms/available?date=YYYY-MM-DD&time=HH:MM&party_size=10
      def index
        date = Date.parse(params[:date].to_s)
        time = Time.parse(params[:time].to_s)
        party_size = params[:party_size].presence

        rooms = Availability::RoomsForSlot.call(date: date, time: time, party_size: party_size)
        render json: rooms.map { |r| r.as_json(only: [:id, :name, :capacity, :room_type, :price_per_hour]) }
      rescue ArgumentError
        render json: { error: 'Invalid date/time' }, status: :unprocessable_entity
      end
    end
  end
end


