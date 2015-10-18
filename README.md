# r-exec

Send R code from Atom to be executed in R.app, Terminal, iTerm, or a web browser running RStudio Server on Mac OS X.  The current selection is sent or in the case of no selection the current line is sent.

## Installation

`apm install r-exec`

or

Search for `r-exec` within package search in the Settings View.

## Configuration

### Keybindings

While `cmd-enter` is bound to sending code in the package, it is also annoyingly bound to entering a new line by default in atom.
In order to make it work, you must add the following binding in `~/.atom/keymap.cson`:

```javascript
'atom-workspace atom-text-editor':
  'cmd-enter': 'r-exec:send-command'
```

### Behavior

All configuration can be done in the settings panel. Alternatively, you can edit your configuration file as noted below.

In your global configuration file (`~/.atom/init.coffee`), you may set the following variables:

- `r-exec.whichApp` which R engine to use. Valid engines are:
  - `R.app`: the default (the R GUI)
  - `iTerm` or `Terminal`: Assumes the currently active terminal has R running
  - `Safari` or `Google Chrome`: assumes the currently active tab has an active RStudio session running, with the console active
- `r-exec.advancePosition`
  - if `true`, go to the after running the current line
  - if `false`, leave the cursor where it currently is
- `r-exec.focusWindow`
  - if `true`, focus the window before sending code
  - if `false`, send the code in the background and stay focused on Atom. This is not possible when sending code to a browser

The default configuration looks like this:

```javascript
atom.config.set('r-exec.whichApp', 'R.app')
atom.config.set('r-exec.advancePosition', false)
atom.config.set('r-exec.focusWindow', true)
```

## Usage

- `cmd-enter`: send code to configured engine (`r-exec:whichEngine`)
- `cmd-shift-e`: change to current working directory of current file

## Notes

This is very much in an **alpha** state and is a quick hobby project.  It is currently Mac-only because these things are easy to do with AppleScript.  Any help on the Windows or Linux side would be great.

In the RStudio Server case, the solution is pretty clunky - the code is sent to the clipboard and then a paste command is sent to Safari.  But it works.

## TODO

- Make the choice of which R.app to send the code to configurable, based on a project-level configuration variable (sometimes multiple copies of R.app are made so that multiple R GUIs can be running simultaneously for different projects).
- In RStudio Server case, make sure active window really is RStudio Server before pasting, maybe by checking the  [title](http://www.alfredforum.com/topic/2013-how-to-get-frontmost-tab's-url-and-title-of-various-browsers/).
- Error reporting.
- Support for Windows and Linux.
