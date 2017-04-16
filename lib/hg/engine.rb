module Hg
  class Engine < ::Rails::Engine
    AUTOLOAD_PATHS = Dir.glob(File.join(Hg::Engine.root, 'lib', '**/'))
    config.autoload_paths   += AUTOLOAD_PATHS
    config.eager_load_paths += AUTOLOAD_PATHS

    isolate_namespace Hg
  end
end
