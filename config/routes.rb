FleerAndTaker::Application.routes.draw do
  controller 'play' do
    match "play(/index)", :action => :index, :via => [:get]
    match "play/accept_only_friends", :action => :accept_only_friends, :via => [:post]
#    match "play/tweet", :action => :tweet, :via => [:post]
    get "play/search"
    match "play/:id/new", :action => :new, :via => [:get]
    match "play/:id/create", :action => :create, :via => [:post]
    match "play/:id/game", :action => :game, :via => [:get], :as => :play_game
    match "play/:id/move", :action => :move, :via => [:post]
    match "play/:id/cancel", :action => :cancel, :via => [:post]
    match "play/:id/give_up", :action => :give_up, :via => [:post]
    match "play/:id/talk", :action => :talk, :via => [:post]
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "index#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
