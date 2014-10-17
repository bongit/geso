# coding: utf-8
class GameAssetsController < ApplicationController
  before_action :set_game_asset, only: [:show, :edit, :update, :destroy]
  before_action :singed_in_asset
  before_action :correct_user, only: [:edit]

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
    @is_bought_asset = BoughtAsset.exists?(user_id: current_user.id, game_asset_id: params[:id])
    @license = @game_asset.license
  end

  # GET /game_assets/new
  def new
    @game_asset = GameAsset.new
  end

  def ajax_test
  end

  def ajax_post
    @license = params[:license].to_i
    logger.info("license :" + params[:license])
    respond_to do |format|
      format.js
    end
  end

  # GET /game_assets/1/edit
  def edit
  end


  # POST /game_assets
  # POST /game_assets.json
  def create
    @game_asset = GameAsset.new(game_asset_params)
    @game_asset.user_id = current_user.id

    respond_to do |format|
      if @game_asset.save
        format.html { redirect_to "/game_assets/#{@game_asset.id}/edit", notice: '素材の仮登録が完了しました。引き続き情報を入力して下さい。' }
      else
        format.html { render :edit, notice: '値が正しくありません。'}
      end
    end
  end

  # PATCH/PUT /game_assets/1
  # PATCH/PUT /game_assets/1.json
  def update
    respond_to do |format|
      if @game_asset.update(game_asset_params)
        format.html { redirect_to @game_asset, notice: '素材情報の更新が完了しました。' }
      else
        format.html { render :edit }
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
    end
  end

  def thumbnail_check
    @game_asset = GameAsset.find(params[:id])
    thumb = params[:thumb]
    name = thumb.original_filename
    File.open("tmp/check/#{name}", 'wb') do |f|
      f.write(thumb.read)
    end
    %x(clamscan "tmp/check/#{name}")

    if $? == 0
      %x(cp "tmp/check/#{name}" "public/assets/thumbs/thumbnail_#{params[:id]}.png")
      redirect_to @game_asset, notice: 'サムネイル画像のアップロードが完了しました。'
    else
      redirect_to @game_asset, notice: 'サムネイル画像のアップロードに失敗しました。'
    end
    %x(rm -rf "tmp/check/#{name}")
  end

  def screenshot_check
    @game_asset = GameAsset.find(params[:id])
    screenshots = params[:screenshots]
    count = 1

    screenshots.each do |ss|
      name = ss.original_filename

      File.open("tmp/check/#{name}", 'wb') do |f|
        f.write(ss.read)
      end

      %x(clamscan "tmp/check/#{name}")

      if $? == 0
        %x(cp "tmp/check/#{name}" "public/assets/screenshots/ss#{count}_asset#{params[:id]}.png")
        count += 1
      else
        redirect_to @game_asset, notice: 'スクリーンショット画像のアップロードに失敗しました。'
        return
      end
      %x(rm -rf "tmp/check/#{name}")
    end
    redirect_to @game_asset, notice: 'スクリーンショットのアップロードが完了しました。'

  end

  def upload
    #File -> temp
    @game_asset = GameAsset.find(params[:id])
    file = params[:file]
    name = file.original_filename
    File.open("tmp/check/#{name}", 'wb') do |f|
      f.write(file.read)
    end
    %x(clamscan "tmp/check/#{name}")

    if $? == 0
      # File -> Storage
      new_name = "geso_#{@game_asset.id}_#{@game_asset.name}"
      bucket = AWS::S3.new.buckets[Rails.application.secrets.aws_s3_bucket_name]
      object = bucket.objects[Rails.application.secrets.aws_s3_dir_name + new_name]
      object.write(file)

      # File Info -> Database
      @game_asset.user_id = current_user.id
      @game_asset.file_name = file.original_filename

      respond_to do |format|
        if @game_asset.save
          format.html { redirect_to @game_asset, notice: '素材の登録が完了しました。公開ボタンを押してゲソ丸に公開しましょう。' }
        else
          format.html { render :show , notice: '値が正しくありません。'}
        end
      end
    else
      redirect_to @game_asset, alert: 'アップロードに失敗しました。素材ファイルがウイルスに感染している疑いがあります。' 
    end
    %x(rm -rf "tmp/check/#{name}")
  end

  def download
    @game_asset = GameAsset.find(params[:id])
    bought_assets = BoughtAsset.where(user_id: current_user)

    if bought_assets.find_by(game_asset_id: @game_asset.id)
    bucket = AWS::S3.new.buckets[Rails.application.secrets.aws_s3_bucket_name]
    dir_file = Rails.application.secrets.aws_s3_dir_name + "geso_#{@game_asset.id}_#{@game_asset.name}"

    send_data(bucket.objects[dir_file].read, {
      filename: @game_asset.file_name,
      content_disposition: 'attachement'
      })

    @game_asset.increment_dt

    bought_asset = BoughtAsset.new
    bought_asset.user_id = current_user.id
    bought_asset.game_asset_id = @game_asset.id
    bought_asset.save
    else
      redirect_to root_path, alert: "エラーが発生しました。"
    end
  end

  def add_to_cart
    @cart = Cart.new
    @cart.user_id = current_user.id
    @cart.asset_id = params[:id]
    if @cart.save
      redirect_to "/users/#{current_user.id}/cart_index", notice: "カートに商品が追加されました。"
    else
      render :show , notice: "error"   
    end
  end

  def review_new
    set_game_asset
    @review = Review.new
    @review.reviewer_id = current_user.id
    @review.game_asset_id = params[:id]
  end 

  def review_create
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game_asset
      @game_asset = GameAsset.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_asset_params
      params.require(:game_asset).permit(:name, :price, :main_category, :sub_category, 
        :sales_copy, :sales_body, :sales_closing, :file, :thumb, :screenshots, :order, :license, :make_public)
    end

    def singed_in_asset
      store_location
      redirect_to signin_url, notice: "ログインして下さい。" unless signed_in?
    end

    def correct_user
      @author = User.find(@game_asset.user_id)
      redirect_to(root_path) unless current_user?(@author)
    end


    AWS.config(
      access_key_id:      Rails.application.secrets.aws_s3_access_key, 
      secret_access_key:  Rails.application.secrets.aws_s3_secret_key, 
      region:             'us-west-2',
      :s3_server_side_encryption => :aes256
    )
end
