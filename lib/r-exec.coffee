String::addSlashes = ->
  @replace(/[\\"]/g, "\\$&").replace /\u0000/g, "\\0"

module.exports =
  config:
    whichEngine:
      type: 'string'
      default: 'R.app'
      description: 'Which engine to send commands to. Valid engines are: R.app, Terminal, iTerm, and Safari.'
    advancePosition:
      type: 'boolean'
      default: false
      description: 'If true, the cursor advances to the after sending the current block/line.'
    focusWindow:
      type: 'boolean'
      default: true
      description: 'If true, after code is sent, bring focus to where it was sent.'

  activate: ->
    atom.commands.add 'atom-workspace',
      'r-exec:send-command',  => @sendCommand()
    atom.commands.add 'atom-workspace',
      'r-exec:setwd', => @setWorkingDirectory()

  sendCommand: ->
    # we store the current position so that we can jump back to it later (if the user wants to)
    currentPosition = atom.workspace.getActiveTextEditor().getCursorBufferPosition()
    selection = @getSelection()

    @sendCode(selection.selection)

    advancePosition = atom.config.get 'r-exec.advancePosition'
    if advancePosition
      if not selection.anySelection
        currentPosition.row += 1
      atom.workspace.getActiveTextEditor().setCursorScreenPosition(currentPosition)
      atom.workspace.getActiveTextEditor().moveToFirstCharacterOfLine()
    else
      if not selection.anySelection
        atom.workspace.getActiveTextEditor().setCursorScreenPosition(currentPosition)

  sendCode: (code) ->
    whichEngine = atom.config.get 'r-exec.whichEngine'

    switch whichEngine
      when 'iTerm' then @iterm(code)
      when 'R.app' then  @rapp(code)
      when 'Safari' then  @rstudioserver(code)
      when 'Terminal' then  @terminal(code)
      else console.error 'r-exec.whichEngine "' + whichEngine + '" is not supported.'

  getSelection: ->
    # returns an object with keys:
    # selection: the selection or line at which the cursor is present
    # anySelection: if true, the user made a selection.
    selection = atom.workspace.getActiveTextEditor().getLastSelection()
    anySelection = true

    if selection.getText().addSlashes() == ""
      anySelection = false
      atom.workspace.getActiveTextEditor().selectLinesContainingCursors()
      selection = atom.workspace.getActiveTextEditor().getLastSelection()
    selection = selection.getText().addSlashes()

    {selection: selection, anySelection: anySelection}

  setWorkingDirectory: ->
    # set the current working directory to the directory of where the current file is
    cwd = atom.workspace.getActiveTextEditor().getPath()
    cwd = cwd.substring(0, cwd.lastIndexOf('/'))
    cwd = "setwd(\"" + cwd + "\")"

    @sendCode(cwd.addSlashes())

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

  rstudioserver: (selection) ->
    # This assumes the active pane item is an console
    osascript = require 'node-osascript'

    atom.clipboard.write selection
    focusWindow = atom.config.get 'r-exec.focusWindow'
    command = []
    if not focusWindow
      console.warn '"r-exec.focusWindow" is always set when engine is Safari'
    command.push 'tell application "Safari" to activate'
    command.push 'delay 0.5'
    command.push 'tell application "System Events" to tell process "Safari" ' +\
      'to keystroke "v" using {command down}'
    command.push 'delay 0.1'
    command.push 'tell application "System Events" to tell process "Safari" ' +\
      'to keystroke return'
    command = command.join('\n')

    osascript.execute command, (error, result, raw) ->
      if error
        console.error(error)
      else
        console.log result, raw


atom.project.getPaths()
