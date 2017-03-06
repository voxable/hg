RSpec.shared_context 'with mocked queue' do
  BOT_CLASS_NAME = 'NewsBot'

  let(:user_id) { '1' }
  # TODO: likely need a message factory
  let(:message) {
    Hashie::Mash.new({
                       sender: {id: user_id}
                     })
  }
  let(:bot_class) { class_double(BOT_CLASS_NAME).as_stubbed_const }
  let(:valid_args) { [user_id, 'news_bots', BOT_CLASS_NAME] }

  before(:example) do
    allow(queue_class).to receive(:new).and_return(queue)
    allow(queue).to receive(:pop).and_return({})
    # Access the let variable to instantiate the class double
    bot_class
  end
end

RSpec.shared_context 'when queue has unprocessed message' do
  let(:user_class) { class_double('User').as_stubbed_const }
  let(:router_class) { double('router', handle: nil) }

  before(:example) do
    allow(bot_class).to receive(:user_class).and_return(user_class)
    allow(bot_class).to receive(:router).and_return(router_class)
    allow(user_class).to receive(:find_or_create_by).and_return(user)
  end
end

