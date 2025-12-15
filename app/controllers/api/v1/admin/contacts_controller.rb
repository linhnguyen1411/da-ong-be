module Api
  module V1
    module Admin
      class ContactsController < BaseController
        before_action :set_contact, only: [:show, :destroy, :mark_read, :mark_unread]

        def index
          contacts = Contact.recent

          if params[:status] == 'unread'
            contacts = contacts.unread
          elsif params[:status] == 'read'
            contacts = contacts.read_contacts
          end

          render json: contacts
        end

        def show
          render json: @contact
        end

        def destroy
          @contact.destroy
          head :no_content
        end

        def mark_read
          @contact.mark_as_read!
          render json: @contact
        end

        def mark_unread
          @contact.mark_as_unread!
          render json: @contact
        end

        def mark_all_read
          Contact.unread.update_all(read: true, read_at: Time.current)
          render json: { message: 'All contacts marked as read' }
        end

        def stats
          render json: {
            total: Contact.count,
            unread: Contact.unread.count,
            read: Contact.read_contacts.count,
            today: Contact.where('created_at >= ?', Date.current.beginning_of_day).count
          }
        end

        private

        def set_contact
          @contact = Contact.find(params[:id])
        end
      end
    end
  end
end
