EzcaterSlack::Engine.routes.draw do
  resource :webhooks, only: [:create]
end
