Shapado::Application.routes.draw do

  match '/topics/autocomplete' => 'topics#autocomplete'
  match '/universities/autocomplete' => 'universities#autocomplete'
  
  resources :universities
  
  resources :affiliations

  resources :topics, :only => [:index, :show, :edit, :update] do
    member do
      post :follow
      post :unfollow
      post :refuse_suggestion
    end

    collection do
      post :follow
    end
  end

  resources :invitations, :only => [:index, :create]

  resources :waiting_users, :only => :create

  devise_for(:users,
             :path_names => {:sign_in => 'login', :sign_out => 'logout'},
             :controllers => {:registrations => 'users'})
  match 'confirm_age_welcome' => 'welcome#confirm_age', :as => :confirm_age_welcome
  match '/change_language_filter' => 'welcome#change_language_filter', :as => :change_language_filter
  match '/register' => 'users#create', :as => :register
  match '/signup' => 'users#new', :as => :signup
  match '/signup/:current_step' => 'users#wizard', :as => :wizard
  match '/moderate' => 'admin/moderate#index', :as => :moderate
  match '/moderate/ban' => 'admin/moderate#ban', :as => :ban
  match '/moderate/unban' => 'admin/moderate#unban', :as => :unban
  match '/about' => 'welcome#about', :as => :about
  match '/send_feedback' => 'welcome#send_feedback', :as => :send_feedback
  match '/tos' => 'doc#tos', :as => :tos
  match '/privacy' => 'doc#privacy', :as => :privacy
  
  match '/auth/:provider/callback' => 'settings/external_accounts#create'
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
    resources :external_accounts, :only => [:index, :destroy]
  end

  resources :users, :except => [:edit, :update] do
    member do
      post :unfollow
      post :follow
      post :refuse_suggestion
    end
  end

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

  get '/questions/:id/:slug' => 'questions#show', :as => :se_url, :id => /\d+/

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
      get :watch
      get :unwatch
      get :history
      get :revert
      get :diff
      get :classify
      get :unclassify
      get :retag
      put :retag_to
      post :close
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
  match '/:group_invitation' => 'users#new'
  root :to => 'welcome#index'
end
