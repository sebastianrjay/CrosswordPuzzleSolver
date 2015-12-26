require 'set'
require_relative './crossword_file_parser'
require_relative './crossword_solver'
require_relative './word'

class CrosswordPuzzle
	include CrosswordFileParser
	include CrosswordSolver
	
	attr_reader :clues, :height, :width, :words, :word_positions, :words_remaining

	def initialize(layout_filename, clues_filename)
		parse_clues_file(clues_filename)
		@words, @word_positions, @words_remaining = Set.new, {}, 0
		parse_layout_file(layout_filename)
	end

	def delete_letter(pos)
		previously_solved_word_count = 0
		@word_positions[pos].each do |word|
			previously_solved_word_count += 1 if word.solved?
		end

		if previously_solved_word_count > 0
			puts "\nAre you sure you want to modify the solved word(s) at the 
position? #{pos} (y/n)"
	    input = gets.chomp
	    return unless input.downcase == "y"
		end

		@word_positions[pos].each do |word|
			word.delete_letter(pos)
		end

		@words_remaining += previously_solved_word_count
	end

	def set_letter(pos, letter, force = false)
		return false unless @word_positions[pos]

		@word_positions[pos].each do |word|
			word_already_solved = word.solved?
			force ? word.set_letter!(pos, letter) : word.set_letter(pos, letter)
			@words_remaining -= 1 if word.solved? && !word_already_solved
		end

		letter
	end

	def solved?
		@words_remaining == 0
	end

	def word_intersection_positions
		# Never changes after puzzle instantiation, so let's cache it!
		@word_intersection_positions ||= @word_positions.keys.select do |key| 
			@word_positions[key].length == 2
		end
	end
end
