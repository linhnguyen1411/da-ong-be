module Api
  module V1
    module Admin
      class UploadsController < BaseController
        # POST /api/v1/admin/uploads
        # Upload single file and return URL
        def create
          unless params[:file].present?
            render json: { error: 'No file uploaded' }, status: :bad_request
            return
          end

          file = params[:file]
          
          # Validate file type
          allowed_types = %w[image/jpeg image/png image/gif image/webp]
          unless allowed_types.include?(file.content_type)
            render json: { error: 'Invalid file type. Only JPEG, PNG, GIF, WEBP allowed.' }, status: :unprocessable_entity
            return
          end

          # Validate file size (max 5MB)
          if file.size > 5.megabytes
            render json: { error: 'File too large. Maximum size is 5MB.' }, status: :unprocessable_entity
            return
          end

          # Create blob and return URL
          blob = ActiveStorage::Blob.create_and_upload!(
            io: file,
            filename: file.original_filename,
            content_type: file.content_type
          )

          render json: {
            url: rails_blob_url(blob, only_path: true),
            signed_id: blob.signed_id,
            filename: blob.filename.to_s,
            content_type: blob.content_type,
            byte_size: blob.byte_size
          }, status: :created
        end

        # DELETE /api/v1/admin/uploads/:signed_id
        def destroy
          blob = ActiveStorage::Blob.find_signed(params[:id])
          blob.purge
          head :no_content
        rescue ActiveSupport::MessageVerifier::InvalidSignature
          render json: { error: 'Invalid file ID' }, status: :not_found
        end
      end
    end
  end
end
