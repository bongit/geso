# coding: utf-8
class GameAssetsController < ApplicationController
  before_action :set_game_asset, only: [:show, :edit, :update, :destroy, :download]
  before_action :singed_in_asset

  # GET /game_assets
  # GET /game_assets.json
  def index
    @game_assets = GameAsset.all
  end

  # GET /game_assets/1
  # GET /game_assets/1.json
  def show
  end

  # GET /game_assets/new
  def new
    @game_asset = GameAsset.new
  end

  # GET /game_assets/1/edit
  def edit
  end

  # POST /game_assets
  # POST /game_assets.json
  def create
    @game_asset = GameAsset.new(game_asset_params)
    s3 = AWS::S3.new
    bucket = s3.buckets[Rails.application.secrets.bucket_name]
     
    file = game_asset_params[:file]
    file_name = file.original_filename
    file_full_path="assets/"+file_name

    object = bucket.objects[file_full_path]
    object.write(file ,:acl => :public_read)
    @game_asset.name= Rails.application.secrets.aws_s3_path + "#{file_name}"
    @game_asset.user_id = current_user.id

    respond_to do |format|
      if @game_asset.save
        format.html { redirect_to @game_asset, notice: 'Game asset was successfully created.' }
        format.json { render :show, status: :created, location: @game_asset }
      else
        format.html { render :new }
        format.json { render json: @game_asset.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /game_assets/1
  # PATCH/PUT /game_assets/1.json
  def update
    respond_to do |format|
      if @game_asset.update(game_asset_params)
        format.html { redirect_to @game_asset, notice: 'Game asset was successfully updated.' }
        format.json { render :show, status: :ok, location: @game_asset }
      else
        format.html { render :edit }
        format.json { render json: @game_asset.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /game_assets/1
  # DELETE /game_assets/1.json
  def destroy
    @game_asset.destroy
    respond_to do |format|
      format.html { redirect_to game_assets_url, notice: 'Game asset was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def download
    obj_url = @game_asset.name.slice(40..-1)
    send_data(AWS::S3.new.buckets[Rails.application.secrets.bucket_name].objects[obj_url].read, {
      filename: obj_url.slice(7..-1),
      content_disposition: 'attachement'
      })
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game_asset
      @game_asset = GameAsset.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_asset_params
      params.require(:game_asset).permit(:file)
    end

    def singed_in_asset
      store_location
      redirect_to signin_url, notice: "ログインして下さい。" unless signed_in?
    end
      AWS.config(
    access_key_id:      Rails.application.secrets.aws_s3_access_key, 
    secret_access_key:  Rails.application.secrets.aws_s3_secret_key, 
    region:             'us-west-2',
    :s3_server_side_encryption => :aes256
    )
end
