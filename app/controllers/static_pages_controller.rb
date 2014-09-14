class StaticPagesController < ApplicationController
  def top
  end
  def mailer
    @mail = SystemMailer.register_confirmation.deliver
    redirect_to(root_path)
  end
end
