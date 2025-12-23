module Api
  module V1
    module Admin
      class MenuItemsController < BaseController
        before_action :set_menu_item, only: [:show, :update, :destroy, :upload_images, :delete_image]

        def index
          menu_items = MenuItem.ordered.includes(:category).with_attached_images
          
          if params[:category_id].present?
            menu_items = menu_items.where(category_id: params[:category_id])
          end

          render json: menu_items.map { |item| menu_item_json(item) }
        end

        def show
          render json: menu_item_json(@menu_item)
        end

        def create
          menu_item = MenuItem.new(menu_item_params)

          # Attach images if provided (support multiple)
          if params[:images].present?
            Array(params[:images]).each do |image|
              menu_item.images.attach(image)
            end
          end

          if menu_item.save
            render json: menu_item_json(menu_item), status: :created
          else
            render json: { errors: menu_item.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          # Attach new images if provided (append to existing)
          if params[:images].present?
            Array(params[:images]).each do |image|
              @menu_item.images.attach(image)
            end
          end

          if @menu_item.update(menu_item_params)
            render json: menu_item_json(@menu_item)
          else
            render json: { errors: @menu_item.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @menu_item.images.purge if @menu_item.images.attached?
          @menu_item.destroy
          head :no_content
        end

        # POST /api/v1/admin/menu_items/:id/upload_images
        def upload_images
          unless params[:images].present?
            render json: { error: 'No images uploaded' }, status: :bad_request
            return
          end

          Array(params[:images]).each do |image|
            @menu_item.images.attach(image)
          end
          
          if @menu_item.images.attached?
            render json: { 
              images_urls: @menu_item.images.map { |img| rails_blob_url(img, only_path: true) },
              message: 'Images uploaded successfully' 
            }
          else
            render json: { error: 'Failed to upload images' }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/menu_items/:id/delete_image/:image_id
        def delete_image
          attachment = @menu_item.images.attachments.find_by(id: params[:image_id])
          if attachment
            attachment.purge
            render json: { 
              images: @menu_item.images.attachments.reload.map { |att| { id: att.id, url: rails_blob_url(att.blob, only_path: true) } },
              message: 'Image deleted successfully' 
            }
          else
            render json: { error: 'Image not found' }, status: :not_found
          end
        end

        def reorder
          params[:positions].each do |item|
            MenuItem.find(item[:id]).update(position: item[:position])
          end
          render json: { message: 'Menu items reordered successfully' }
        end

        # GET /api/v1/admin/menu_items/export
        def export
          require 'caxlsx'
          
          package = Axlsx::Package.new
          workbook = package.workbook
          workbook.add_worksheet(name: "Món ăn") do |sheet|
            # Header
            sheet.add_row ["Mã Hàng", "Tên món ăn", "Đơn vị tính", "Giá", "Ghi chú"]
            
            # Data
            MenuItem.includes(:category).ordered.each do |item|
              sheet.add_row [
                item.product_code || '',
                item.name || '',
                item.unit || '',
                item.is_market_price ? 'Thời giá' : (item.price || 0),
                item.description || ''
              ]
            end
          end
          
          send_data package.to_stream.read, 
                    filename: "mon_an_#{Date.current.strftime('%Y%m%d')}.xlsx",
                    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        end

        # POST /api/v1/admin/menu_items/import
        def import
          unless params[:file].present?
            render json: { error: 'No file uploaded' }, status: :bad_request
            return
          end

          require 'roo'
          
          begin
            file = params[:file]
            spreadsheet = Roo::Spreadsheet.open(file.path, extension: :xlsx)
            sheet = spreadsheet.sheet(0)
            
            updated_count = 0
            errors = []
            
            # Skip header row (row 1)
            (2..sheet.last_row).each do |row|
              next if sheet.row(row).all?(&:nil?) # Skip empty rows
              
              product_code = sheet.cell(row, 1).to_s.strip
              name = sheet.cell(row, 2).to_s.strip
              unit = sheet.cell(row, 3).to_s.strip
              price_str = sheet.cell(row, 4).to_s.strip
              description = sheet.cell(row, 5).to_s.strip
              
              next if name.blank? # Skip if no name
              
              # Find menu item by product_code or name
              menu_item = if product_code.present?
                MenuItem.find_by(product_code: product_code) || MenuItem.find_by(name: name)
              else
                MenuItem.find_by(name: name)
              end
              
              if menu_item
                # Update existing item
                is_market_price = price_str.downcase.include?('thời giá') || price_str.downcase.include?('thoi gia')
                price = is_market_price ? 0 : (price_str.gsub(/[^\d]/, '').to_f)
                
                menu_item.update(
                  product_code: product_code.presence || menu_item.product_code,
                  name: name,
                  unit: unit.presence || menu_item.unit,
                  price: price,
                  description: description.presence || menu_item.description,
                  is_market_price: is_market_price
                )
                updated_count += 1
              else
                errors << "Dòng #{row}: Không tìm thấy món ăn với mã '#{product_code}' hoặc tên '#{name}'"
              end
            end
            
            render json: { 
              message: "Import thành công. Đã cập nhật #{updated_count} món ăn.",
              updated_count: updated_count,
              errors: errors
            }
          rescue => e
            render json: { error: "Lỗi import: #{e.message}" }, status: :unprocessable_entity
          end
        end

        private

        def set_menu_item
          @menu_item = MenuItem.find(params[:id])
        end

        def menu_item_params
          params.permit(:category_id, :name, :description, :price, :image_url, :active, :position, :is_market_price, :product_code, :unit)
        end

        def menu_item_json(item)
          json = item.as_json(include: { category: { only: [:id, :name] } })
          
          # Trả về mảng tất cả ảnh
          json['images_urls'] = item.images.attached? ? 
            item.images.map { |img| rails_blob_url(img, only_path: true) } : []
          
          # Thumbnail (ảnh đầu tiên)
          json['thumbnail_url'] = item.images.attached? ? 
            rails_blob_url(item.images.first, only_path: true) : item.image_url
          
          # Thêm image IDs để cho phép xóa từng ảnh (dùng attachment id)
          json['images'] = item.images.attached? ?
            item.images.attachments.map { |att| { id: att.id, url: rails_blob_url(att.blob, only_path: true) } } : []
          
          json
        end
      end
    end
  end
end
