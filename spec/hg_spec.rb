require 'rails_helper'

describe Hg do
  class Bot
    class Router < Hg::Router; end
  end

  it 'has a version number' do
    expect(Hg::VERSION).not_to be nil
  end
end
