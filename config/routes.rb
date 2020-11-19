Rails.application.routes.draw do
  

  get '/setup', to: 'welcome#setup', as: 'setup'  

  root 'welcome#index'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
