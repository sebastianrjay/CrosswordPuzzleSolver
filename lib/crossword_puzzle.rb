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
		# A totally arbitrary number. I never saw the websites return more than 
		# 4 appropriate results for a given clue query.
		max_search_results_count = 5
		current_search_results_count, database_name = 1, :crossword_heaven

		until current_search_results_count > max_search_results_count
			return true if solve_with_database(database_name, current_search_results_count)
			current_search_results_count += 1

			if current_search_results_count > max_search_results_count && 
					database_name == :crossword_heaven
				current_search_results_count = 1
				database_name = :crossword_giant
			end
		end

		false
	end

	def solve_with_database(database_name, limit)
		found_match, max_search_len = false, 1

		until solved?
			words.each do |word|
				next if word.solved?

				if database_name == :crossword_heaven
					word_solutions = word.valid_solutions(false)
				else
					word_solutions = word.valid_solutions(true)
				end

				if word_solutions.length > 0 && word_solutions.length <= max_search_len
					i, has_conflicts = 0, true
					until i == word_solutions.length
						current_solution, has_conflicts = word_solutions[i], false
						str_idx = 0
						previous_j, previous_k = word.intersection_positions(self).first

						word.intersection_positions(self).each do |pos|
							j, k = pos
							increment = [j - previous_j, k - previous_k].max
							str_idx += increment
							other_word = word_positions[pos].find {|word| word != self }

							if other_word.letter_positions[pos] == current_solution[str_idx]
								has_conflicts = true
								break
							end

							previous_j, previous_k = j, k
						end

						break unless has_conflicts

						i += 1
					end

					unless has_conflicts
						word.set_as_string(word_solutions[i], self)
						found_match = true
					end
				end
			end

			found_match ? max_search_len = 1 : max_search_len += 1
			found_match = false

			return false if max_search_len > limit
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
