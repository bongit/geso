class ReviewsController < ApplicationController
  def index
    @user = current_user
    @game_assets = Review.where('user_id' == @user.id)
  end

  def new
  end

  def create
    @review = Review.new(review_params)
    @review.reviewer_id = current_user.id
    if @review.save
      redirect_to '/bought_assets/index'
    else
      render notice: '???'
    end
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

    def review_params
      params.require(:review).permit(:game_asset_id, :text, :rating)
    end
end
