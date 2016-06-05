## 0.3.5 - Support for iTerm2 3.0.0 ([@pimentel](https://github.com/pimentel))
- iTerm2 3.0.0 now supported under mode `iTerm2`. Older versions of iTerm2 are supported under mode `iTerm` due to a recent API change.

## 0.3.4 - Fix multiple bugs, re-factor ([@pimentel](https://github.com/pimentel))
- Fix bug when trying to send current line at the end of the file
- Skip comments when advancing lines with `cmd-enter`
- Skip comments when advancing paragraphs

## 0.3.3 - Send knitr block ([@pimentel](https://github.com/pimentel))
- Allow user to send a RMarkdown block
- When sending to server, if the title does not contain 'RStudio', print a error
- When using `advancePosition`, if sending the current line, advance to the next non-empty line (rather than simply the next line)

## 0.3.1 - Send function or paragraph ([@pimentel](https://github.com/pimentel))
- Allow user to send function or paragraph
- Add configuration allowing notifications
- Add menu items allowing user to change destination application

## 0.3.0 - Major re-factoring ([@pimentel](https://github.com/pimentel))
- Allow user to send code by typing `cmd-enter`
- Allow user to configure which application to send code to
- Add support for Google Chrome and iTerm
- Change behavior of `r-exec:setwd`
- Fix bug when sending code with single quotes

## 0.1.0 - First Release ([@hafen](https://github.com/hafen))
- Simple support for sending R code to be executed in R.app, Terminal, or a web browser running RStudio Server
