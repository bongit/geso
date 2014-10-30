# coding: utf-8
class GameAssetsController < ApplicationController
  before_action :signed_in_user, except: [:index]
  before_action :asset_owner, only: [:edit, :update, :destroy, :zip, :upload, :asset_file_upload, :thumbnail_check, :screenshot_check, :back_to_upload, :asset_file_confirm] # include set_game_asset
  before_action :set_game_asset, only: [:show, :review_new, :download, :review_new, :review_edit, :add_to_cart, :get_free_asset]
  require 'rubygems'
  require 'zip'

  # GET /game_assets
  # GET /game_assets.json
  def index
    # 設定
    if params[:order] == nil || params[:order] == ""
      params[:order] = "created_at desc"
    end

    @game_assets = GameAsset.where(make_public: true).search(params[:search], params[:main_category], params[:sub_category]).order("#{params[:order]}").paginate(page: params[:page], :per_page => 25)

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

  # POST /game_assets
  # POST /game_assets.json
  def create
    @game_asset = GameAsset.new(game_asset_params)
    @game_asset.user_id = current_user.id
    @game_asset.make_public = false
    @game_asset.file_uploaded = false
    @game_asset.downloaded_times = 0

    respond_to do |format|
      if @game_asset.save
        format.html { redirect_to asset_file_upload_game_asset_path(@game_asset), notice: '素材の仮登録が完了しました。引き続き素材ファイルをアップロードして下さい。' }
      else
        format.html { render :new }
      end
    end
  end

  # GET /game_assets/1/edit
  def edit
    if @game_asset.file_uploaded == false
      redirect_to asset_file_upload_game_asset_path
    end
  end

  # PATCH/PUT /game_assets/1
  # PATCH/PUT /game_assets/1.json
  def update
      if @game_asset.update(game_asset_params)
        redirect_to @game_asset, notice: "素材の情報を更新しました。"
      else
        render :edit, notice: '値が正しくありません。'
      end
  end

  # DELETE /game_assets/1
  # DELETE /game_assets/1.json
  def destroy
    if @game_asset.downloaded_times == 0
      if GameAsset.find(@game_asset.id).destroy
        bucket = AWS::S3.new.buckets[Rails.application.secrets.aws_s3_bucket_name]
        dir_file = Rails.application.secrets.aws_s3_dir_name + "geso_#{@game_asset.id}_#{@game_asset.file_name}"
        obj = bucket.objects[dir_file]
        obj.delete

        thumb_name = "public/assets/thumbs/thumbnail_#{@game_asset.id}.png"
        if File.exist?(thumb_name)
          %x(rm -rf "#{thumb_name}")
        end

        count = 1
        screen_shot_name = ""
        while count < 4
          screen_shot_name = "public/assets/screenshots/ss#{count}_asset#{@game_asset.id}.png"
          if File.exist?(screen_shot_name)
              %x(rm -rf "#{screen_shot_name}")
          end
          count += 1
        end

        carts = Cart.where(asset_id: @game_asset.id)
        if carts != nil
          carts.each do |c|
            c.destroy
          end
        end

        respond_to do |format|
          format.html { redirect_to current_user, notice: "素材を削除しました。" }
        end
      else
        redirect_to @game_asset, alert: "エラーが発生しました。"
      end
    else
      redirect_to @game_asset, alert: "既に利用者がいるため削除はできません。素材を非公開にして、今後新しい利用者が出ないようにして下さい。"
    end
  end

  def asset_file_upload
    if @game_asset.file_uploaded
      redirect_to @game_asset
    elsif @game_asset.file_name
      name = @game_asset.file_name
      %x(rm -rf "tmp/check/#{name}")
      @game_asset.update(file_name: nil)
    end
  end

  def zip
    file = form_tag_params[:file]
    if file != nil
      if file.size < 100.megabytes
        name = file.original_filename
        File.open("tmp/check/#{name}", 'wb') do |f|
          f.write(file.read)
        end
        %x(clamscan "tmp/check/#{name}")
        if $? == 0
          zip_names = Array.new
          Zip::File.open("tmp/check/#{name}") do |inner|
            inner.each do |i|
              next if i.name =~ /\/$/
              logger.info("name : " + i.name)
              zip_names.push(i.name)
            end
          end
          @game_asset.zip_includes = zip_names
          @game_asset.file_name = file.original_filename
            if @game_asset.save 
              redirect_to asset_file_confirm_game_asset_path, notice: "素材ファイルの解析が終了しました。このファイルで良いか確認して下さい。"
            else
              %x(rm -rf "tmp/check/#{name}")
              redirect_to :back, alert: "素材情報の更新に失敗しました。もう一度やり直して下さい。"
            end
        else
          %x(rm -rf "tmp/check/#{name}")
          redirect_to :back, alert: "ファイルの解析に失敗しました。もう一度やり直して下さい。"
        end
      else
        redirect_to :back, alert: "ファイルが500MBを超えています。"
      end 
    else
      redirect_to :back, alert: "ファイルが選択されていません。"
    end
  end

  def asset_file_confirm
    if @game_asset.file_uploaded
      redirect_to @game_asset
    elsif !@game_asset.file_name
      redirect_to asset_file_upload_game_asset_path
    end
  end

  def upload
    @game_asset.file_uploaded = true
    if @game_asset.save
      name = @game_asset.file_name
      file = File.read("tmp/check/#{name}")

      # File -> Storage
      new_name = "geso_#{@game_asset.id}_#{@game_asset.name}"
      bucket = AWS::S3.new.buckets[Rails.application.secrets.aws_s3_bucket_name]
      object = bucket.objects[Rails.application.secrets.aws_s3_dir_name + new_name]
      object.write(file)

      redirect_to edit_game_asset_path, notice: '素材のアップロードが完了しました。残りの情報を入力して、素材を公開しましょう。'
    else
      redirect_to asset_file_upload_game_asset_path , alert: "素材の登録に失敗しました。"
    end
    %x(rm -rf "tmp/check/#{name}")
  end

  def thumbnail_check
    thumb = form_tag_params[:thumb]
    if thumb != nil
      if thumb.size < 1.megabytes
        name = thumb.original_filename
        File.open("tmp/check/#{name}", 'wb') do |f|
          f.write(thumb.read)
        end
        %x(clamscan "tmp/check/#{name}")

        if $? == 0
          %x(cp "tmp/check/#{name}" "public/assets/thumbs/thumbnail_#{@game_asset.id}.png")
          redirect_to edit_game_asset_path, notice: 'サムネイル画像のアップロードが完了しました。'
        else
          redirect_to edit_game_asset_path, notice: 'サムネイル画像のアップロードに失敗しました。'
        end
        %x(rm -rf "tmp/check/#{name}")
      else
      redirect_to :back, alert: "ファイルが制限サイズを超えています。"
      end        
    else
      redirect_to :back, alert: "ファイルが選択されていません。"
    end
  end

  def screenshot_check
    screenshots = params[:screenshots]
    if screenshots != nil
      count = 1
      screenshots.each do |ss|
        name = ss.original_filename
        if ss.size < 1.megabytes
          File.open("tmp/check/#{name}", 'wb') do |f|
            f.write(ss.read)
          end

          %x(clamscan "tmp/check/#{name}")
          if $? == 0
            %x(cp "tmp/check/#{name}" "public/assets/screenshots/ss#{count}_asset#{@game_asset.id}.png")
            count += 1
          else
            %x(rm -rf "tmp/check/#{name}")
            redirect_to edit_game_asset_path, alert: 'スクリーンショット画像のアップロードに失敗しました。ファイルがウイルスに感染している疑いがあります。' and return
          end
          %x(rm -rf "tmp/check/#{name}")
        else
          redirect_to edit_game_asset_path, alert: "ファイル#{name}が制限サイズを超えています。" and return
        end
      end
        redirect_to edit_game_asset_path, notice: 'スクリーンショットのアップロードが完了しました。'
    else
      redirect_to :back, alert: "ファイルが選択されていません。"
    end
  end

  def download
    bought_assets = BoughtAsset.where(user_id: current_user)

    if bought_assets.find_by(game_asset_id: @game_asset.id)
    bucket = AWS::S3.new.buckets[Rails.application.secrets.aws_s3_bucket_name]
    dir_file = Rails.application.secrets.aws_s3_dir_name + "geso_#{@game_asset.id}_#{@game_asset.name}"

    send_data(bucket.objects[dir_file].read, {
      filename: @game_asset.file_name,
      content_disposition: 'attachement'
      })
    else
      redirect_to root_path, alert: "エラーが発生しました。"
    end
  end

  def add_to_cart
    if @game_asset.user_id != current_user.id
      @cart = Cart.new
      @cart.user_id = current_user.id
      @cart.asset_id = @game_asset.id
      if @cart.save
        redirect_to cart_user_path(current_user), notice: "カートに商品が追加されました。"
      else
        redirect_to :back , notice: "既にカートに入っています。"   
      end
    else
      redirect_to @game_asset
    end
  end

  def get_free_asset
      if @game_asset.price == 0
        bought_asset = BoughtAsset.new
        bought_asset.user_id = current_user.id
        bought_asset.game_asset_id = @game_asset.id
        if bought_asset.save
          @game_asset.increment_dt
          redirect_to bought_assets_user_path, notice: "無料素材を入手できます。"
        else
          redirect_to bought_assets_user_path, notice: "既に入手済みです。"
        end
      else
        redirect_to root_path, alert: "エラーが発生しました。"
      end
  end

  def review_new
    if Review.find_by(reviewer_id: current_user.id, game_asset_id: @game_asset.id)
      redirect_to review_edit_game_asset_path    
    elsif BoughtAsset.find_by(user_id: current_user.id, game_asset_id: @game_asset.id)
      @review = Review.new
      @review.reviewer_id = current_user.id
      @review.game_asset_id = @game_asset          
    else
      redirect_to root_path, alert: "エラーが発生しました。"
    end
  end

  def review_edit
    if Review.find_by(reviewer_id: current_user.id, game_asset_id: @game_asset.id)
      reviews = Review.where(game_asset_id: @game_asset.id)
      @review = reviews.find_by(reviewer_id: current_user.id)
    else
      redirect_to reivew_new_game_asset_path
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game_asset
      @game_asset = GameAsset.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_asset_params
      params.require(:game_asset).permit(:name, :price, :main_category, :sub_category, :file_uploaded, :promo_url,
        :sales_copy, :sales_body, :sales_closing, :make_public, :order, :license, :search, :genre)
    end

    def form_tag_params
      params.permit(:file, :thumb)
    end

    def signed_in_user
      redirect_to signin_url, notice: "ログインして下さい。" unless signed_in?
    end

    def asset_owner
      @game_asset = GameAsset.find(params[:id])
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
