require 'set'
require_relative './crossword_file_parser'
require_relative './word'

class CrosswordPuzzle
	include CrosswordFileParser
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
			puts "\nAre you sure you want to modify the solved word(s) at this 
position? (y/n)"
	    input = gets.chomp
	    return unless input.downcase == "y"
		end

		@word_positions[pos].each do |word|
			word.delete_letter(pos)
		end

		@words_remaining += previously_solved_word_count
	end

	def set_letter(pos, letter)
		return nil unless @word_positions[pos]

		@word_positions[pos].each do |word|
			word_already_solved = word.solved?
			word.set_letter(pos, letter)
			@words_remaining -= 1 if word.solved? && !word_already_solved
		end

		letter
	end

	def solve!
		current_limit = 10
		current_len, database_name = 1, :crossword_heaven

		until current_len > current_limit
			return true if solve_with_database(database_name, current_len)
			current_len += 1

			if current_len > current_limit && database_name == :crossword_heaven
				current_len, current_limit, database_name = 1, 10, :crossword_giant
			end
		end

		false
	end

	def solve_with_database(database_name, len_limit)
		found_match, solutions_count = false, 1

		until solved?
			words.each do |word|
				next if word.solved?

				if database_name == :crossword_heaven
					word_solutions = word.valid_solutions(false)
				else
					word_solutions = word.valid_solutions(true)
				end

				if word_solutions.length > 0 && word_solutions.length <= solutions_count
					word.set_as_string(word_solutions.first)
					@words_remaining -= 1
					found_match = true
				end
			end

			found_match ? solutions_count = 1 : solutions_count += 1
			found_match = false

			return false if solutions_count > len_limit
		end

		true
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
