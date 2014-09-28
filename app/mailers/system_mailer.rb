class SystemMailer < ActionMailer::Base
  default from: 'celendipity@gmail.com'
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.registration_confirmation.subject
  #
  def register_confirmation(address)
  	mail to: address
    # mail to: 'appdente@gmail.com'
  end

  def password_reset(address)
    @user = User.find_by(email: address)
  	mail to: address
  end
end
