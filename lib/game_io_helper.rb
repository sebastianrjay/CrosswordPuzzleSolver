module GameIOHelper

	def gameplay_instructions
		"\nTo move the cursor, use the arrow keys. If the cursor shows a number when 
hovering over a square, then that is the clue number/letter associated with that 
square. When the cursor is hovering over a square, press any letter key on the 
keyboard to enter that letter into that square. If you saw a number or letter 
before your input, you won't see your input until you move the cursor. To 
replace a letter, simply press a different letter key. To delete an entered 
letter and replace it with a blank square, press BACKSPACE. Press ESC at any 
time to quit.\n\n"
	end

	def get_file_path(file_type)
		puts "\nPlease enter the relative path to your #{file_type} text file, from 
the CrosswordPuzzleSolver root directory. If you have a '#{file_type}.txt' file 
saved in the CrosswordPuzzleSolver root directory, simply enter '#{file_type}.txt'\n"

		begin
			path = gets.chomp

			unless path =~ /.+(.txt)/
				msg = "\nYour #{file_type} file must be in text (.txt) format. Please 
fix the clues file and restart the game.\n"

				puts msg
				exit
			else
				File.open(path)
			end

		rescue => e
			puts "Oops, looks like you entered an invalid file path! Please try again."
			retry
		end

		path
	end

  def print_running_game
    system "clear"
    puts gameplay_instructions
    render_puzzle
    puts solve_hint

    if puzzle.solved?
      puts "\nYOU SOLVED THE PUZZLE!\n\n"
      exit
    end
  end

	def read_char
    STDIN.raw!

    input = STDIN.getc.chr
    if input == "\e" then
      input << STDIN.read_nonblock(3) rescue nil
      input << STDIN.read_nonblock(2) rescue nil
    end

    STDIN.cooked!

    input
  end

  def render_computer_solution(solved)
    system "clear"
    render_puzzle

    if solved
      puts "\n\nThe computer solved your puzzle! The solution is printed 
above.\n\n"
    else
      puts "\n\nThe computer was unable to solve your puzzle. Its best effort is  
printed above.\n"
    end

    exit
  end

	def render_puzzle
    0.upto(puzzle.width - 1) do |i|
    	0.upto(puzzle.height - 1) do |j|
    		pos = [i, j]

    		unless puzzle.word_positions[pos]
    			print "   ".colorize(background: :black)
    			next
    		end

    		has_cursor = (cursor.position == pos ? true : false)
        current_words = puzzle.word_positions[pos]
    		letter = current_words.first.get_letter(pos)
    		text = (letter ? " #{letter} " : "   ")

    		if has_cursor
          clue_idx = -1
          clue_idx = 0 if pos == (current_words[0].clue[:position] rescue nil)
          clue_idx = 1 if pos == (current_words[1].clue[:position] rescue nil)

          if clue_idx > -1
            text = " #{current_words[clue_idx].clue[:number]} "
          end
          
    			print text.black.colorize(background: :light_cyan)
    		else
    			print text.white.colorize(background: :light_black)
    		end
    	end

    	puts
    end

    puts "\n\nWords remaining: #{puzzle.words_remaining}"
	end

	def solve_hint
		"\n\nFeeling lazy? To have the computer solve your puzzle, enter '$' at any 
time. It bears no responsibility for any incorrect answers entered so far ;)\n"
	end
end
