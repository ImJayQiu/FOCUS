class User < ApplicationRecord

    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

    devise :database_authenticatable, :registerable,
	:recoverable, :rememberable, :validatable, :trackable

    ROLES = %w[Admin Expert User]
    # validates :name, :email, :org, :country, :presence => true

end
