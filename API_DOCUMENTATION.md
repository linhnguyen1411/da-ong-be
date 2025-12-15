# Đá & Ong - Backend API Documentation

## Base URL
```
http://localhost:3001/api/v1
```

## Authentication

### Login
```
POST /auth/login
```
**Body:**
```json
{
  "email": "admin@daong.vn",
  "password": "admin123"
}
```
**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "admin": {
    "id": 1,
    "email": "admin@daong.vn",
    "name": "Admin",
    "role": "super_admin"
  }
}
```

### Get Current Admin
```
GET /auth/me
Authorization: Bearer <token>
```

---

## Public APIs (Không cần auth)

### Categories
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/categories` | Lấy danh sách categories |
| GET | `/categories/:id` | Chi tiết category |

### Menu Items
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/menu_items` | Lấy danh sách món ăn |
| GET | `/menu_items?category_id=1` | Lọc theo category |
| GET | `/menu_items/:id` | Chi tiết món ăn |

### Best Sellers
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/best_sellers` | Lấy danh sách best seller |
| GET | `/best_sellers/:id` | Chi tiết best seller |

### Daily Specials
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/daily_specials` | Lấy danh sách món ngon mỗi ngày |
| GET | `/daily_specials?today=true` | Lọc theo ngày hôm nay |
| GET | `/daily_specials/:id` | Chi tiết |

### Rooms
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/rooms` | Lấy danh sách phòng available |
| GET | `/rooms/:id` | Chi tiết phòng |

### Contacts
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/contacts` | Gửi form liên hệ |

**Body:**
```json
{
  "name": "Nguyễn Văn A",
  "email": "email@example.com",
  "phone": "0901234567",
  "subject": "Hỏi về dịch vụ",
  "message": "Nội dung tin nhắn..."
}
```

### Bookings
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/bookings` | Đặt bàn |
| GET | `/bookings/check_availability?room_id=1&date=2024-12-15&time=18:00` | Kiểm tra phòng trống |

**Body đặt bàn:**
```json
{
  "room_id": 1,
  "customer_name": "Nguyễn Văn A",
  "customer_phone": "0901234567",
  "customer_email": "email@example.com",
  "party_size": 10,
  "booking_date": "2024-12-15",
  "booking_time": "18:00",
  "duration_hours": 3,
  "notes": "Sinh nhật",
  "booking_items_attributes": [
    { "menu_item_id": 1, "quantity": 2 },
    { "menu_item_id": 3, "quantity": 1 }
  ]
}
```

---

## Admin APIs (Cần auth)

> Headers: `Authorization: Bearer <token>`

### Admin - Categories
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/categories` | Danh sách tất cả categories |
| GET | `/admin/categories/:id` | Chi tiết |
| POST | `/admin/categories` | Tạo mới |
| PATCH | `/admin/categories/:id` | Cập nhật |
| DELETE | `/admin/categories/:id` | Xóa |
| POST | `/admin/categories/reorder` | Sắp xếp lại thứ tự |

**Body tạo/sửa:**
```json
{
  "name": "Tên danh mục",
  "description": "Mô tả",
  "position": 1,
  "active": true
}
```

### Admin - Menu Items
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/menu_items` | Danh sách |
| GET | `/admin/menu_items?category_id=1` | Lọc theo category |
| POST | `/admin/menu_items` | Tạo mới |
| PATCH | `/admin/menu_items/:id` | Cập nhật |
| DELETE | `/admin/menu_items/:id` | Xóa |
| POST | `/admin/menu_items/reorder` | Sắp xếp lại |

**Body:**
```json
{
  "category_id": 1,
  "name": "Tên món",
  "description": "Mô tả",
  "price": 150000,
  "image_url": "https://example.com/image.jpg",
  "active": true
}
```

### Admin - Best Sellers
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/best_sellers` | Danh sách |
| POST | `/admin/best_sellers` | Tạo mới |
| PATCH | `/admin/best_sellers/:id` | Cập nhật |
| DELETE | `/admin/best_sellers/:id` | Xóa |
| PATCH | `/admin/best_sellers/:id/toggle_pin` | Bật/tắt ghim đầu |
| PATCH | `/admin/best_sellers/:id/toggle_highlight` | Bật/tắt highlight |
| POST | `/admin/best_sellers/reorder` | Sắp xếp lại |

**Body:**
```json
{
  "menu_item_id": 1,
  "title": "Tiêu đề bài viết",
  "content": "Nội dung bài viết...",
  "image_url": "https://example.com/image.jpg",
  "pinned": false,
  "highlighted": true,
  "active": true
}
```

### Admin - Daily Specials
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/daily_specials` | Danh sách |
| GET | `/admin/daily_specials?date=2024-12-15` | Lọc theo ngày |
| POST | `/admin/daily_specials` | Tạo mới |
| PATCH | `/admin/daily_specials/:id` | Cập nhật |
| DELETE | `/admin/daily_specials/:id` | Xóa |
| PATCH | `/admin/daily_specials/:id/toggle_pin` | Bật/tắt ghim |
| PATCH | `/admin/daily_specials/:id/toggle_highlight` | Bật/tắt highlight |

