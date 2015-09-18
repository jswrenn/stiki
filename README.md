# Stiki - The Static Wiki
The premise:
 - Files are articles
 - Folders are categories

## Installation
Besides racket, Stiki has three dependencies. 

### find
To speed rendering up, Stiki uses the unix utility `find` rather than Racket's filesystem procedures.

### Sugar
```sh
raco pkg install sugar
```

### Markdown
```sh
raco pkg install markdown
```

If you want to allow links with spaces in them, use a fork of Markdown
```sh
raco pkg install https://github.com/jswrenn/markdown.git
```

## Usage
```sh
racket -l stiki/main [SOURCE-DIRECTORY] [DEST-DIRECTORY] [EDIT-URL-FRAGMENT] [HISTORY-URL-FRAGMENT]
```
The EDIT-URL-FRAGMENT and HISTORY-URL-FRAGMENTS the partial links for your wiki's online git hosting's edit and history pages for a file.

Github's integrated editor for this readme is `https://github.com/jswrenn/markdown/blob/master/README.md`. 
The fragment you would pass to Stiki would be `https://github.com/jswrenn/markdown/edit/master/`


## Customization
Just modify the source code to your liking. There's about 100 important lines of Racket, with another 100 lines of useful path utilities for making writing templates easier.
