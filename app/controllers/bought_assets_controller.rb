class BoughtAssetsController < ApplicationController
  def index
  	@bought_assets = current_user.bought_assets
  end

  def create
  	@bought_asset = BoughtAsset.new
  	@bought_asset.user_id = current_user.id
  	@bought_asset.game_asset_id = params[:game_asset_id]
  	@bought_asset.save
  end 
end
