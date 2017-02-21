require 'colorize'
require 'io/console'
require_relative './crossword_puzzle'
require_relative './cursor'
require_relative './game_io_helper'
require_relative './word'

class Game
	include GameIOHelper
	attr_reader :cursor, :puzzle

	def initialize
		prompt_player_for_puzzle_info
		@cursor = Cursor.new(puzzle.width, puzzle.height)
		run_gameplay
	end

	def run_gameplay
		while true
			print_running_game

			input = read_char

			case input
			when "\177" # BACKSPACE
				puzzle.delete_letter(cursor.position)
			when "\e[A" # UP ARROW
        cursor.move!("up")
      when "\e[B" # DOWN
        cursor.move!("down")
      when "\e[C" # RIGHT
        cursor.move!("right")
      when "\e[D" # LEFT
        cursor.move!("left")
			when "$"
				puts "\nHang tight! The computer is solving your puzzle as fast as it can.\n\n"
				is_solved = puzzle.solve!
				render_computer_solution(is_solved)
      when "\e" # ESCAPE
        puts "\nAre you sure you want to exit the game? (y/n)"
        exit if gets.chomp == "y"
      when "\u0003"
        puts "CONTROL-C"
        exit
			when /([A-Z]|[a-z])/
				puzzle.set_letter(cursor.position, input.upcase)
      end
		end
	end

	private

		def prompt_player_for_puzzle_info
			system "clear"
			puts "\n\nWelcome to the Ruby Crossword Puzzle (Solver)!\n"
			puts "Please ensure that you started this game from the 
CrosswordPuzzleSolver root directory, via 'ruby lib/game.rb'.\n\n"

			clues_path = get_file_path("clues")
			layout_path = get_file_path("layout")

			@puzzle = CrosswordPuzzle.new(layout_path, clues_path)
		end
end

Game.new
