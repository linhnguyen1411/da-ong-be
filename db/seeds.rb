# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default admin
Admin.find_or_create_by!(email: 'admin@daong.vn') do |admin|
  admin.name = 'Admin'
  admin.password = 'admin123'
  admin.role = 'super_admin'
end

puts "Created default admin: admin@daong.vn / admin123"

# Create sample categories
categories = [
  { name: 'Khai Vị', description: 'Các món khai vị' },
  { name: 'Món Chính', description: 'Các món chính' },
  { name: 'Lẩu', description: 'Các loại lẩu' },
  { name: 'Hải Sản', description: 'Các món hải sản tươi sống' },
  { name: 'Đồ Uống', description: 'Nước uống, bia, rượu' },
  { name: 'Tráng Miệng', description: 'Món tráng miệng' }
]

categories.each do |cat|
  Category.find_or_create_by!(name: cat[:name]) do |c|
    c.description = cat[:description]
  end
end

puts "Created #{Category.count} categories"

# Create sample menu items
khai_vi = Category.find_by(name: 'Khai Vị')
mon_chinh = Category.find_by(name: 'Món Chính')
lau = Category.find_by(name: 'Lẩu')
hai_san = Category.find_by(name: 'Hải Sản')

if khai_vi
  [
    { name: 'Gỏi Cuốn Tôm Thịt', price: 65000, description: 'Gỏi cuốn tươi với tôm, thịt heo và rau sống' },
    { name: 'Chả Giò Hải Sản', price: 85000, description: 'Chả giò giòn rụm nhân hải sản' },
    { name: 'Salad Trộn Dầu Giấm', price: 55000, description: 'Salad rau củ tươi với sốt dầu giấm' }
  ].each do |item|
    MenuItem.find_or_create_by!(name: item[:name], category: khai_vi) do |m|
      m.price = item[:price]
      m.description = item[:description]
    end
  end
end

if mon_chinh
  [
    { name: 'Bò Lúc Lắc', price: 185000, description: 'Thịt bò Úc xào với tiêu đen và hành tây' },
    { name: 'Cơm Chiên Dương Châu', price: 95000, description: 'Cơm chiên với tôm, trứng và rau củ' },
    { name: 'Sườn Nướng BBQ', price: 165000, description: 'Sườn heo nướng sốt BBQ đặc biệt' }
  ].each do |item|
    MenuItem.find_or_create_by!(name: item[:name], category: mon_chinh) do |m|
      m.price = item[:price]
      m.description = item[:description]
    end
  end
end

if lau
  [
    { name: 'Lẩu Thái Tom Yum', price: 350000, description: 'Lẩu Thái chua cay với hải sản tươi (2-3 người)' },
    { name: 'Lẩu Nấm Chay', price: 280000, description: 'Lẩu nấm tổng hợp cho người ăn chay (2-3 người)' }
  ].each do |item|
    MenuItem.find_or_create_by!(name: item[:name], category: lau) do |m|
      m.price = item[:price]
      m.description = item[:description]
    end
  end
end

if hai_san
  [
    { name: 'Tôm Hùm Nướng Bơ Tỏi', price: 850000, description: 'Tôm hùm tươi nướng bơ tỏi (theo kg)' },
    { name: 'Cua Rang Me', price: 450000, description: 'Cua biển rang với sốt me chua ngọt' }
  ].each do |item|
    MenuItem.find_or_create_by!(name: item[:name], category: hai_san) do |m|
      m.price = item[:price]
      m.description = item[:description]
    end
  end
end

puts "Created #{MenuItem.count} menu items"

# Create sample rooms
rooms = [
  { name: 'Phòng VIP 1', capacity: 20, has_sound_system: true, has_projector: true, has_karaoke: true, price_per_hour: 500000 },
  { name: 'Phòng VIP 2', capacity: 15, has_sound_system: true, has_projector: false, has_karaoke: true, price_per_hour: 400000 },
  { name: 'Phòng Họp A', capacity: 30, has_sound_system: true, has_projector: true, has_karaoke: false, price_per_hour: 600000 },
  { name: 'Phòng Tiệc Lớn', capacity: 50, has_sound_system: true, has_projector: true, has_karaoke: true, price_per_hour: 1000000 },
  { name: 'Bàn Ngoài Trời 1', capacity: 8, has_sound_system: false, has_projector: false, has_karaoke: false, price_per_hour: 0 },
  { name: 'Bàn Ngoài Trời 2', capacity: 6, has_sound_system: false, has_projector: false, has_karaoke: false, price_per_hour: 0 }
]

rooms.each do |room|
  Room.find_or_create_by!(name: room[:name]) do |r|
    r.capacity = room[:capacity]
    r.has_sound_system = room[:has_sound_system]
    r.has_projector = room[:has_projector]
    r.has_karaoke = room[:has_karaoke]
    r.price_per_hour = room[:price_per_hour]
    r.description = "Phòng #{room[:name]} - Sức chứa #{room[:capacity]} người"
  end
end

puts "Created #{Room.count} rooms"
puts "Seed completed!"
