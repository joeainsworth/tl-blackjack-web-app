require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'secretk3y'

helpers do
  SUIT  = ['H', 'S', 'C', 'D']
  CARDS = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  BLACKJACK_VALUE  = 21
  DEALER_MIN_VALUE = 17

  def new_player?
    !session[:player_name]
  end

  def shuffle_deck
    session[:deck] = SUIT.product(CARDS).shuffle
  end

  def deal_cards
    session[:player_cards] = []
    session[:dealer_cards] = []

    2.times do
      session[:player_cards] << session[:deck].pop
      session[:dealer_cards] << session[:deck].pop
    end
  end

  def calculate_total(hand)
    total = 0
    face_values = hand.map { |card| card[1] }
    face_values.each do |value|
      if value == "A"
        total += 11
      else
        total += (value.to_i == 0 ? 10 : value.to_i )
      end
    end

    face_values.select { |value| value == "A" }.count.times do
      break if total <= BLACKJACK_VALUE
      total -= 10
    end

    total
  end

  def dealer_total
    calculate_total(session[:dealer_cards])
  end

  def player_total
    calculate_total(session[:player_cards])
  end

  def deal_single_card(option)
    session[:dealer_cards] << session[:deck].shift if option == 'dealer'
    session[:player_cards] << session[:deck].shift if option == 'player'
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = case card[1]
      when 'A' then 'ace'
      when 'K' then 'king'
      when 'Q' then 'queen'
      when 'J' then 'jack'
      else card[1]
    end

    value = "#{suit}_#{value}"
    "<img src='/images/cards/#{value}.jpg' class='card_image'>"
  end

  def end_of_game?(name, total)
    if total > BLACKJACK_VALUE
      looser!("#{name} lost with a total of #{total}!")
      @show_hit_or_stay_controls = false
      @play_again = true
    elsif total == BLACKJACK_VALUE
      winner!("#{name} hit Blackjack!")
      @show_hit_or_stay_controls = false
      @play_again = true
    end
  end

  def winner!(msg)
    @flash = { 'type': 'success', 'message': msg }
    @play_again = true
  end

  def looser!(msg)
    @flash = { 'type': 'danger', 'message': msg }
    @play_again = true
  end

  def tie!(msg)
    @flash = { 'type': 'success', 'message': msg }
    @play_again = true
  end
end

before do
  @flash = {}
  @play_again = false
  @show_hit_or_stay_controls = true
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @flash = { type: 'danger', message: 'Name is required' }
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name].capitalize
  redirect '/game'
end

get '/game' do
  redirect '/' if new_player?
  session[:turn] = 'player'
  shuffle_deck
  deal_cards
  end_of_game?(session[:player_name], player_total)
  erb :game
end

post '/game/player/hit' do
  deal_single_card('player')
  end_of_game?(session[:player_name], player_total)
  erb :game
end

post '/game/player/stay' do
  @show_hit_or_stay_controls = false
  @flash = { 'type': 'success', 'message': 'You choose to stay!'}
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = 'dealer'
  @show_hit_or_stay_controls = false
  if end_of_game?('Dealer', dealer_total)
  elsif dealer_total >= 17
    if player_total > dealer_total
      winner!("#{session[:player_name]} won with a total of #{player_total}!")
    elsif dealer_total > player_total
      looser!("Dealer won with a total of #{dealer_total}!")
    else
      tie!("It was a tie! Both players scored #{player_total}.")
    end
  else
    @show_dealer_hit_control = true
  end

  erb :game
end

post '/game/dealer/hit' do
  @show_hit_or_stay_controls = false
  deal_single_card('dealer')
  redirect '/game/dealer'
end

get '/game_over' do
  erb :game_over
end
