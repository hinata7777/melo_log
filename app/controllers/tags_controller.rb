class TagsController < ApplicationController
  include Pagy::Backend

  def index
    @resident_tags = Tag.active.resident.order(:name)
    @event_tags    = Tag.active.event.order(:name)
  end

  def show
    @tag = Tag.active.find(params[:id])
    
    posts_scope = @tag.posts
                      .includes(:song, :tags, :user)  
                      .order(created_at: :desc)
    
    @pagy, @posts = pagy(posts_scope, items: 5)
    
    @posts_count = @tag.post_tags_count
  end
end
