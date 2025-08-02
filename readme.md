# The brd project
this is the definition of 150 lines of zig code that are held together by duck tape
(what this means for you is that dont use this application/command line tool on something like your companies server)

# What does this do 
welp, great question. It is like a clipboard for the teminal as the name and description suggest but it stores files only, like when you want to move a file somewhere but the temporary directory that you were going to use is not created yet it stores it into ~/.brd-buf/ and it's ready to commit the files somewhere else.

# Usage
there are 3 actions to be used here
1. `brd mv` moves the file into the buffer (deleting the original version but stores a copy somewhere else) **Not Recommended**
2. `brd cp` copies the file into the buffer leaving the original version as it is **Recommended**
3. `brd cmt` commits (pastes) the file into the folder provided

# Example
`bash
brd mv test.txt # copy and save the file to clipboard
cd ..
mkdir test_dir
brd cmt . # move the file from clipboard`

# Notes
1. **DO NOT** use this in some production server (I'm not responsible for what this buggy new project is gonna cause)
2. Make sure that there are exactly 3 prameters (or it wont work) (subject to change)
3. If there is any issues with this tool just drop it in the issues tab
