module Api
  module V1
    class ContactsController < ApplicationController
      def create
        contact = Contact.new(contact_params.except(:attachments))

        if contact.save
          contact.attachments.attach(params[:attachments]) if params[:attachments].present?
          render json: { message: 'Contact submitted successfully', contact: contact }, status: :created
        else
          render json: { errors: contact.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def contact_params
        params.permit(:name, :email, :phone, :subject, :message, attachments: [])
      end
    end
  end
end
