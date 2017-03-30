module Hg
  class Engine < ::Rails::Engine
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    isolate_namespace Hg
  end
end
