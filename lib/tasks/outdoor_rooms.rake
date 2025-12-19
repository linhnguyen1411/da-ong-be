namespace :rooms do
  desc "Create 25 outdoor rooms"
  task seed_outdoor: :environment do
    puts "Creating 25 outdoor rooms..."
    
    # Get current max position
    max_position = Room.maximum(:position) || 0
    
    25.times do |i|
      room_number = i + 1
      room_name = "Bàn Ngoài Trời #{room_number}"
      
      # Skip if already exists
      if Room.exists?(name: room_name)
        puts "  - #{room_name} already exists, skipping..."
        next
      end
      
      # Random capacity between 4-10
      capacity = [4, 6, 8, 10].sample
      
      Room.create!(
        name: room_name,
        description: "Bàn ngoài trời #{room_number} - Sức chứa #{capacity} người, không gian thoáng mát",
        capacity: capacity,
        has_sound_system: false,
        has_projector: false,
        has_karaoke: false,
        price_per_hour: 0,
        status: 'available',
        room_type: 'outdoor',
        position: max_position + room_number,
        active: true
      )
      
      puts "  + Created: #{room_name} (capacity: #{capacity})"
    end
    
    puts "\n✅ Done! Total outdoor rooms: #{Room.where(room_type: 'outdoor').count}"
    puts "Total rooms: #{Room.count}"
  end
end

