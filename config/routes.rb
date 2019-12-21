Rails.application.routes.draw do

  resources :rmethods
    resources :fmethods # forecast methods management

    resources :datasets # model datasets and observation datasets management

  resources :roc do
	collection do
	    post 'result'
	end
    end


    # forecast form submit to this controller return "result" page
    resources :forecast do
	collection do
	    post 'result'
	end
    end

    resources :countries # user countries management

    devise_for :users , controllers: {registrations: 'users/registrations', sessions: 'users/sessions'}

    resources :users

    resources :welcome do
	collection do
	    get 'index'
	    get 'home'
	    get 'forecast'
	    get 'debug'
	    get 'roc'
	end
    end

    get 'welcome/home'  # ladning page after login
    get 'welcome/index' # index page before login
    root 'welcome#home'

    # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
