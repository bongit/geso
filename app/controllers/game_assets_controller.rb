# coding: utf-8
class GameAssetsController < ApplicationController
  before_action :set_game_asset, only: [:show, :edit, :update, :destroy, :download]
  before_action :singed_in_asset

  # GET /game_assets
  # GET /game_assets.json
  def index
    # 設定
    if params[:order] == nil || params[:order] == ""
      params[:order] = "created_at desc"
    end

    @game_assets = GameAsset.search(params[:search], params[:main_category], params[:sub_category]).order("#{params[:order]}").paginate(page: params[:page], :per_page => 25)

    if  params[:main_category] != ""
      @main_category = params[:main_category]
      @sub_categories = SubCategory.sub_for(params[:main_category])
      @sub_category = params[:sub_category]
    end
  end

  # GET /game_assets/1
  # GET /game_assets/1.json
  def show
    @author = User.find(@game_asset[:user_id])
  end

  # GET /game_assets/new
  def new
    @game_asset = GameAsset.new
  end


  # GET /game_assets/1/edit
  def edit
  end

  def edit2
    @game_asset = GameAsset.find(params[:id])
  end

  def edit3
    @game_asset = GameAsset.find(params[:id])
  end

  # POST /game_assets
  # POST /game_assets.json
  def create
    @game_asset = GameAsset.new(game_asset_params)
    @game_asset.user_id = current_user.id

      respond_to do |format|
        if @game_asset.save
          format.html { redirect_to "/game_assets/#{@game_asset.id}/edit2", notice: '素材の仮登録が完了しました。引き続き情報を入力して下さい。' }
          format.json { render :show, status: :created, location: @game_asset }
        else
          format.html { render :edit2, notice: '値が正しくありません。'}
          format.json { render json: @game_asset.errors, status: :unprocessable_entity }
        end
      end
  end

  # PATCH/PUT /game_assets/1
  # PATCH/PUT /game_assets/1.json
  def update
    respond_to do |format|
      if @game_asset.update(game_asset_params)
        format.html { redirect_to @game_asset, notice: '素材情報の更新が完了しました。' }
        format.json { render :show, status: :ok, location: @game_asset }
      else
        format.html { render :edit }
        format.json { render json: @game_asset.errors, status: :unprocessable_entity }
      end
    end
  end

  def step2
    @game_asset = GameAsset.find(params[:id])
    respond_to do |format|
      if @game_asset.update(game_asset_params)
        format.html { redirect_to "/game_assets/#{@game_asset.id}/edit3", notice: '商品情報の登録が完了しました。素材ファイルをアップロードして下さい。' }
        format.json { render :edit3, status: :ok, location: @game_asset }
      else
        format.html { render :edit3, notice: '値が正しくありません。'}
        format.json { render json: @game_asset.errors, status: :unprocessable_entity }
      end
    end
  end

  def step3
    @game_asset = GameAsset.find(params[:id])
    respond_to do |format|
      if @game_asset.save(game_asset_params)
        format.html { redirect_to "/game_assets/#{@game_asset.id}/edit3", notice: '商品情報の登録が完了しました。素材ファイルをアップロードして下さい。' }
        format.json { render :show, status: :ok, location: @game_asset }
      else
        format.html { render :show, notice: '値が正しくありません。'}
        format.json { render json: @game_asset.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /game_assets/1
  # DELETE /game_assets/1.json
  def destroy
    bucket = AWS::S3.new.buckets[Rails.application.secrets.aws_s3_bucket_name]
    dir_file = Rails.application.secrets.aws_s3_dir_name + @game_asset.file_name
    obj = bucket.objects[dir_file]
    obj.delete

    @game_asset.destroy
    respond_to do |format|
      format.html { redirect_to game_assets_url, notice: 'Game asset was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def upload
    #File -> temp
    file = game_asset_params[:file]
    name = file.original_filename
    File.open("tmp/check/#{name}", 'wb') do |f|
      file.read do |chunk|
        f.write(chunk)
      end
    end
    %x(clamscan "tmp/check/#{name}")

    if $? == 0
      # File -> Storage
      bucket = AWS::S3.new.buckets[Rails.application.secrets.aws_s3_bucket_name]
      object = bucket.objects[Rails.application.secrets.aws_s3_dir_name + file.original_filename]
      object.write(file)

      # File Info -> Database
      @game_asset.user_id = current_user.id
      @game_asset.file_name = file.original_filename

      respond_to do |format|
        if @game_asset.save
          format.html { redirect_to @game_asset, notice: '素材の登録が完了しました。' }
          format.json { render :show, status: :created, location: @game_asset }
        else
          format.html { render :new , notice: '値が正しくありません。'}
          format.json { render json: @game_asset.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to new_game_asset_path, alert: 'アップロードに失敗しました。素材ファイルがウイルスに感染している疑いがあります。' 
    end
    %x(rm -rf "tmp/check/#{name}")
  end

  def download
    bucket = AWS::S3.new.buckets[Rails.application.secrets.aws_s3_bucket_name]
    dir_file = Rails.application.secrets.aws_s3_dir_name + @game_asset.file_name

    send_data(bucket.objects[dir_file].read, {
      filename: @game_asset.file_name,
      content_disposition: 'attachement'
      })

    @game_asset.increment_dt
  end

  def test
  end

  def thumbnail
    thumb_file = params[:file]
    thumb_name = thumb_file.original_filename
    @thumb_path = "tmp/#{thumb_name}"

    File.open(@thumb_path, 'wb') do |f|
      f.write(thumb_file.read)
    end

    # @thumb = 'gesomaru.png'
    redirect_to '/game_assets/test2'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game_asset
      @game_asset = GameAsset.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_asset_params
      params.require(:game_asset).permit(:name, :price, :main_category, :sub_category, 
        :sales_copy, :sales_body, :sales_closing, :file, :thumbnail, :screenshots, :order)
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
