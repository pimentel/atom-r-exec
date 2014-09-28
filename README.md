# r-exec

Send R code from Atom to be executed in R.app, Terminal, or a web browser running RStudio Server on Mac OS X.  The current selection is sent or in the case of no selection the current line is sent.

## Installation

`apm install r-exec`

or

Search for `r-exec` within package search in the Settings View.

## Usage

- `cmd-shift-r`: send code to R.app
- `cmd-shift-t`: send code to active Terminal.app window (assuming R is running in the terminal window)
- `cmd-shift-e`: send code to be pasted in active Safari window (assuming this window is RStudio Server)

## Notes

This is very much in an **alpha** state and is a quick hobby project.  It is currently Mac-only because these things are easy to do with AppleScript.  Any help on the Windows or Linux side would be great.

In the R.app case, the working directory in R is set to the Atom project root directory before any command is run.  This is not done in the Terminal or RStudio Server cases because in those cases it is likely that R is running on a different system.

In the RStudio Server case, the solution is pretty clunky - the code is sent to the clipboard and then a paste command is sent to Safari.  But it works.

## TODO

- Make the choice of which R.app to send the code to configurable, based on a project-level configuration variable (sometimes multiple copies of R.app are made so that multiple R GUIs can be running simultaneously for different projects).
- Make which browser to use configurable in the RStudio Server case (currently hard-coded to Safari).
- In RStudio Server case, make sure active window really is RStudio Server before pasting, maybe by checking the  [title](http://www.alfredforum.com/topic/2013-how-to-get-frontmost-tab's-url-and-title-of-various-browsers/).
- Error reporting.
- Support for Windows and Linux.
