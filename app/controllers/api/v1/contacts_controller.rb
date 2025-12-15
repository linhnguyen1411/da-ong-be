module Api
  module V1
    class ContactsController < ApplicationController
      def create
        contact = Contact.new(contact_params)

        if contact.save
          render json: { message: 'Contact submitted successfully', contact: contact }, status: :created
        else
          render json: { errors: contact.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def contact_params
        params.permit(:name, :email, :phone, :subject, :message)
      end
    end
  end
end
