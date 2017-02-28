Hg::Engine.routes.draw do
  # TODO: should route Messenger to a nested route, not root
  post '/', to: Facebook::Messenger::Server
end
