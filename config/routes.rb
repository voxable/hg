Hg::Engine.routes.draw do
  # TODO: should route Messenger to a nested route, not root
  get '/', to: Facebook::Messenger::Server
  post '/', to: Facebook::Messenger::Server
end
