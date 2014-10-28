class UsersController < ApplicationController
  require 'paypal-sdk-adaptivepayments'
  PayPal::SDK.load('config/paypal.yml',  ENV['RACK_ENV'] || 'development' || 'production')

  before_action :signed_in_user, except: [:new, :create, :forgot_password, :send_password_reset, :edit_new_password, :update_password]
  before_action :correct_user,   only: [:edit, :update, :cart, :cart_delete, :cart_delete_all, :order]
  before_action :admin_user,     only: :destroy
  before_action :set_user, only: [:show, :edit_new_password, :update_password]

  # GET /users
  # GET /users.json
  def index
    @users = User.search(params[:search]).paginate(page: params[:page], :per_page => 30)
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @game_assets = @user.game_assets.paginate(page: params[:page], :per_page => 10)
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)
    respond_to do |format|
      if @user.save
        format.html { redirect_to '/signin', notice: 'ユーザー登録が完了しました。' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    if BCrypt::Password.new(@user.password_digest) == user_params[:password]
      respond_to do |format|
        if @user.update(user_params)
          format.html { redirect_to @user, notice: '更新しました。' }
        else
          format.html { render :edit }
        end
      end
    else
      flash.now[:error] = 'パスワードが違います。'
      render :edit
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    User.find(params[:id]).destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
    end
  end

  def following
    @title = "Following"
    @user = User.find(params[:id])
    @users = @user.followed_users.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = "Followers"
    @user = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end


  # Password
  def forgot_password
  end

  def send_password_reset
    if User.find_by(email: params[:address])
      user = User.find_by(email: params[:address])
      one_time_token = User.new_remember_token
      cookies[:one_time_token] = { value: one_time_token, expires: 10.minute.from_now }
      user.update_attribute(:one_time_token, one_time_token)

      SystemMailer.password_reset(params[:address]).deliver
      redirect_to root_path, notice: "確認用メールをお送りしました。メールに記載の方法でパスワードを変更して下さい。"
    else
      redirect_to :back, alert: "このメールアドレスは登録されていません。"
    end
  end

  def edit_new_password
    user = User.find(params[:id])
    if user.one_time_token != cookies[:one_time_token]
      cookies.each do |cookie|
        cookie.each do |c|
          logger.info(c)
        end
      end
      redirect_to root_path, alert: "もう一度やり直して下さい。"
    else

    end
  end

  # PATCH /users/1/update_password
  def update_password
    respond_to do |format|
      if @user.update(user_params)
        @user.update_attribute(:one_time_token, nil)
        cookies.delete :one_time_token
        format.html { redirect_to '/signin', notice: 'パスワードを変更しました。' }
      else
        format.html { render :edit_new_password }
      end
    end
  end

  def cart
    @in_cart_item_ids =  Cart.where(user_id: current_user.id)
    @all_assets = GameAsset.all
  end

  def cart_delete
    if Cart.destroy(params[:cart_item_id])
      redirect_to cart_user_path(current_user), :method => 'get', notice: "商品をカートから削除しました。"
    end 
  end

  def cart_delete_all
    in_cart_items = Cart.where(user_id: current_user.id)
    in_cart_items.each do |ic|
      Cart.destroy(ic)
    end
    redirect_to cart_user_path, :method => 'get', notice: "商品をカートから削除しました。"
  end

  def order
    in_cart_items = Cart.where(user_id: current_user.id)
    assets = Array.new
    in_cart_items.each do |ic|
      assets.push(GameAsset.find(ic.asset_id))
    end

    receivers = Array.new
    geso_amount = 0
    assets.each do |a|
      next if a.price == 0
      author = User.find(a.user_id)
      receivers.push({
        :amount => (a.price*0.75).round.to_i,
        :email => author.email
        })
      geso_amount += (a.price*0.25).round.to_i
    end

    receivers.push({
      :amount => geso_amount,
      :email => Rails.application.secrets.receive_address
      })

    @api = PayPal::SDK::AdaptivePayments.new

      # Build request object
      @pay = @api.build_pay({
        :actionType => "PAY",
        :receiverList => {
          :receiver => receivers
        },
        :currencyCode => "JPY",
        :cancelUrl => "http://#{Rails.application.secrets.host_name}/users/#{current_user.id}/cart",
        :returnUrl => "http://#{Rails.application.secrets.host_name}/users/#{current_user.id}/order_complete",
        :requestEnvelope => { :errorLanguage => "en_US" },
        :feesPayer => "EACHRECEIVER",})

      # Make API call & get response
      @response = @api.pay(@pay)
      logger.info("responseEnvelope.ack : " + @response.responseEnvelope.ack)

      # Access response
      if @response.success? && @response.payment_exec_status != "ERROR"
        @api.logger.info("Pay Key : " + @response.payKey + " : "+ @response.paymentExecStatus)

        in_cart_items.each do |ci|
          ci.pay_key = @response.payKey
          ci.save
        end
          redirect_to @api.payment_url(@response)  # Url to complete payment
      else
        @response.error[0].message
      end
  end

  def order_complete
    in_cart_items = Cart.where(user_id: current_user.id)
    pay_key_array = Array.new

    in_cart_items.each do |ci|
      pay_key_array.push(ci.pay_key)
    end

    if pay_key_array.uniq.length != 1 || pay_key_array.first == nil
      flash[:alert] = "エラーが発生しました。"
      redirect_to root_path and return
    end

    @api = PayPal::SDK::AdaptivePayments::API.new
    @payment_details_request = @api.build_payment_details()
    @payment_details_request.payKey = pay_key_array.first
    @payment_details_response = @api.payment_details(@payment_details_request)

    @api.logger.info("PayKey : " + pay_key_array.first)
    @api.logger.info("ack : " + @payment_details_response.responseEnvelope.ack)

    # 購入済みに追加　➡　カートから削除
    if @payment_details_response.responseEnvelope.ack == "Success"
      @api.logger.info("Status : " + @payment_details_response.status)

      if @payment_details_response.status == "COMPLETED"
        in_cart_items.each do |ic|
          bought_asset = BoughtAsset.new
          bought_asset.user_id = current_user.id
          bought_asset.game_asset_id = ic.asset_id
          bought_asset.pay_key = pay_key_array.first
            if bought_asset.save
              game_asset = GameAsset.find(bought_asset.game_asset_id)
              game_asset.increment_dt
              ic.destroy
            else
              logger.info("Critical Error !")        
              logger.info("user : " + current_user.id)            
              logger.info("pay key : " + pay_key_array.first)
              flash[:alert] = "重大なエラーが発生しました。運営者へ連絡して下さい。"       
              redirect_to root_path and return
            end
        end
      else
        flash[:alert] = "支払エラーが発生しました。"       
        redirect_to root_path and return
      end

    else
      flash[:alert] = "通信エラーが発生しました。"       
      redirect_to root_path and return
    end

    redirect_to bought_assets_user_path, notice: "素材の購入が完了しました。"
  end

  def cancel
    cart_items = Cart.where(user_id: current_user.id)
    cart_items.each do |ci|
      ci.pay_key = ""
      ci.save
    end
  end

  def bought_assets
    bought_assets = BoughtAsset.where(user_id: current_user.id)
    @assets = Array.new
    bought_assets.each do |ba|
       @assets.push(GameAsset.find(ba.game_asset_id))
    end
    @assets
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :profile_text, :url)
    end

    # Before actions
    def signed_in_user
      redirect_to signin_url, notice: "ログインして下さい。" unless signed_in?
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_path) unless current_user?(@user)
    end

     def admin_user
      redirect_to(root_path) unless current_user.admin?
    end
end
