class SystemMailer < ActionMailer::Base
  default from: 'example@gmail.com'
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.registration_confirmation.subject
  #
  def register_confirmation
    mail to: 'appdente@gmail.com'
  end
end
