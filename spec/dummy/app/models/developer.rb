class Developer < ApplicationRecord
  # == Constants ============================================================

  # == Attributes ===========================================================
  #          id:  :integer,
  #       first:  :text, required
  #      middle:  :text,
  #        last:  :text, required
  #      suffix:  :text,
  #         dob:  :date, required
  #      gender:  :enum
  #       email:  :text, required
  #  created_at:  :datetime,
  #  updated_at:  :datetime
  # enum gender: BetterRecord::Gender::ENUM

  # == Extensions ===========================================================

  # == Relationships ========================================================
  has_validated_avatar
  has_protected_password

  has_many :tasks, inverse_of: :developer
  has_many_attached :multi_images

  # == Validations ==========================================================
  validates :first, :last, presence: true, length: { minimum: 2 }

  validates_presence_of :dob, :gender, :money_col
  validate :older_than_12, if: :dob_changed?

  validates :email, presence: true,
                    format: { with: /\A[^@\s;.\/\[\]\\]+(\.[^@\s;.\/\[\]\\]+)*@[^@\s;.\/\[\]\\]+(\.[^@\s;.\/\[\]\\]+)*\.[^@\s;.\/\[\]\\]+\z/ },
                    uniqueness: { case_sensitive: false }


  # == Scopes ===============================================================

  # == Callbacks ============================================================

  # == Boolean Class Methods ================================================

  # == Class Methods ========================================================

  # == Boolean Methods ======================================================

  # == Instance Methods =====================================================

  private
    def older_than_12
      if dob > 13.years.ago.to_date
        errors.add(:dob, 'You must be at least 13 years old to use this app')
        false
      else
        true
      end
    end

end
