class Developer < ApplicationRecord
  # == Constants ============================================================

  # == Attributes ===========================================================
  #          id:  :integer,
  #       first:  :text, required
  #      middle:  :text,
  #        last:  :text, required
  #      suffix:  :text,
  #         dob:  :date, required
  #       email:  :text, required
  #  created_at:  :datetime,
  #  updated_at:  :datetime

  # == Extensions ===========================================================

  # == Relationships ========================================================
  has_validated_avatar
  has_protected_password

  has_many :tasks, inverse_of: :developer

  # == Validations ==========================================================
  validates :first, :last, presence: true, length: { minimum: 2 }

  validates_presence_of :dob
  validate :older_than_12, if: :dob_changed?

  validates :email, presence: true,
                    format: { with: /\A[^@;\/\\]+\@[^@;\/\\]+\.[^@;\.\/\\]+\z/ },
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
