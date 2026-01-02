namespace :menu_items do
  desc "Đánh lại mã hàng cho tất cả sản phẩm"
  task regenerate_product_codes: :environment do
    puts "🔄 Bắt đầu đánh lại mã hàng cho sản phẩm..."
    
    MenuItem.order(:id).find_each.with_index do |item, index|
      # Format: SP + số thứ tự 4 chữ số (VD: SP0001, SP0002, ...)
      new_code = "SP#{format('%04d', index + 1)}"
      
      # Kiểm tra xem mã đã tồn tại chưa
      if MenuItem.exists?(product_code: new_code) && MenuItem.find_by(product_code: new_code).id != item.id
        # Nếu trùng, thử mã khác
        counter = index + 1
        loop do
          new_code = "SP#{format('%04d', counter)}"
          break unless MenuItem.exists?(product_code: new_code)
          counter += 1
        end
      end
      
      old_code = item.product_code
      item.update_column(:product_code, new_code)
      
      puts "  ✓ #{item.name}: #{old_code || '(chưa có)'} → #{new_code}"
    end
    
    puts "✅ Hoàn thành! Đã đánh lại mã hàng cho #{MenuItem.count} sản phẩm."
  end

  desc "Set default unit là Phần cho các sản phẩm chưa có unit"
  task set_default_unit: :environment do
    puts "🔄 Đang set unit mặc định là 'Phần' cho các sản phẩm chưa có unit..."
    
    updated_count = MenuItem.where(unit: nil).or(MenuItem.where(unit: 0)).update_all(unit: 0)
    
    puts "✅ Đã cập nhật #{updated_count} sản phẩm."
  end
end

