module Api
  module V1
    module Admin
      class MenuItemsController < BaseController
        before_action :set_menu_item, only: [:show, :update, :destroy, :upload_images, :delete_image]

        def index
          # Sort theo product_code (mã hàng) mặc định
          menu_items = MenuItem.includes(:category).with_attached_images
          
          if params[:category_id].present?
            menu_items = menu_items.where(category_id: params[:category_id])
          end

          # Sort theo product_code, nếu không có thì sort theo id
          menu_items = menu_items.order(
            Arel.sql("CASE WHEN product_code IS NULL OR product_code = '' THEN 1 ELSE 0 END"),
            :product_code,
            :id
          )

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
            # Header - đúng thứ tự và tên cột
            sheet.add_row ["Mã hàng", "Tên hàng", "Danh mục", "Đơn vị tính", "Giá bán", "GHI CHÚ"]
            
            # Data - Sort theo category position trước, sau đó theo product_code
            menu_items = MenuItem.includes(:category)
                                 .joins(:category)
                                 .order('categories.position ASC, categories.id ASC')
                                 .order(
                                   Arel.sql("CASE WHEN menu_items.product_code IS NULL OR menu_items.product_code = '' THEN 1 ELSE 0 END"),
                                   'menu_items.product_code',
                                   'menu_items.id'
                                 )
            
            menu_items.each do |item|
              # Format giá dưới dạng text để Excel không tự format
              price_value = if item.is_market_price
                'Thời giá'
              elsif item.price
                # Xuất giá dưới dạng số nguyên (không có dấu chấm thập phân) để tránh Excel format
                item.price.to_i.to_s
              else
                '0'
              end
              
              sheet.add_row [
                item.product_code || '',
                item.name || '',
                item.category&.name || '',
                item.unit.presence || 'Phần', # Default là Phần nếu không có
                price_value,
                '' # Ghi chú để trống
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
            created_count = 0
            deleted_count = 0
            errors = []
            
            # Bước 1: Thu thập tất cả mã sản phẩm từ file import
            imported_product_codes = []
            items_to_process = []
            
            # Skip header row (row 1)
            (2..sheet.last_row).each do |row|
              next if sheet.row(row).all?(&:nil?) # Skip empty rows
              
              product_code = sheet.cell(row, 1).to_s.strip
              name = sheet.cell(row, 2).to_s.strip
              category_name = sheet.cell(row, 3).to_s.strip
              unit = sheet.cell(row, 4).to_s.strip
              price_cell = sheet.cell(row, 5)
              # Lấy giá trị raw từ cell để xử lý đúng
              price_str = price_cell.nil? ? '' : price_cell.to_s.strip
              description = sheet.cell(row, 6).to_s.strip
              
              next if name.blank? # Skip if no name
              
              if product_code.blank?
                errors << "Dòng #{row}: Mã hàng không được để trống"
                next
              end
              
              imported_product_codes << product_code
              items_to_process << {
                row: row,
                product_code: product_code,
                name: name,
                category_name: category_name,
                unit: unit,
                price_cell: price_cell,  # Lưu raw cell value
                price_str: price_str,
                description: description
              }
            end
            
            # Bước 2: Xóa các sản phẩm không có trong file import
            existing_items = MenuItem.where.not(product_code: [nil, ''])
            items_to_delete = existing_items.where.not(product_code: imported_product_codes)
            deleted_count = items_to_delete.count
            items_to_delete.destroy_all
            
            # Bước 3: Xử lý từng dòng trong file import
            items_to_process.each do |item_data|
              row = item_data[:row]
              product_code = item_data[:product_code]
              name = item_data[:name]
              category_name = item_data[:category_name]
              unit = item_data[:unit]
              price_cell = item_data[:price_cell]  # Lấy raw cell value
              price_str = item_data[:price_str]
              description = item_data[:description]
              
              # Tìm hoặc tạo category
              category = nil
              if category_name.present?
                # Tìm category: thử exact match trước, sau đó thử trim và case-insensitive
                category = Category.find_by(name: category_name) || 
                          Category.find_by(name: category_name.strip) ||
                          Category.where("TRIM(name) = ?", category_name.strip).first ||
                          Category.where("LOWER(TRIM(name)) = ?", category_name.strip.downcase).first
                
                if category.nil?
                  errors << "Dòng #{row}: Không tìm thấy danh mục '#{category_name}'. Món ăn sẽ được thêm vào danh mục đầu tiên."
                  category = Category.first
                end
              end
              
              if category.nil?
                category = Category.first
                if category.nil?
                  errors << "Dòng #{row}: Không có danh mục nào trong hệ thống. Vui lòng tạo danh mục trước."
                  next
                end
              end
              
              # Validate unit enum
              valid_units = ['Phần', 'Kg', 'Lạng', 'Nguyên Con']
              unit_value = unit.presence
              if unit_value && !valid_units.include?(unit_value)
                errors << "Dòng #{row}: Đơn vị tính '#{unit_value}' không hợp lệ. Chỉ chấp nhận: #{valid_units.join(', ')}. Sử dụng 'Phần' làm mặc định."
                unit_value = 'Phần'
              end
              unit_value ||= 'Phần'
              
              # Xử lý giá: Excel có thể trả về số hoặc text
              # Kiểm tra giá trị raw từ cell trước
              is_market_price = false
              price = 0
              
              if price_cell.nil? || price_cell.to_s.strip.blank?
                price = 0
              else
                # Luôn convert sang string trước để xử lý thống nhất
                price_str_normalized = price_cell.to_s.strip
                is_market_price = price_str_normalized.downcase.include?('thời giá') || 
                                 price_str_normalized.downcase.include?('thoi gia')
                
                if is_market_price
                  price = 0
                else
                  # Nếu là số từ Excel (Numeric), convert sang string rồi parse
                  if price_cell.is_a?(Numeric)
                    # Excel có thể trả về số với format khác, convert sang string rồi parse lại
                    price_str_from_number = price_cell.to_s
                    # Loại bỏ dấu chấm thập phân nếu có (VD: 150000.0 -> 150000)
                    if price_str_from_number.include?('.')
                      # Kiểm tra xem có phải là số thập phân thật không (VD: 150.5) hay chỉ là format (150000.0)
                      parts = price_str_from_number.split('.')
                      if parts.length == 2 && parts[1].to_i == 0
                        # Chỉ là format, không phải số thập phân
                        price = parts[0].to_i
                      else
                        # Là số thập phân thật, giữ nguyên
                        price = price_cell.to_f
                      end
                    else
                      price = price_cell.to_i
                    end
                  else
                    # Parse từ string: loại bỏ tất cả ký tự không phải số
                    # Xử lý cả trường hợp có dấu phẩy/chấm phân cách hàng nghìn (VD: 150.000, 1.500.000)
                    cleaned_price = price_str_normalized.gsub(/[^\d]/, '')
                    if cleaned_price.blank?
                      price = 0
                    else
                      # Chuyển thành số nguyên để tránh vấn đề float
                      price = cleaned_price.to_i
                    end
                  end
                end
              end
              
              # Tìm menu item theo product_code (bắt buộc phải có mã hàng)
              if product_code.blank?
                errors << "Dòng #{row}: Mã hàng không được để trống. Bỏ qua dòng này."
                next
              end
              
              begin
                # Tìm menu item theo product_code (chỉ tìm theo mã, không tìm theo tên)
                menu_item = MenuItem.find_by(product_code: product_code)
                
                if menu_item
                  # Trường hợp 2: Món ăn đã tồn tại -> ghi đè tất cả thông tin từ file
                  menu_item.update!(
                    product_code: product_code,
                    name: name,
                    category_id: category.id,
                    unit: unit_value,
                    price: price,
                    description: description.presence || '',
                    is_market_price: is_market_price
                  )
                  updated_count += 1
                else
                  # Trường hợp 1: Món ăn chưa tồn tại -> tạo mới
                  max_position = MenuItem.where(category_id: category.id).maximum(:position).to_i + 1
                  MenuItem.create!(
                    product_code: product_code,
                    name: name,
                    category_id: category.id,
                    unit: unit_value,
                    price: price,
                    description: description.presence || '',
                    is_market_price: is_market_price,
                    active: true,
                    position: max_position
                  )
                  created_count += 1
                end
              rescue => e
                errors << "Dòng #{row}: Lỗi khi xử lý món ăn '#{name}' (mã: #{product_code}): #{e.message}"
              end
            end
            
            render json: { 
              message: "Import thành công. Đã tạo mới #{created_count} món, cập nhật #{updated_count} món, xóa #{deleted_count} món.",
              created_count: created_count,
              updated_count: updated_count,
              deleted_count: deleted_count,
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
