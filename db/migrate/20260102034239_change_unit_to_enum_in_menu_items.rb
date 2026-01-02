class ChangeUnitToEnumInMenuItems < ActiveRecord::Migration[7.1]
  def up
    # Thêm cột integer mới cho enum
    add_column :menu_items, :unit_enum, :integer, default: 0, null: false
    
    # Migrate dữ liệu cũ (nếu có)
    execute <<-SQL
      UPDATE menu_items 
      SET unit_enum = CASE unit
        WHEN 'Phần' THEN 0
        WHEN 'Kg' THEN 1
        WHEN 'Lạng' THEN 2
        WHEN 'Nguyên Con' THEN 3
        ELSE 0
      END
      WHERE unit IS NOT NULL;
    SQL
    
    # Xóa cột cũ và đổi tên cột mới
    remove_column :menu_items, :unit
    rename_column :menu_items, :unit_enum, :unit
  end

  def down
    # Thêm lại cột string
    add_column :menu_items, :unit_string, :string
    
    # Migrate dữ liệu ngược lại
    execute <<-SQL
      UPDATE menu_items 
      SET unit_string = CASE unit
        WHEN 0 THEN 'Phần'
        WHEN 1 THEN 'Kg'
        WHEN 2 THEN 'Lạng'
        WHEN 3 THEN 'Nguyên Con'
        ELSE 'Phần'
      END;
    SQL
    
    # Xóa cột enum và đổi tên cột string
    remove_column :menu_items, :unit
    rename_column :menu_items, :unit_string, :unit
  end
end
