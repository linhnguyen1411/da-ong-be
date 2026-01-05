namespace :rooms do
  desc "Generate thumbnails and medium variants for all room images"
  task generate_thumbnails: :environment do
    puts "🔄 Bắt đầu generate thumbnails cho room images..."
    
    total_rooms = Room.count
    processed_rooms = 0
    processed_variants = 0
    errors = []
    
    Room.find_each do |room|
      begin
        room.images.attached?.each do |image|
          begin
            # Generate thumb variant (400x300, JPEG format for smaller size)
            thumb_variant = image.variant({ resize_to_limit: [400, 300], format: :jpeg })
            thumb_variant.processed
            processed_variants += 1
            print "."
            
            # Generate medium variant (800x600, JPEG format for smaller size)
            medium_variant = image.variant({ resize_to_limit: [800, 600], format: :jpeg })
            medium_variant.processed
            processed_variants += 1
            print "."
          rescue => e
            errors << "Room #{room.id}, Image #{image.id}: #{e.message}"
            puts "\n⚠️  Lỗi khi xử lý ảnh #{image.id} của room #{room.id}: #{e.message}"
          end
        end
        
        processed_rooms += 1
        if processed_rooms % 10 == 0
          puts "\n✅ Đã xử lý #{processed_rooms}/#{total_rooms} phòng (#{processed_variants} variants)..."
        end
      rescue => e
        errors << "Room #{room.id}: #{e.message}"
        puts "\n❌ Lỗi khi xử lý room #{room.id}: #{e.message}"
      end
    end
    
    puts "\n✅ Hoàn thành! Đã xử lý #{processed_rooms} phòng, #{processed_variants} variants."
    if errors.any?
      puts "\n⚠️  Có #{errors.length} lỗi:"
      errors.first(10).each { |error| puts "  - #{error}" }
      puts "  ..." if errors.length > 10
    end
  end
end
