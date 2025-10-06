module AccountBlock
  class EmailOtp < ApplicationRecord
    self.table_name = "email_otps" # ensure table is correct

    # ----------------------------
    # Validations
    # ----------------------------
    validates :email, presence: true, format: { 
      with: /\A[\w+\-.]+@(.*\.)?(edu\.in|ac\.in)\z/i, 
      message: "must be a student email (edu.in or ac.in)" 
    }
    validates :otp, presence: true, length: { is: 6 }

    # ----------------------------
    # Callbacks
    # ----------------------------
    before_validation :generate_otp, on: :create
    before_validation :set_expiry, on: :create

    # ----------------------------
    # Methods
    # ----------------------------
    def generate_otp
      self.otp = rand.to_s[2..7] # 6-digit OTP
    end

    def set_expiry
      self.expires_at = 10.minutes.from_now
      self.verified = false
    end

    def valid_otp?(entered_otp)
      !verified && expires_at > Time.current && otp == entered_otp
    end
  end
end
