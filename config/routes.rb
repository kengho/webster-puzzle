Rails.application.routes.draw do
  scope ENV['RAILS_RELATIVE_URL_ROOT'] || '/' do
    namespace :api do
      namespace :v1 do
        match '/definitions' => "definitions#index", via: [:options, :get]
        match '/puzzles' => "puzzles#index", via: [:options, :get]
      end
    end
  end
end
