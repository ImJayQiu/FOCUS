Rails.application.routes.draw do


    resources :verification do
	collection do
	    post 'result'
	    post 'detail'
	    get 'anomaly'
	    get 'departure'
	    get 'corr'
	    post 'probfore'
	    get 'probpoint'
	    get 'climatology'
	    get 'sd'
	    get 'rmse'
	    get 'acc'
	end
    end



    resources :wiki_pages do
	collection do
	    get 'wikifocus'
	end
    end 
    
    resources :rmethods
    resources :fmethods # forecast methods management

    resources :datasets # model datasets and observation datasets management

    resources :roc do
	collection do
	    post 'result'
	end
    end

    resources :forecastm2 do
	collection do
	    post 'result'
	    post 'detail'
	    get 'anomaly'
	    get 'departure'
	    get 'corr'
	    post 'probfore'
	    get 'probpoint'
	    get 'climatology'
	    get 'sd'
	    get 'rmse'
	    get 'acc'
	end
    end



    # forecast form submit to this controller return "result" page
    resources :forecast do
	collection do
	    post 'result'
	    post 'detail'
	    get 'anomaly'
	    get 'departure'
	    get 'corr'
	    post 'probfore'
	    get 'probpoint'
	    get 'climatology'
	    get 'sd'
	    get 'rmse'
	    get 'acc'
	end
    end

    resources :countries # user countries management

    devise_for :users , controllers: {registrations: 'users/registrations', sessions: 'users/sessions'}

    resources :users

    resources :welcome do
	collection do
	    get 'index'
	    get 'thankyou'
	    get 'home'
	    get 'forecast'
	    get 'verification'
	    get 'forecastm2'
	    get 'debug'
	    get 'roc'
	end
    end

    get 'welcome/home'  # ladning page after login
    get 'welcome/index' # index page before login
    root 'welcome#index'

    # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
