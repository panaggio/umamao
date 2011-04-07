Shapado::Application.routes.draw do

  match '/topics/autocomplete' => 'topics#autocomplete'
  match '/unanswered' => 'welcome#unanswered', :as => :unanswered
  get '/notifications' => 'welcome#notifications', :as => :notifications

  resources :affiliations

  resources :topics, :only => [:index, :show, :edit, :update] do
    member do
      post :follow
      post :unfollow
      post :ignore
      post :unignore
      get :unanswered
      get :followers
      post :toggle_email_subscription
      get :javascript_embedded
    end

    collection do
      post :follow
    end
  end

  resources :invitations, :only => [:new, :create] do
    collection do
      get :pending
      get :accepted
    end
  end

  match "/proxy" => "contacts#import_callback"
  resources :contacts do
    collection do
      post :fetch
      get :import
      get :search
    end
  end

  resources :waiting_users, :only => :create

  devise_for(:users,
             :path_names => {:sign_in => 'login', :sign_out => 'logout'},
             :controllers => {:registrations => 'users'})
  match 'confirm_age_welcome' => 'welcome#confirm_age', :as => :confirm_age_welcome
  match '/change_language_filter' => 'welcome#change_language_filter', :as => :change_language_filter
  match '/register' => 'users#create', :as => :register
  match '/signup' => 'users#new', :as => :signup
  match '/resend_confirmation_email' => 'users#resend_confirmation_email'
  match '/signup/find' => 'signup_wizard#find'
  match '/signup/:current_step' => 'signup_wizard#wizard', :as => :wizard
  match '/moderate' => 'admin/moderate#index', :as => :moderate
  match '/moderate/ban' => 'admin/moderate#ban', :as => :ban
  match '/moderate/unban' => 'admin/moderate#unban', :as => :unban
  match '/about' => 'welcome#about', :as => :about
  match '/send_feedback' => 'welcome#send_feedback', :as => :send_feedback
  match '/tos' => 'doc#tos', :as => :tos
  match '/privacy' => 'doc#privacy', :as => :privacy

  get '/agreement' => 'agreement#edit', :as => :agreement
  post '/agreement' => 'agreement#update'
  get '/agreement/refuse' => 'agreement#refuse', :as => :refuse_agreement

  match '/auth/:provider/callback' => 'settings/external_accounts#create'
  match '/auth/dac' => 'affiliations#add_dac_student', :via => :post
  match '/auth/failure' => 'settings/external_accounts#failure'

  namespace :settings do
    match 'profile' => 'profile#edit', :via => :get
    match 'profile' => 'profile#update', :via => :put
    match 'resume' => 'resume#edit'
    match 'notifications' => 'notifications#edit', :via => :get
    match 'notifications' => 'notifications#update', :via => :put
    match 'password' => 'password#edit', :via => :get
    match 'password' => 'password#update', :via => :put
    match 'account' => 'account#edit', :via => :get
    match 'account' => 'account#update', :via => :put
    match 'follow_topics' => 'follow_topics#edit', :via => :get
    match 'ignore_topics' => 'ignore_topics#edit', :via => :get
    resources :external_accounts, :only => [:index, :destroy]
  end

  resources :users, :except => [:edit, :update] do
    member do
      post :unfollow
      post :follow
      get  :set_not_new
      get  :followers
      get  :following
      get  :topics
      get  :questions
      get  :answers
    end
  end

  match '/users/inline_edition' => 'users#inline_edition'

  post "/suggestions/refuse" => "suggestions#refuse",
    :as => :refuse_suggestion

  resources :ads
  resources :adsenses
  resources :adbards

  resources :pages do
    member do
      get :js
      get :css
    end
  end

  resources :announcements do
    collection do
      post :hide
    end
  end

  resources :imports do
    collection do
      post :send_confirmation
    end
  end

  match '/questions/:id/:slug' => 'questions#show', :as => :se_url, :id => /\d+/

  resources :questions do
    collection do
      get :tags_for_autocomplete
      get :unanswered
      get :related_questions
    end

    member do
      get :flag
      get :favorite
      get :unfavorite
      post :watch
      post :unwatch
      get :history
      get :revert
      get :diff
      get :classify
      get :unclassify
      get :retag
      put :retag_to
      post :close
      get :followers
    end

    resources :comments

    resources :answers do
      member do
        get :flag
        get :history
        get :diff
        get :revert
      end

      resources :comments
    end

    resources :close_requests
  end

  match 'questions/tagged/:tags' => 'questions#index', :constraints => { :tags => /\S+/ }, :as => :tag
  match 'questions/unanswered/tags/:tags' => 'questions#unanswered'

  resources :groups do
    member do
      get :allow_custom_ads
      get :disallow_custom_ads
      get :close
      get :accept
      get :css
    end
  end

  resources :votes
  resources :flags
  resources :share_question
  resources :share_answer

  scope '/manage' do
    resources :widgets do
      member do
        post :move
      end
    end

    resources :members
  end

  scope '/manage', :as => 'manage' do
    controller 'admin/manage' do
      match 'properties' => :properties
      match 'content' => :content
      match 'theme' => :theme
      match 'actions' => :actions
      match 'stats' => :stats
      match 'reputation' => :reputation
      match 'domain' => :domain
    end
  end

  match '/search' => 'searches#index', :as => :search
  match '/search/autocomplete' => 'searches#autocomplete'
  match '/about' => 'groups#show', :as => :about

  [:universities, :courses, :course_offers,
   :academic_programs, :academic_program_classes].each do |submodel|

    resources submodel, :only => [:index, :show, :edit, :update],
    :controller => 'topics' do
      member do
        post :follow
        post :unfollow
        get :unanswered
        get :followers
        get :javascript_embedded
      end

      collection do
        post :follow
      end
    end
  end

  match '/content-search' => 'opensearch#index', :as => :opensearch

  match '/:group_invitation' => 'users#new'

  root :to => 'welcome#index'
end
