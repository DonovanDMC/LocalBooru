# frozen_string_literal: true

id_name_constraint = { id: %r{[^/]+?}, format: /json|html/ }.freeze
Rails.application.routes.draw do
  require "sidekiq/web"
  require "sidekiq_unique_jobs/web"

  mount Sidekiq::Web, at: "/sidekiq"

  namespace :admin do
    resource :bulk_update_request_import, only: %i[new create]
    resources :exceptions, only: %i[index show]
    resources :destroyed_posts, only: %i[index show update]
  end
  resources :favorites, only: %i[index create destroy] do
    collection do
      get :clear
      put :clear
    end
  end
  resources :creators, constraints: id_name_constraint do
    member do
      put :revert
    end
    collection do
      get :show_or_new
      resources :versions, only: %i[index], controller: "creators/versions", as: "creator_versions" do
        get :search, on: :collection
      end
      resources :urls, only: %i[index], controller: "creators/urls", as: "creator_urls"
    end
  end
  resource :dtext_preview, only: %i[create]
  resources :mod_actions, only: %i[index show]
  resources :pools do
    resource :order, only: %i[edit], controller: "pools/orders"
    member do
      put :revert
    end
    collection do
      get :gallery
      resources :versions, controller: "pools/versions", as: "pool_versions", only: %i[index] do
        member do
          get :diff
        end
      end
    end
  end
  resources :posts, only: %i[index show update delete destroy] do
    resource :similar, only: %i[show], controller: "posts/iqdb"
    collection do
      get :random
      resources :events, controller: "posts/events", as: "post_events", only: :index
      resource :iqdb, controller: "posts/iqdb", as: "posts_iqdb", only: %i[show] do
        collection do
          post :show
        end
      end
      resources :replacements, controller: "posts/replacements", as: "post_replacements", only: %i[index new create destroy] do
        member do
          put :approve
          put :reject
          post :promote
        end
      end
      resources :versions, controller: "posts/versions", as: "post_versions", only: %i[index] do
        member do
          put :undo
        end
      end
    end
    member do
      put :update_iqdb
      put :revert
      get :show_seq
      get :favorites

      put :expunge
      get :delete
      put :undelete
      put :regenerate_thumbnails
      put :regenerate_videos
      post :add_to_pool
      post :remove_from_pool
      get "/frame/:frame", to: "posts#frame", as: "frame"
      resource :move_favorites, controller: "posts/move_favorites", as: "move_favorites_post", only: %i[show create]
    end
  end
  resources :qtags, path: "q", only: %i[show]
  resources :stats, only: %i[index]
  resources :tags, constraints: id_name_constraint, only: %i[index show edit update] do
    collection do
      get :preview
      get :meta_search
      resource :related, controller: "tags/related", as: "related_tags", only: %i[show] do
        collection do
          get :bulk
          post :bulk
        end
      end
      resources :versions, controller: "tags/versions", as: "tag_versions", only: %i[index]
      resources :aliases, controller: "tags/aliases", as: "tag_aliases" do
        put :approve, on: :member
      end
      resources :implications, controller: "tags/implications", as: "tag_implications" do
        put :approve, on: :member
      end
    end
    member do
      put :correct
    end
  end
  resources :uploads, only: %i[index show new create]

  options "*all", to: "application#enable_cors"

  get "/static/keyboard_shortcuts", to: "static#keyboard_shortcuts", as: "keyboard_shortcuts"
  get "/static/site_map", to: "static#site_map", as: "site_map"
  get "/static/toggle_mobile_mode", to: "static#toggle_mobile_mode", as: "toggle_mobile_mode"
  get "/static/theme", to: "static#theme", as: "theme"
  get "/robots", to: "static#robots", as: "robots"
  get "/sitemap", to: "static#site_map", as: "sitemap_root"
  get "/up", to: "rails/health#show", as: "health_check"
  root to: "static#home"

  get "*other", to: "static#not_found"
end
