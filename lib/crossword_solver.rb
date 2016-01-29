module CrosswordSolver

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
		# max_search_results_count is a totally arbitrary number. I never saw the 
		# websites return more than 4 usable results for a given clue query.
		max_search_results_count = 5
		current_search_results_count, database_name = 1, :crossword_giant

		# This is a greedy algorithm; a lower value of current_search_results_count 
		# increases greediness, while a higher value decreases greediness.
		until current_search_results_count > max_search_results_count
			if solve_with_database(database_name, current_search_results_count)
				# We've solved the puzzle! In programmer-speak, 'we' means 'computer'.
				return true
			end

			current_search_results_count += 1

			if current_search_results_count > max_search_results_count && 
					database_name == :crossword_giant
				current_search_results_count = 1
				database_name = :crossword_heaven
			end
		end

		false
	end

	def solve_with_database(database_name, limit)
		found_match, max_search_len = false, 1

		until solved?
			words.each do |word|
				next if word.solved?

				# Have no fear! Word#valid_solutions caches database results, and 
				# narrows itself down as we fill in letters thanks to Word#to_regex.
				if database_name == :crossword_giant
					word_solutions = word.valid_solutions(false)
				else
					word_solutions = word.valid_solutions(true)
				end

				# This is a greedy algorithm. We want to first set the solutions in the 
				# puzzle where we only found one matching solution, because we're more 
				# confident that such solutions are correct. As we move along in the 
				# solve algorithm, we increase max_search_len so that we can set more 
				# ambiguous solutions, whose correctness is less likely.
				if word_solutions.length > 0 && word_solutions.length <= max_search_len
					0.upto(word_solutions.length - 1) do |i|
						# No conflict? Great, let's move on and set the current word as the 
						# current solution! Otherwise, let's keep searching solutions
						unless has_conflict?(word, word_solutions[i])
							word.set_as_string(word_solutions[i], self)
							found_match = true
							break
						end
					end
				end
			end

			# We just finished iterating through all the words in the puzzle, checking 
			# at most max_search_len solutions per iteration. If we didn't find a 
			# match, we need to make the algorithm less greedy and increase 
			# max_search_len. If we found a match, then we reset max_search_len to 1 
			# because we've narrowed down our solution constraints by one additional 
			# solved word, and we may be able to greedily prefer solving a word that 
			# now only has one matching database search result.
			found_match ? max_search_len = 1 : max_search_len += 1
			found_match = false

			# We've increased max_search_len to the limit and still haven't found any 
			# new valid solutions. Return false; we were unable to solve the puzzle 
			# using the database specified by database_name.
			return false if max_search_len > limit
		end

		# We solved the puzzle using the database specified by database_name!
		true
	end
end
