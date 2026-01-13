namespace :menu_items do
  desc "Regenerate product codes for all menu items"
  task regenerate_product_codes: :environment do
    puts "🔄 Bắt đầu đánh lại mã hàng cho sản phẩm..."
    MenuItem.order(:id).each_with_index do |item, index|
      old_code = item.product_code
      new_code = "SP%04d" % (index + 1)
      if old_code != new_code
        item.update_column(:product_code, new_code)
        puts "  ✓ #{item.name}: #{old_code.presence || '(chưa có)'} → #{new_code}"
      else
        puts "  ✓ #{item.name}: #{old_code} → #{new_code}"
      end
    end
    puts "✅ Hoàn thành! Đã đánh lại mã hàng cho #{MenuItem.count} sản phẩm."
  end

  desc "Set default unit 'Phần' for menu items that have no unit"
  task set_default_unit: :environment do
    puts "🔄 Đang set unit mặc định là 'Phần' cho các sản phẩm chưa có unit..."
    updated_count = 0
    MenuItem.where(unit: nil).find_each do |item|
      item.update_column(:unit, MenuItem.units['Phần'])
      updated_count += 1
    end
    puts "✅ Đã cập nhật #{updated_count} sản phẩm."
  end

  desc "Generate thumbnails and medium variants for all menu item images"
  task generate_thumbnails: :environment do
    puts "🔄 Bắt đầu generate thumbnails cho menu item images..."

    total_items = MenuItem.where.not(id: MenuItem.left_joins(:images_attachments).where(active_storage_attachments: { id: nil }).select(:id)).count
    processed_items = 0
    processed_variants = 0
    errors = []

    MenuItem.find_each do |item|
      begin
        item.images.each do |image|
          begin
            # Generate thumb variant (400x300, JPEG format for smaller size)
            thumb_variant = image.variant({ resize_to_limit: [400, 300], format: :jpeg, saver: { quality: 85 } })
            thumb_variant.processed
            processed_variants += 1
            print "."

            # Generate medium variant (800x600, JPEG format for smaller size)
            medium_variant = image.variant({ resize_to_limit: [800, 600], format: :jpeg, saver: { quality: 85 } })
            medium_variant.processed
            processed_variants += 1
            print "."
          rescue => e
            errors << "MenuItem #{item.id}, Image #{image.id}: #{e.message}"
            puts "\n⚠️  Lỗi khi xử lý ảnh #{image.id} của menu item #{item.id}: #{e.message}"
          end
        end

        processed_items += 1
        if processed_items % 10 == 0
          puts "\n✅ Đã xử lý #{processed_items}/#{total_items} món ăn..."
        end
      rescue => e
        errors << "MenuItem #{item.id}: #{e.message}"
        puts "\n❌ Lỗi khi xử lý menu item #{item.id}: #{e.message}"
      end
    end

    puts "\n✅ Hoàn thành! Đã xử lý #{processed_items} món ăn, #{processed_variants} variants."
    if errors.any?
      puts "\n⚠️  Có #{errors.length} lỗi:"
      errors.first(10).each { |error| puts "  - #{error}" }
      puts "  ..." if errors.length > 10
    end
  end
end
