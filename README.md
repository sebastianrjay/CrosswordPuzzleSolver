# About

This command line app lets you write your own crossword puzzle and play it, or 
have the computer solve it for you at any time while playing. An example 
crossword puzzle is provided in the `clues.txt` and `layout.txt` files.

I originally wrote this app in 3 days as a coding challenge submission for one 
of the major tech companies, and it landed me the on-site interview. While 
candidates were forbidden from posting the assignment itself publicly, its 
directions explicitly instructed us to post our solutions on Github.

NOTE: If you are a representative of the unnamed tech company above and would 
like me to remove this app from public display on my Github profile, please 
write to me at sebastianrjay@gmail.com. I'm surprised at the instructions to 
post our solutions publicly, given that this particular assignment may be used 
in other interview processes.

# Description

The app can be played as a regular crossword puzzle game, where the user enters solutions. It can also solve the puzzle at any time, as described in the directions below.

It solves any crossword puzzle by scraping [crosswordgiant.com](http://www.crosswordgiant.com) and [crosswordheaven.com](http://crosswordheaven.com/) with [RESTClient](https://github.com/rest-client/rest-client). To get a word's solution list from each server, it sends the clue for each word in the puzzle to the server's clue search endpoint, and parses the returned HTML with [Nokogiri](https://github.com/sparklemotion/nokogiri) to get that word's potential solutions. It then uses a greedy algorithm to first fill in each word with the least number of valid solutions, to avoid inserting an incorrect word and thus maintaining the puzzle's solvability.

# Directions

Assuming you've [installed Ruby](https://github.com/rbenv/rbenv) and then 
installed bundler via `gem install bundler`, navigate to the 
CrosswordPuzzleSolver root directory in the terminal and enter `bundle install`. 

To run the app, enter `ruby lib/game.rb` from the CrosswordPuzzleSolver root 
directory. Follow the on-screen directions to solve the puzzle yourself, or have 
the computer solve your puzzle at any time. (To have the computer solve the 
puzzle, enter '$' at any time while playing.)

To create your own puzzle with a different layout and clues, simply create 
additional clues and layout .txt files, saved under whichever name you want in 
the CrosswordPuzzleSolver root directory. The puzzle can be of any dimensions, 
but clues must be specified by a single 0-9 or A-Z character. '.' represents an 
empty white square, and '#' represents a black square. In your clues file, be 
sure to create separate sections for Across and Down clues, as shown in the 
example file.

# Data Structures, Runtime and Space Complexity Analysis

As part of the coding challenge reference above, I wrote and submitted the analysis below with my code on 22 December 2015. The space complexity analysis is a bit sparse because I only had 2 hours to write it before the submission deadline.

*Note: For the duration of this paper, `h` refers to puzzle height, `w` refers to puzzle width, `n` refers to the number of words in the puzzle, `L` refers to word length, and `L_average` refers to average word length.*

*The general trend here is that we can minimize runtime by using hashes. We trade a bit of extra space for faster runtime.*

## Data Structures and Runtime Analysis

### Word (`word.rb` class and `word_solution_getter.rb` module)

* Stores its letter positions in a hash, where the key is an array specifying a position on the puzzle grid. Thus, setting or deleting a letter and its position runs in `O(1)` time.
* Stores and updates a `@letters_remaining counter`, so that we can check if a word is solved in `O(1)` time.
* Stores `@intersection_positions`, an array of positions where a Word intersects with other Words on the puzzle grid. This array is instantiated in `O(L)` time, since looking up the number of words at each letter position in the puzzle takes `O(1)` time.
* The `Word#to_regex` method constructs a regex in `O(L)` time based on the word’s current letters. The purpose of the regex is to filter database clue search results against the word’s current letters, e.g. in `Word#valid_solutions`.
* Word instantiation takes `O(L)` time, since saving a letter position to @letter_positions takes `O(1)` time.
* `Word#web_solutions` is slow and runs in `O(number_of_word_solutions * L)` time, but in each word, it’s only called once for each database because we cache the results in a private `attr_accessor`. Its slowness is solely due to waiting for a server response.
* `Word#valid_solutions` runs in `O(number_of_word_solutions * L)` time, since checking each cached web solution against the regex takes `O(L)` time. This runs much faster than `Word#web_solutions`, since we don’t have to wait for a server response. We don’t cache its results because as other words are updated in the puzzle, letters in this word may be updated, thus changing the valid solutions for this word.
* A clue hash is saved to each word, enabling `O(1)` lookup of clue text, clue number and clue start position for a fetched word. Since looking up a word in the puzzle by position takes `O(1)` time (as explained below), looking up a clue and its info by puzzle grid position takes `O(1)` time.

### CrosswordPuzzle (`crossword_puzzle.rb` class, `crossword_file_parser.rb` module, and `crossword_solver.rb` module)

* Stores word positions in a hash, where the key is an array specifying a position on the puzzle grid. Thus, looking up a word or words by grid position takes `O(1)` time, since there can be no more than two words saved to each position.
* Stores a `Set` of all the words. Thus, we can check if we’ve already saved a word in `O(1)` time when instantiating the puzzle, and we have a handy way to iterate through words without hitting duplicates in `CrosswordPuzzle#solve!`
* Stores and updates a `@words_remaining counter`, so that we can check if the puzzle is solved in `O(1)` time. The counter is updated every time we solve a word, and every time we render a solved word unsolved.
* CrosswordPuzzle instantiation takes `O(h * w)` time. We iterate through all positions in the puzzle grid, which takes `O(h * w)` time. We cache unsaved word positions in an array, and instantiate a new word from them once we hit the end of a word in the puzzle grid. We never iterate through a single puzzle row or column more than once, and repeat a given subset of a puzzle row or column at most once when instantiating a word.
* Setting a letter at a grid position always updates both words in that position in `O(1)` time, since we are simply saving values to at most two hashes.
* Rendering CrosswordPuzzle takes `O(h * w)` time. We must iterate through each position. For each position, we look up the words at that position. From the first word (and there are no more than 2 words per position), we look up the letter and clue number corresponding to the position in `O(1)` time.

## Space Complexity Analysis

* I’ve chosen to minimize runtime at the possible expense of space. If I’m not mistaken, storing the puzzle and letters takes `O(h * w)` space. Storing the puzzle and words, and positions in each word, should also take `O(h * w)` space because there are no more than two words per grid position, and there are h * w grid positions. Each word stores positions that we’ve already stored in the puzzle. Words are stored in `O(n * L_average)` space. `O(n * L_average)` and `O(h * w)` should be roughly equivalent since there are no more than two words per position, and each puzzle position is stored in at most two words.

## `CrosswordPuzzle#solve!` Algorithm Runtime Analysis

*Note: a better explanation of the algorithm can be found in the code comments in `crossword_solver.rb`.*

* If I’m not mistaken, `CrosswordSolver#solve!` runtime is `O(s_average * n * L_average)`, where `s` is the average number of web solutions for a given word, and `s_average` is the average number of solutions per word, for all words. In practice, the algorithm runs in `O(n * L_average)` time since we never check more than 5 web solutions per word. (Matching against the regex takes `O(L)` time.)
