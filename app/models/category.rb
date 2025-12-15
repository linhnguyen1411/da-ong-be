class Category < ApplicationRecord
  has_many :menu_items, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  before_validation :set_defaults, on: :create
  before_save :handle_position_change, if: :will_save_change_to_position?
  after_destroy :reorder_all_positions

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc) }

  private

  def set_defaults
    self.active = true if active.nil?
    self.position ||= Category.maximum(:position).to_i + 1
  end

  def handle_position_change
    return if new_record?
    
    old_pos = position_was
    new_pos = position
    
    # Clamp new position to valid range
    max_pos = Category.count
    new_pos = [[new_pos, 1].max, max_pos].min
    self.position = new_pos
    
    if old_pos && new_pos && old_pos != new_pos
      if new_pos < old_pos
        # Moving up: shift items in between down
        Category.where("position >= ? AND position < ? AND id != ?", new_pos, old_pos, id)
                .update_all("position = position + 1")
      else
        # Moving down: shift items in between up
        Category.where("position > ? AND position <= ? AND id != ?", old_pos, new_pos, id)
                .update_all("position = position - 1")
      end
    end
  end

  def reorder_all_positions
    # After delete, reindex all remaining categories
    Category.order(:position, :id).each_with_index do |cat, index|
      new_position = index + 1
      cat.update_column(:position, new_position) if cat.position != new_position
    end
  end
end
