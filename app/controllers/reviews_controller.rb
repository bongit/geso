class ReviewsController < ApplicationController

  def create
    @review = Review.new(review_params)
    @review.reviewer_id = current_user.id
    if @review.save
      game_asset = GameAsset.find(@review.game_asset_id)
      game_asset.rating = Review.average_rating(game_asset.id)
      game_asset.save
      redirect_to "/game_assets/#{@review.game_asset_id}", notice: "レビューを投稿しました。"
    else
      flash[:alert] = @review.errors.full_messages
      redirect_to :back
    end
  end

  def update    
    @review = Review.find_by(id: params[:id], reviewer_id: current_user.id)
    if @review.update(review_params)
      game_asset = GameAsset.find(@review.game_asset_id)
      game_asset.rating = Review.average_rating(game_asset.id)
      game_asset.save
      redirect_to "/game_assets/#{@review.game_asset_id}", notice: "レビューを変更しました。"
    else
      flash[:alert] = @review.errors.full_messages
      redirect_to :back
    end
  end

  def destroy
  end

  private

    def review_params
      params.require(:review).permit(:game_asset_id, :text, :rating)
    end

end
