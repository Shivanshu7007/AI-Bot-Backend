module AccountBlock
  class OtpMailer < ApplicationMailer
    default from: "shivanshu.mishra.work@gmail.com"  # change to your email

    # ----------------------------
    # Send OTP email
    # ----------------------------
    def send_otp(email_otp)
      @otp = email_otp.otp
      mail(to: email_otp.email, subject: "Your OTP Code")
    end
  end
end
