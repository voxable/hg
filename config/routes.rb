Hg::Engine.routes.draw do
  # TODO: should route Messenger to a nested route, not root
  root to: Facebook::Messenger::Server
end
