class ApplicationController < ActionController::Base

    before_action :authenticate_user!, except: :index

    before_action :configure_permitted_parameters, if: :devise_controller?

    protected

    def configure_permitted_parameters
	devise_parameter_sanitizer.permit(:sign_up) do |user_params|
	    user_params.permit(:name, :email, :country, :org, :password, :password_confirmation,)
	end
    end

    def after_sign_in_path_for(resource)
	# return the path based on resource
	welcome_home_path
    end

    def after_sign_out_path_for(resource)
	# return the path based on resource
	welcome_index_path
    end

    def after_sign_up_path_for(resource)
	welcome_home_path
    end


end
