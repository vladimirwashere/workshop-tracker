# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  resource :session, only: %i[new create destroy]
  resources :passwords, param: :token, only: %i[new create edit update]

  # Account management
  resource :account, only: %i[show update]

  # User settings
  resource :user_settings, only: %i[update]

  # Admin user management
  resources :users, except: :destroy do
    member do
      patch :deactivate
      patch :reactivate
      delete :soft_delete
      post :reset_password
    end
  end

  # Workers and salary history
  resources :workers do
    resources :worker_salaries, only: %i[index new create edit update destroy]
  end

  # Projects with nested phases, tasks and materials
  resources :projects do
    resources :phases, only: %i[show new create edit update destroy]
    resources :tasks, only: %i[show new create edit update destroy]
    resources :material_entries
  end

  # Top-level material entries (cross-project listing + create)
  resources :material_entries, only: %i[index new create]

  # Daily logs
  resources :daily_logs do
    collection do
      post :duplicate
    end
  end

  # Cascading dropdowns for daily log form
  get "phases_for_project/:project_id", to: "phases#for_project", as: :phases_for_project
  get "tasks_for_project/:project_id", to: "tasks#for_project", as: :tasks_for_project

  # Attachments (polymorphic: related_type + related_id via params)
  resources :attachments, only: %i[index show create destroy] do
    member do
      get :download
    end
  end

  # Config management
  resources :configs, only: %i[index edit update]

  # Currency rates
  resources :currency_rates, only: %i[index] do
    collection do
      post :fetch_latest
    end
  end

  # Dashboard
  get "dashboard", to: "dashboard#show"

  # Gantt chart
  get "gantt", to: "gantt#show"
  get "gantt/data", to: "gantt#data", as: :gantt_data
  patch "gantt/update_task", to: "gantt#update_task", as: :gantt_update_task

  # Worker timelines
  get "worker_timelines", to: "worker_timelines#index", as: :worker_timelines
  get "worker_timelines/:worker_id", to: "worker_timelines#show", as: :worker_timeline

  # Reports
  get "reports/financial", to: "reports#financial", as: :financial_reports
  get "reports/activity", to: "reports#activity", as: :activity_reports
  get "reports", to: redirect("/reports/financial")

  # Root
  root "sessions#new"
end
