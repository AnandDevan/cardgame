require 'net/http'
require 'json'

def run_game_loop
  game = Game.new
  last_drawn_card = "Waiting to draw first card"
  last_card = game.last_drawn_card
  last_drawn_card = "Last drawn card: #{last_card['value']} of #{last_card['suit']}" if last_card

  prompt = "#{"-"*90}\nEnter D, R, P, O, Q\n"\
  " - D: \tdraw card,\n"\
  " - R: \treset deck,\n"\
  " - P: \tprint cards sorted, \n"\
  " - Q: \tquit, \n"\
  " - O: \tPrint cards in draw order,\n"\
  " - S: \tSave game"
  puts prompt, last_drawn_card
  while input = gets.chomp
    #draw one card
    if input.upcase == 'D'
      print "\r" + ("\e[A\e[K"*2)
      card = game.draw_card
      puts last_drawn_card = "Last drawn card: #{card['value']} of #{card['suit']}"

    #shuffle/reset deck
    elsif input.upcase == 'R'
      print "\r" + ("\e[A\e[K"*2)
      game.shuffle_deck
      puts "Shuffled card deck"

    #print cards drawn in sorted order
    elsif input.upcase == 'P'
      # cards_drawn_so_far_sorted = game.drawn_cards_sorted.map{|card| "- #{card['value']} \tof #{card['suit']}"}.join "\n"
      cards_drawn_so_far_sorted = game.drawn_cards_sorted
      puts "Cards drawn so far in sorted order:\n#{cards_drawn_so_far_sorted}"
      puts prompt, last_drawn_card

    #print cards in order of draw
    elsif input.upcase == 'O'
      cards_drawn_so_far = game.drawn_cards.map{|card| "- #{card['value']} \tof #{card['suit']}"}.join "\n"
      drawn_cards_collapsed_list = game.drawn_cards_collapsed_list
      puts "Cards drawn so far in draw order:\n#{cards_drawn_so_far}"
      puts drawn_cards_collapsed_list
      puts prompt, last_drawn_card

    # save current game state
    elsif input.upcase == 'S'
      game.save_state
      print "\r" + ("\e[A\e[K"*2)
      puts "Saved game state to card_game.json"

    elsif input.upcase == 'Q'
      game.save_state if File.exist? game.saved_state_file
      puts "Quitting game"
      break
    end
  end
end

class Game
  @@root_url = 'http://deckofcardsapi.com/api'
  attr_accessor :deck_id, :drawn_cards, :saved_state_file

  def initialize
    @drawn_cards = []
    @deck_id = ''
    @saved_state_file = 'card_game_state.json'
    puts @@root_url
    load_saved_game || initialize_deck
  end

  def draw_card
    url = "#{@@root_url}/deck/#{@deck_id}/draw/?count=1"
    resp = JSON.parse Net::HTTP.get_response(URI.parse(url)).body
    if resp && resp['success'] == true
      if resp['cards'] && resp['cards'].size == 1
        card = resp['cards'].first
        @drawn_cards << resp['cards'][0]
        return card
      end
    end
    'Failed drawing card'
  end

  def shuffle_deck
    url = "#{@@root_url}/deck/#{@deck_id}/shuffle/"
    resp = JSON.parse Net::HTTP.get_response(URI.parse(url)).body
    puts resp
    @drawn_cards = []
    reset_saved_state
  end

  def initialize_deck
    url = "#{@@root_url}/deck/new/shuffle/?deck_count=1"
    resp = JSON.parse Net::HTTP.get_response(URI.parse(url)).body
    raise "Initialize deck api failure" if resp['success'] != true
    reset_saved_state
    @deck_id = resp['deck_id']
  end

  def save_state
    cur_state = {
      'deck_id' => @deck_id,
      'drawn_cards' => @drawn_cards
    }
    file = File.open('card_game_state.json', 'w')
    file.write JSON.pretty_generate cur_state
    file.close
  end

  def reset_saved_state
    return unless File.exist? @saved_state_file
    # File.truncate 'card_game_state.json', 0
    File.delete 'card_game_state.json'
    @drawn_cards = []
  end

  def load_saved_game
    return false unless File.exist? @saved_state_file
    file = File.open 'card_game_state.json', 'r'
    return false unless file.size > 0
    cur_state = JSON.parse file.read

    # validate deck is still active by doing a shuffle
    url = "#{@@root_url}/deck/#{cur_state['deck_id']}/shuffle/"
    resp = JSON.parse Net::HTTP.get_response(URI.parse(url)).body
    return false unless resp['success']

    @drawn_cards = cur_state['drawn_cards']
    @deck_id = cur_state['deck_id']
    puts "Loaded saved game. Number of cards drawn is #{@drawn_cards.size}"
    true
  end

  def drawn_cards
    @drawn_cards
  end
  def last_drawn_card
    @drawn_cards.last
  end

  def drawn_cards_collapsed_list
    res = {}
    @drawn_cards.each do |card|
      res[card['value']] ||= 0
      res[card['value']] += 1
    end
    res
  end

  # method to compare cards based on value
  def drawn_cards_sorted
    sorted_cards = @drawn_cards.sort do |card1, card2|
      card_value(card1['value']) <=> card_value(card2['value'])
    end
    res = {}
    sorted_cards.each do |card|
      res[card['value']] ||= 0
      res[card['value']] += 1
    end
    res
  end
  # method to return an int for a given card value,
  # map face cards to int
  def card_value(card_val)
    return  01 if card_val == 'ACE'
    return  11 if card_val == 'JACK'
    return  12 if card_val == 'QUEEN'
    return  13 if card_val == 'KING'
    card_val.to_i
  end
end

# kick off game loop
run_game_loop
