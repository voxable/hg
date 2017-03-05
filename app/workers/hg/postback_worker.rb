module Hg
  class PostbackWorker
    include Sidekiq::Worker
    # TODO: Make number of retries configurable.
    sidekiq_options retry: 1
  end
end
