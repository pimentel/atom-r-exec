{CompositeDisposable, Point, Range} = require 'atom'

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
      description: 'Cursor advances to the next line after ' +
        'sending the current line when there is no selection'
    focusWindow:
      type: 'boolean'
      default: true
      description: 'After code is sent, bring focus to where it was sent'
    notifications:
      type: 'boolean'
      default: true
      description: 'Send notifications if there is an error sending code'

  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace',
      'r-exec:send-command', => @sendCommand()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'r-exec:send-paragraph': => @sendParagraph()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'r-exec:send-function': => @sendFunction()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'r-exec:setwd', => @setWorkingDirectory()

    @subscriptions.add atom.commands.add 'atom-workspace',
      'r-exec:set-chrome', => @setChrome()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'r-exec:set-iterm', => @setIterm()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'r-exec:set-rapp', => @setRApp()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'r-exec:set-safari', => @setSafari()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'r-exec:set-terminal', => @setTerminal()

  deactivate: ->
    @subscriptions.dispose()

  setChrome: ->
    atom.config.set('r-exec.whichApp', apps.chrome)
  setIterm: ->
    atom.config.set('r-exec.whichApp', apps.iterm)
  setRApp: ->
    atom.config.set('r-exec.whichApp', apps.rapp)
  setSafari: ->
    atom.config.set('r-exec.whichApp', apps.safari)
  setTerminal: ->
    atom.config.set('r-exec.whichApp', apps.terminal)


  sendCommand: ->
    whichApp = atom.config.get 'r-exec.whichApp'
    # we store the current position so that we can jump back to it later
    # (if the user wants to)
    currentPosition = atom.workspace.getActiveTextEditor().
      getLastSelection().getScreenRange().end
    selection = @getSelection(whichApp)
    @sendCode(selection.selection, whichApp)

    advancePosition = atom.config.get 'r-exec.advancePosition'
    if advancePosition and not selection.anySelection
      currentPosition.row += 1
      atom.workspace.getActiveTextEditor().
        setCursorScreenPosition(currentPosition)
      atom.workspace.getActiveTextEditor().moveToFirstCharacterOfLine()
    else
      if not selection.anySelection
        atom.workspace.getActiveTextEditor().
          setCursorScreenPosition(currentPosition)

  sendCode: (code, whichApp) ->
    switch whichApp
      when apps.iterm then @iterm(code)
      when apps.rapp then @rapp(code)
      when apps.safari, apps.chrome then @browser(code, whichApp)
      when apps.terminal then @terminal(code)
      else console.error 'r-exec.whichApp "' + whichApp + '" is not supported.'

  getFunctionRange: ->
    # gets the range of the closest function above the cursor.
    # if there is no (proper) function, return false
    editor = atom.workspace.getActiveTextEditor()
    currentPosition = editor.getCursorBufferPosition()
    # search for the simple function that looks something like:
    # label <- function(...) {
    # in case the current function definition is on the current line
    currentPosition.row += 1
    backwardRange = [0, currentPosition]
    funRegex = new
      RegExp(/^[a-zA-Z]+[a-zA-Z0-9_\.]*[\s]*(<-|=)[\s]*(function)[\s]*\(/g)
    # funRegex = new
    #   RegExp(/^[a-zA-Z]+[a-zA-Z0-9_\.]*[\s]*(<-|=)[\s]*(function)[^{]*{/g)
    foundStart = null
    editor.backwardsScanInBufferRange funRegex, backwardRange, (result) ->
      foundStart = result.range
      result.stop()

    if not foundStart?
      console.error "Couldn't find the beginning of the function."
      return null

    # now look for the end
    numberOfLines = editor.getLineCount()
    forwardRange = [foundStart, new Point(numberOfLines + 1, 0)]

    foundEnd = null
    editor.scanInBufferRange /}/g, forwardRange, (result) ->
      if result.range.start.column == 0
        foundEnd = result.range
        result.stop()

    if not foundEnd?
      console.error "Couldn't find the end of the function."
      return null

    # check if cursor is contained in range
    currentPosition.row -= 1
    if foundStart.start.row <= currentPosition.row and
        currentPosition.row <= foundEnd.start.row
      return new Range(foundStart.start, foundEnd.end)
    else
      console.error "Couldn't find a function surrounding the current line."
      return null

  sendFunction: ->
    editor = atom.workspace.getActiveTextEditor()
    whichApp = atom.config.get 'r-exec.whichApp'

    range = @getFunctionRange()
    if range?
      code = editor.getTextInBufferRange(range)
      @sendCode(code, whichApp)
    else
      @conditionalWarning("Couldn't find function.")

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

  conditionalWarning: (message) ->
    notifications = atom.config.get 'r-exec.notifications'
    if notifications
      atom.notifications.addWarning(message)

  sendParagraph: ->
    whichApp = atom.config.get 'r-exec.whichApp'
    editor = atom.workspace.getActiveTextEditor()
    paragraphRange = editor.getCurrentParagraphBufferRange()

    if paragraphRange
      code = editor.getTextInBufferRange(paragraphRange)
      code = code.addSlashes()
      @sendCode(code, whichApp)
      advancePosition = atom.config.get 'r-exec.advancePosition'
      if advancePosition
        editor.moveToBeginningOfNextParagraph()
    else
      console.error 'No paragraph at cursor.'
      @conditionalWarning("No paragraph at cursor.")

  setWorkingDirectory: ->
    # set the current working directory to the directory of
    # where the current file is
    whichApp = atom.config.get 'r-exec.whichApp'

    cwd = atom.workspace.getActiveTextEditor().getPath()
    if not cwd
      console.error 'No current working directory (save the file first).'
      @conditionalWarning('No current working directory (save the file first).')
      return
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

  browser: (selection, whichApp) ->
    # This assumes the active pane item is an console
    atom.clipboard.write selection
    focusWindow = atom.config.get 'r-exec.focusWindow'

    osascript = require 'node-osascript'

    command = []
    whichApp = '"' + whichApp + '"'
    if not focusWindow
      console.warn '"r-exec.focusWindow" is always set when engine is ' +
        'Safari or Google Chrome'
    command.push 'tell application ' + whichApp + ' to activate'
    command.push 'delay 0.5'
    command.push 'tell application "System Events" to tell process ' +
      whichApp + ' ' +
      'to keystroke "v" using {command down}'
    command.push 'delay 0.1'
    command.push 'tell application "System Events" to tell process ' +
      whichApp + ' ' +
      'to keystroke return'
    command = command.join('\n')

    osascript.execute command, (error, result, raw) ->
      if error
        console.error(error)

atom.project.getPaths()