**Body:**
```json
{
  "menu_item_id": 1,
  "title": "Món ngon hôm nay",
  "content": "Nội dung...",
  "image_url": "https://example.com/image.jpg",
  "special_date": "2024-12-15",
  "pinned": true,
  "highlighted": false,
  "active": true
}
```

### Admin - Contacts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/contacts` | Danh sách tất cả |
| GET | `/admin/contacts?status=unread` | Lọc chưa đọc |
| GET | `/admin/contacts?status=read` | Lọc đã đọc |
| GET | `/admin/contacts/:id` | Chi tiết |
| DELETE | `/admin/contacts/:id` | Xóa |
| PATCH | `/admin/contacts/:id/mark_read` | Đánh dấu đã đọc |
| PATCH | `/admin/contacts/:id/mark_unread` | Đánh dấu chưa đọc |
| PATCH | `/admin/contacts/mark_all_read` | Đánh dấu tất cả đã đọc |
| GET | `/admin/contacts/stats` | Thống kê |

### Admin - Rooms
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/rooms` | Danh sách tất cả phòng |
| GET | `/admin/rooms/:id` | Chi tiết |
| POST | `/admin/rooms` | Tạo mới |
| PATCH | `/admin/rooms/:id` | Cập nhật |
| DELETE | `/admin/rooms/:id` | Xóa |
| PATCH | `/admin/rooms/:id/update_status` | Cập nhật trạng thái |
| POST | `/admin/rooms/reorder` | Sắp xếp lại |
| GET | `/admin/rooms/stats` | Thống kê |

**Body tạo phòng:**
```json
{
  "name": "Phòng VIP 1",
  "description": "Mô tả phòng",
  "capacity": 20,
  "has_sound_system": true,
  "has_projector": true,
  "has_karaoke": true,
  "price_per_hour": 500000,
  "status": "available",
  "active": true,
  "room_images_attributes": [
    { "image_url": "https://example.com/img1.jpg", "caption": "Ảnh 1" },
    { "image_url": "https://example.com/img2.jpg", "caption": "Ảnh 2" }
  ]
}
```

**Cập nhật trạng thái:**
```json
{
  "status": "occupied" // available, occupied, maintenance
}
```

### Admin - Bookings (Dashboard)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/bookings` | Danh sách tất cả booking |
| GET | `/admin/bookings?status=pending` | Lọc theo trạng thái |
| GET | `/admin/bookings?date=2024-12-15` | Lọc theo ngày |
| GET | `/admin/bookings?start_date=2024-12-01&end_date=2024-12-31` | Lọc theo khoảng thời gian |
| GET | `/admin/bookings?room_id=1` | Lọc theo phòng |
| GET | `/admin/bookings/:id` | Chi tiết |
| PATCH | `/admin/bookings/:id` | Cập nhật |
| DELETE | `/admin/bookings/:id` | Xóa |
| PATCH | `/admin/bookings/:id/confirm` | Xác nhận đặt bàn |
| PATCH | `/admin/bookings/:id/cancel` | Hủy đặt bàn |
| PATCH | `/admin/bookings/:id/complete` | Hoàn thành |
| GET | `/admin/bookings/today` | Booking hôm nay |
| GET | `/admin/bookings/upcoming` | Booking sắp tới |
| GET | `/admin/bookings/stats` | Thống kê |
| GET | `/admin/bookings/dashboard` | Dashboard tổng hợp |

**Response Dashboard:**
```json
{
  "stats": {
    "total_bookings": 100,
    "pending": 5,
    "confirmed": 10,
    "today": 3
  },
  "today_bookings": [...],
  "upcoming_bookings": [...],
  "recent_contacts": [...],
  "room_status": [...]
}
```

---

## Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 204 | No Content (delete success) |
| 401 | Unauthorized |
| 404 | Not Found |
| 422 | Unprocessable Entity (validation errors) |

---

## Default Admin Account
- **Email:** admin@daong.vn
- **Password:** admin123
