class SitemapController < ApplicationController
  def index
    @base_url = 'https://nhahangdavaong.com'
    @lastmod = Date.current
    
    # Get dynamic content
    @menu_items = MenuItem.active.includes(:category).order(:updated_at)
    @rooms = Room.active.order(:updated_at)
    @categories = Category.active.order(:position)
    
    respond_to do |format|
      format.xml { render layout: false }
    end
  end
end

