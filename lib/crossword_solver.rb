module CrosswordSolver

	MAX_SOLUTION_SEARCH_RESULTS_COUNT = 5

	def has_conflict?(word, solution_string)
		str_idx = 0
		previous_j, previous_k = word.intersection_positions(self).first

		# This loop checks to see if solution_string conflicts with any 
		# solved or incomplete words that intersect with the current word.
		word.intersection_positions(self).each do |pos|
			j, k = pos
			# At least one of the values in this array is always 0.
			increment = [j - previous_j, k - previous_k].max
			str_idx += increment
			other_word = word_positions[pos].find {|new_word| new_word != word }

			# The solution_string conflicts with a word intersecting with the current 
			# word, so we return true.
			if other_word.letter_positions[pos] && 
					other_word.letter_positions[pos] != solution_string[str_idx]
				return true
			end

			previous_j, previous_k = j, k
		end

		false
	end

	def solve!
		Word::SOLUTION_WEBSITE_NAMES.each do |website_name|
			# This is a greedy algorithm; it constrains us to first solving words with 
			# max_allowable_search_len valid solutions, or less. We ignore words with 
			# more than MAX_SOLUTION_SEARCH_RESULTS_COUNT valid solutions, since the 
			# validity of those solutions is less certain.
			max_allowable_search_len = 1

			until max_allowable_search_len > MAX_SOLUTION_SEARCH_RESULTS_COUNT
				if solved_with_website?(website_name, max_allowable_search_len)
					return true # We've solved the puzzle with website_name!
				end

				max_allowable_search_len += 1
			end
		end

		false
	end

	def solved_with_website?(website_name, max_allowable_search_len)
		found_match, current_max_search_len = false, 1

		until solved?
			words.each do |word|
				next if word.solved?

				word_solutions = word.valid_solutions(website_name)

				if word_solutions.any? && word_solutions.count <= current_max_search_len
					word_solutions.each do |word_solution|
						# No conflict? Great, let's move on and set the current word as the 
						# current solution! Otherwise, let's keep searching solutions.
						unless has_conflict?(word, word_solution)
							word.set_as_string(word_solution, self)
							found_match = true
							break
						end
					end
				end
			end

			# We just finished iterating through all the words in the puzzle, checking 
			# at most current_max_search_len solutions per iteration. If we didn't 
			# find a match, we need to make the algorithm less greedy and increase 
			# current_max_search_len. If we found a match, then we reset 
			# current_max_search_len to 1 because we've narrowed down our solution 
			# constraints by one additional solved word, and we may be able to 
			# greedily prefer solving a word that now only has one valid solution.
			found_match ? current_max_search_len = 1 : current_max_search_len += 1
			found_match = false

			# We've increased current_max_search_len to the max_allowable_search_len 
			# and still haven't found any new valid solutions. Return false; we were 
			# unable to solve the puzzle with this website_name and this
			# max_allowable_search_len.
			return false if current_max_search_len > max_allowable_search_len
		end

		true
	end
end
