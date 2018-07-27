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

  attribute :new_avatar, :boolean
  attribute :new_password, :text
  attribute :new_password_confirmation, :text

  # == Extensions ===========================================================

  # == Relationships ========================================================
  has_one_attached :last_avatar
  has_one_attached :avatar
  has_many :tasks, inverse_of: :developer

  # == Validations ==========================================================
  validates :first, :last, presence: true, length: { minimum: 2 }

  validates_presence_of :dob
  validate :older_than_12, if: :dob_changed?

  validates :email, presence: true,
                    format: { with: /\A[^@;\/\\]+\@[^@;\/\\]+\.[^@;\.\/\\]+\z/ },
                    uniqueness: { case_sensitive: false }

  validate :avatar, :valid_image

  validate :new_password, :require_password_confirmation, if: :new_password?

  # == Scopes ===============================================================

  # == Callbacks ============================================================
  after_save :cache_current_avatar, if: :new_avatar?

  # == Class Methods ========================================================

  # == Instance Methods =====================================================
  def attach_avatar(file, options = {})
    avatar.attach(file, **options)
    __send__ :valid_image
  end

  private
    def password
      self[:password]
    end

    def password=(val)
      write_attribute :password, val
    end

    def require_password_confirmation
      if new_password.present?
        if new_password != new_password_confirmation
          errors.add(:new_password, 'Password does not match confirmation')
        else
          self.password = new_password
        end
      end
    end

    def older_than_12
      if dob > 13.years.ago.to_date
        errors.add(:dob, 'You must be at least 13 years old to use this app')
        false
      else
        true
      end
    end

    def valid_image_format
      unless avatar.blob.content_type.start_with? 'image/'
        errors.add(:avatar, 'is not an image file')
        return false
      end
      true
    end

    def valid_image_size
      if avatar.blob.byte_size > 500.kilobytes
        errors.add(:avatar, 'is too large, avatar must be < 500KB')
        return false
      end
      true
    end

    def valid_image
      return unless avatar.attached?

      if valid_image_format && valid_image_size
        cache_current_avatar
      else
        purge(avatar)
        load_last_avatar if last_avatar.attached?
        false
      end

    end

    def cache_current_avatar
      copy_avatar
    end

    def load_last_avatar
      copy_avatar :last_avatar, :avatar
    end

    def copy_avatar(from = :avatar, to = :last_avatar)
      from = __send__ from
      to = __send__ to

      purge(to) if to.attached?

      tmp = Tempfile.new
      tmp.binmode
      tmp.write(from.download)
      tmp.flush
      tmp.rewind

      to.attach(io: tmp, filename: from.filename, content_type: from.content_type)
      tmp.close
      true
    end
end
