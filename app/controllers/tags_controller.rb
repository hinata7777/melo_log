class TagsController < ApplicationController
  include Pagy::Backend

  def index
    @tags = Tag.active.order(:name)
  end

  def show
    @tag = Tag.active.find(params[:id])
    
    posts_scope = @tag.posts
                      .includes(:song, :tags, :user)  
                      .order(created_at: :desc)
    
    @pagy, @posts = pagy(posts_scope, items: 12)
    
    @posts_count = @tag.post_tags_count
  end
end
