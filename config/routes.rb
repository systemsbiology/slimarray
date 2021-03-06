ActionController::Routing::Routes.draw do |map|
  map.resources :usage_reports, :only => [:new, :create]

  map.resources :service_option_sets

  map.resources :service_options

  # allow other apps to authenticate and then bounce back
  map.connect 'bounce', :controller => "bounce", :action => "bounce"

  # backward compatibility with bookmarked login page
  map.connect 'session/new', :controller => "welcome", :action => "home"

  # logout
  map.connect 'logout', :controller => "sessions", :action => "destroy"

  # SLIM* Authorization routes
  map.resources :sessions
  # map.resources :lab_groups
  map.resources :registrations
  map.resources :users do |users|
    users.resources :lab_memberships, :name_prefix => "user_"
  end
  map.resources :lab_memberships

  # load routes from naming schemer plugin
  # Use with Rails 2.3
  #map.from_plugin :naming_schemer
  map.resources :naming_schemes
  
  #SLIMarray routes
  map.resources :bioanalyzer_runs, :collection => {:grid => :get}, :member => {:pdf => :get}
  map.resources :charge_periods, :member => {:pdf => :get, :excel => :get}

  map.resources :charge_sets, :collection => {:list_all => :get} do |charge_sets|
   charge_sets.resources :charges, :collection => {:bulk_edit_move_or_destroy => :post, :new_from_template => :post}
  end

  map.resources :charge_templates, :collection => {:grid => :get}
  map.resources :lab_groups do |lab_groups|
    lab_groups.resources :chip_types do |chip_types|
      chip_types.resources :chip_transactions, :collection => {:grid => :get}
      chip_types.resources :chip_purchases, :only => [:new, :create]
      chip_types.resources :chip_intergroup_purchases, :only => [:new, :create]
      chip_types.resources :chip_borrows, :only => [:new, :create]
      chip_types.resources :chip_returns, :only => [:new, :create]
    end
  end
  map.resources :chip_transactions, :except => :index
  map.resources :chip_purchases, :only => [:new, :create]
  map.resources :chip_intergroup_purchases, :only => [:new, :create]
  map.resources :chip_borrows, :only => [:new, :create]
  map.resources :chip_returns, :only => [:new, :create]
  map.resources :chip_types, :collection => {:grid => :get}, :member => {:service_options => :get}
  map.resources :inventory_checks, :collection => {:grid => :get}
  map.resources :organisms, :collection => {:grid => :get}
  map.resources :projects, :collection => {:grid => :get}
  map.resources :samples, :collection => {:browse => :get, :search => :get, :all => :get, :grid => :get, :approve => :get}
  map.resources :sample_sets, :only => [:new, :create, :cancel_new_project, :edit, :update],
    :collection => {:sample_mixture_fields => :get}
  map.resources :labels, :collection => {:grid => :get}
  map.resources :platforms, :collection => {:grid => :get}
  map.resources :raw_data_paths, :only => :create
  map.resources :qc_sets, :only => [:create, :show]
  map.resources :qc_thresholds, :collection => {:grid => :get}
  map.resources :microarrays, :only => [:index, :show]
  map.resources :chips, :only => [:index, :edit, :update, :destroy], :collection => {:grid => :get}

  map.resources :hybridization_sets
  map.new_hybridization_set 'hybridization_sets/new', :controller => 'hybridization_sets', :action => 'new', :method => :post

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "welcome", :action => "home"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.resource :session
end
