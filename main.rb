require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'secretk3y'

helpers do
  SUIT  = ['H', 'S', 'C', 'D']
  CARDS = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']

  def shuffle_deck
    SUIT.product(CARDS).shuffle
  end

  def deal_cards
    2.times do
      session[:player_cards] << session[:deck].pop
      session[:dealer_cards] << session[:deck].pop
    end
  end


end

get '/' do
  erb :set_name
end

post '/set_name' do
  session[:player_name] = params[:player_name].capitalize
  redirect '/game'
end

get '/game' do
  session[:deck] = shuffle_deck
  session[:player_cards] = []
  session[:dealer_cards] = []
  deal_cards
  erb :game
end

