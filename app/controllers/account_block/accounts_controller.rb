module AccountBlock
  class AccountsController < ApplicationController
    skip_before_action :verify_authenticity_token

    # ----------------------------
    # POST /account_block/accounts/send_otp
    # ----------------------------
    def send_otp
      email = params[:email]
      email_otp = AccountBlock::EmailOtp.new(email: email)
      if email_otp.save
        OtpMailer.send_otp(email_otp).deliver_later
        render json: { success: true, message: "OTP sent to #{email}" }, status: :ok
      else
        render json: { success: false, errors: email_otp.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # ----------------------------
    # POST /account_block/accounts/verify_otp
    # ----------------------------
    # def verify_otp
    #   email = params[:email]
    #   entered_otp = params[:otp]

    #   email_otp = AccountBlock::EmailOtp.find_by(email: email, verified: false)

    #   if email_otp&.valid_otp?(entered_otp)
    #     email_otp.update(verified: true)

    #     # Create Devise user if not exists
    #     user = User.find_or_create_by(email: email) do |u|
    #       u.password = Devise.friendly_token[0, 20]
    #     end

    #     render json: { success: true, message: "OTP verified, user created", user_id: user.id }, status: :ok
    #   else
    #     render json: { success: false, message: "Invalid or expired OTP" }, status: :unprocessable_entity
    #   end
    # end
    def verify_otp
      email = params[:email]
      entered_otp = params[:otp]

      # If user already exists
      if User.exists?(email: email)
        render json: {
          success: false,
          message: "Account already exists"
        }, status: :unprocessable_entity
        return
      end

      email_otp = AccountBlock::EmailOtp
                    .where(email: email, verified: false)
                    .order(created_at: :desc)
                    .first

      if email_otp&.valid_otp?(entered_otp)
        email_otp.update!(verified: true)

        user = User.create!(
          email: email,
          password: Devise.friendly_token[0, 20]
        )

        render json: {
          success: true,
          message: "OTP verified, user created",
          user_id: user.id
        }, status: :ok
      else
        render json: {
          success: false,
          message: "Invalid or expired OTP"
        }, status: :unprocessable_entity
      end
    end
  end
end