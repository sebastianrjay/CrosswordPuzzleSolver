# ABOUT

This app lets you write your own crossword puzzle and play it, or have the 
computer solve it for you at any time while playing. An example crossword puzzle 
is provided in the `clues.txt` and `layout.txt` files.

# DIRECTIONS

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
empty white square, and '#' represents a black square.
