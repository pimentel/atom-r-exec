String::addSlashes = ->
  @replace(/[\\"]/g, "\\$&").replace /\u0000/g, "\\0"

apps =
  chrome: 'Google Chrome'
  iterm: 'iTerm'
  rapp: 'R.app'
  safari: 'Safari'
  terminal: 'Terminal'

module.exports =
  config:
    whichApp:
      type: 'string'
      enum: [apps.chrome, apps.iterm, apps.rapp, apps.safari, apps.terminal]
      default: apps.rapp
      description: 'Which application to send code to'
    advancePosition:
      type: 'boolean'
      default: false
      description: 'If true, the cursor advances to the next line after sending the current line when there is no selection'
    focusWindow:
      type: 'boolean'
      default: true
      description: 'If true, after code is sent, bring focus to where it was sent'

  activate: ->
    atom.commands.add 'atom-workspace',
      'r-exec:send-command', => @sendCommand()
    atom.commands.add 'atom-workspace',
      'r-exec:setwd', => @setWorkingDirectory()

  sendCommand: ->
    whichApp = atom.config.get 'r-exec.whichApp'
    # we store the current position so that we can jump back to it later (if the user wants to)
    currentPosition = atom.workspace.getActiveTextEditor().getLastSelection().getScreenRange().end
    selection = @getSelection(whichApp)
    @sendCode(selection.selection, whichApp)

    advancePosition = atom.config.get 'r-exec.advancePosition'
    if advancePosition and not selection.anySelection
      currentPosition.row += 1
      atom.workspace.getActiveTextEditor().setCursorScreenPosition(currentPosition)
      atom.workspace.getActiveTextEditor().moveToFirstCharacterOfLine()
    else
      if not selection.anySelection
        atom.workspace.getActiveTextEditor().setCursorScreenPosition(currentPosition)

  sendCode: (code, whichApp) ->
    switch whichApp
      when apps.iterm then @iterm(code)
      when apps.rapp then @rapp(code)
      when apps.safari, apps.chrome then @browser(code, whichApp)
      when apps.terminal then @terminal(code)
      else console.error 'r-exec.whichApp "' + whichApp + '" is not supported.'

  getSelection: (whichApp) ->
    # returns an object with keys:
    # selection: the selection or line at which the cursor is present
    # anySelection: if true, the user made a selection.
    selection = atom.workspace.getActiveTextEditor().getLastSelection()
    anySelection = true

    if selection.getText().addSlashes() == ""
      anySelection = false
      atom.workspace.getActiveTextEditor().selectLinesContainingCursors()
      selection = atom.workspace.getActiveTextEditor().getLastSelection()
    selection = selection.getText()
    if not (whichApp == apps.chrome or whichApp == apps.safari)
      selection = selection.addSlashes()

    {selection: selection, anySelection: anySelection}

  setWorkingDirectory: ->
    # set the current working directory to the directory of where the current file is
    whichApp = atom.config.get 'r-exec.whichApp'

    cwd = atom.workspace.getActiveTextEditor().getPath()
    cwd = cwd.substring(0, cwd.lastIndexOf('/'))
    cwd = "setwd(\"" + cwd + "\")"

    @sendCode(cwd.addSlashes(), whichApp)

  iterm: (selection) ->
    # This assumes the active pane item is an console
    osascript = require 'node-osascript'
    command = []
    focusWindow = atom.config.get 'r-exec.focusWindow'
    if focusWindow
      command.push 'tell application "iTerm" to activate'
    command.push 'tell application "iTerm"'
    command.push '  tell the current terminal'
    command.push '    activate current session'
    command.push '    tell the last session'
    command.push '      write text code'
    command.push '    end tell'
    command.push '  end tell'
    command.push 'end tell'
    command = command.join('\n')

    osascript.execute command, {code: selection}, (error, result, raw) ->
      if error
        console.error(error)
      else
        console.log result, raw

  rapp: (selection) ->
    osascript = require 'node-osascript'
    command = []
    focusWindow = atom.config.get 'r-exec.focusWindow'
    if focusWindow
      command.push 'tell application "R" to activate'
    command.push 'tell application "R" to cmd code'
    command = command.join('\n')

    osascript.execute command, {code: selection}, (error, result, raw) ->
      if error
        console.error(error)
      else
        console.log result, raw

  terminal: (selection) ->
    # This assumes the active pane item is an console
    osascript = require 'node-osascript'
    command = []
    focusWindow = atom.config.get 'r-exec.focusWindow'
    if focusWindow
      command.push 'tell application "Terminal" to activate'
    command.push 'tell application "Terminal"'
    command.push 'do script code in window 1'
    command.push 'end tell'
    command = command.join('\n')

    osascript.execute command, {code: selection}, (error, result, raw) ->
      if error
        console.error(error)
      else
        console.log result, raw

  browser: (selection, whichApp) ->
    # This assumes the active pane item is an console
    atom.clipboard.write selection
    focusWindow = atom.config.get 'r-exec.focusWindow'

    osascript = require 'node-osascript'

    command = []
    whichApp = '"' + whichApp + '"'
    if not focusWindow
      console.warn '"r-exec.focusWindow" is always set when engine is Safari or Google Chrome'
    command.push 'tell application ' + whichApp + ' to activate'
    command.push 'delay 0.5'
    command.push 'tell application "System Events" to tell process ' + whichApp + ' ' +\
      'to keystroke "v" using {command down}'
    command.push 'delay 0.1'
    command.push 'tell application "System Events" to tell process ' + whichApp + ' ' +\
      'to keystroke return'
    command = command.join('\n')

    osascript.execute command, (error, result, raw) ->
      if error
        console.error(error)
      else
        console.log result, raw

atom.project.getPaths()
