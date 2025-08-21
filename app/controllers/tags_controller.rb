class TagsController < ApplicationController
  include Pagy::Backend

  def index
    @tags = Tag.active.order(:name)
               .left_outer_joins(:post_tags)
               .select('tags.*, COUNT(post_tags.id) AS posts_count')
               .group('tags.id')
  end

  def show
    @tag = Tag.active.find(params[:id])
    posts_scope = @tag.posts.includes(:song, :user).order(created_at: :desc)
    @pagy, @posts = pagy(posts_scope, items: 12)
  end
end
