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
      default: false
      description: 'If true, after code is sent, bring focus to where it was sent.'

  activate: ->
    atom.commands.add 'atom-workspace',
      'r-exec:send-to-r-app', => @rapp()
    atom.commands.add 'atom-workspace',
      'r-exec:send-to-terminal', => @terminal()
    atom.commands.add 'atom-workspace',
      'r-exec:send-to-rstudio-server', => @rstudioserver()
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
    console.log 'r-exec.whichEngine: ', whichEngine

    switch whichEngine
      when 'R.app' then  @rapp(code)
      #when 'Safari' then  @rstudioserver(code)
      when 'Terminal' then  @terminal(code)
      else console.error('currently unsupported')

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
    console.log 'before: ', selection.getText()
    selection = selection.getText().addSlashes()
    console.log 'after: ', selection

    {selection: selection, anySelection: anySelection}

  setWorkingDirectory: ->
    # set the current working directory to the directory of where the current file is
    cwd = atom.workspace.getActiveTextEditor().getPath()
    cwd = cwd.substring(0, cwd.lastIndexOf('/'))
    cwd = "setwd(\"" + cwd + "\")"

    @sendCode(cwd.addSlashes())

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

  terminal: (selection)->
    # This assumes the active pane item is an editor
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

  rstudioserver: ->
    # This assumes the active pane item is an editor
    selection = atom.workspace.getActiveTextEditor().getLastSelection()
    if selection.getText().addSlashes() == ""
      atom.workspace.getActiveTextEditor().selectLinesContainingCursors()
      selection = atom.workspace.getActiveTextEditor().getLastSelection()
    osascript = require 'node-osascript'
    atom.clipboard.write selection.getText()
    osascript.execute "tell application \"Safari\" to activate\ndelay 0.5\ntell application \"System Events\" to tell process \"Safari\" to keystroke \"v\" using {command down}\ndelay 0.1\ntell application \"System Events\" to tell process \"Safari\" to keystroke return", (error, result, raw) ->
      if error
        console.error(error)
      else
        console.log result, raw


atom.project.getPaths()

# tell application "R" to activate
# if (item 2 of theCode) is not "" then tell application "R" to cmd "setwd(\"" & (item 2 of theCode) & "\")"
# tell application "R" to cmd (item 1 of theCode)
