class UsersController < ApplicationController
  require 'paypal-sdk-adaptivepayments'
  PayPal::SDK.load('config/paypal.yml',  ENV['RACK_ENV'] || 'development')

  before_action :signed_in_user, only: [:index, :edit, :update, :destroy, :following, :followers]
  before_action :correct_user,   only: [:edit, :update, :cart_index]
  before_action :admin_user,     only: :destroy

  # GET /users
  # GET /users.json
  def index
    @users = User.search(params[:search]).paginate(page: params[:page], :per_page => 30)
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])
    @game_assets = @user.game_assets
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
  # GET /users/forgot_password
  def send_password_reset
    @address = params[:address]
    SystemMailer.password_reset(@address).deliver
    redirect_to root_path, notice: "確認用メールをお送りしました。"
  end

  # GET /users/1/new_password
  def edit_new_password
    @user = User.find(params[:id])
  end

  # PATCH /users/1/update_password
  def update_password
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to '/signin', notice: 'パスワードを変更しました。' }
      else
        format.html { render :edit_new_password }
      end
    end
  end

  def cart_index
    @in_cart_item_ids =  Cart.where(user_id: current_user.id)
    @all_assets = GameAsset.all
  end

  def cart_delete
    if Cart.destroy(params[:cart_item_id])
      respond_to do |format|
        format.html { redirect_to "/users/#{current_user.id}/cart_index", notice: "商品をカートから削除しました。"}
      end       
    end 
  end

  def order
    @receivers = Array.new
    geso_amount = 0
    assets = GameAsset.where(id: params[:buying_asset_ids])
    assets.each do |ba|
      author = User.find(ba.user_id)
      @receivers.push({
        :amount => (ba.price*0.75).round.to_i,
        :email => author.email
        })
      geso_amount += (ba.price*0.25).round.to_i
    end
    @receivers.push({
      :amount => geso_amount,
      :email => "celendipity-facilitator@gmail.com"
      })

    @api = PayPal::SDK::AdaptivePayments.new

      # Build request object
      @pay = @api.build_pay({
        :actionType => "PAY",
        :cancelUrl => "http://localhost:3000/users/#{current_user.id}/cart_index",
        :currencyCode => "JPY",
        :feesPayer => "EACHRECEIVER",
        :receiverList => {
          :receiver => @receivers
        },
        :ipnNotificationUrl => "http://localhost:3000/users/#{current_user.id}/ipn_notify",
        :returnUrl => "http://localhost:3000/users/#{current_user.id}/order_complete" })

      # Make API call & get response
      @response = @api.pay(@pay)

      # Access response
      if @response.success? && @response.payment_exec_status != "ERROR"
        @api.logger.info("Pay Key : " + @response.payKey + " : "+ @response.paymentExecStatus)
        cart_items = Cart.where(asset_id: params[:buying_asset_ids])

        cart_items.each do |ci|
          ci.pay_key = @response.payKey
          ci.save
        end
          redirect_to @api.payment_url(@response)  # Url to complete payment
      else
        @response.error[0].message
      end
  end

  def order_complete
    cart_items = Cart.where(user_id: current_user.id)
    pay_key_array = Array.new

    cart_items.each do |ci|
      pay_key_array.push(ci.pay_key)
    end
    if pay_key_array.uniq.length != 1
      redirect_to root_path, notice: "エラーが発生しました"
      return
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
      if @payment_details_response.status == "COMPLETED" || @payment_details_response.status == "CREATED"
        in_cart_items = Cart.where(user_id: current_user.id)
        in_cart_items.each do |item|
          bought = BoughtAsset.new
          bought.user_id = current_user.id
          bought.game_asset_id = item.asset_id
          bought.save
          item.destroy
        end
      end
    end
    redirect_to "/users/#{current_user.id}/bought_assets"
  end

  def ipn_notify
    if PayPal::SDK::Core::API::IPN.valid?(request.raw_post)
      render notice: "IPN message: VERIFIED"
    else
      render notice: "IPN message: INVALID"
    end
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

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :profile_text, :url, :pay_key)
    end

    # Before actions
    def signed_in_user
      store_location
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
