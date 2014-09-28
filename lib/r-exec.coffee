String::addSlashes = ->
  @replace(/[\\"']/g, "\\$&").replace /\u0000/g, "\\0"

module.exports =
  activate: ->
    atom.workspaceView.command "r-exec:send-to-r-app", => @rapp()
    atom.workspaceView.command "r-exec:send-to-terminal", => @terminal()
    atom.workspaceView.command "r-exec:send-to-rstudio-server", => @rstudioserver()

  rapp: ->
    # This assumes the active pane item is an editor
    selection = atom.workspace.getActiveEditor().getSelection()
    if selection.getText().addSlashes() == ""
      atom.workspace.getActiveEditor().selectLine()
      selection = atom.workspace.getActiveEditor().getSelection()

    path = atom.project.getPath()
    if(path == undefined)
      path = ""
    else
      path = "setwd(\"" + path + "\")"

    osascript = require 'node-osascript'
    osascript.execute "tell application \"R\" to activate\ntell application \"R\" to cmd setwd\ntell application \"R\" to cmd code", {setwd: path.addSlashes(), code: selection.getText().addSlashes()}, (error, result, raw) ->
      if error
        console.error(error)
      else
        console.log result, raw

  terminal: ->
    # This assumes the active pane item is an editor
    selection = atom.workspace.getActiveEditor().getSelection()
    if selection.getText().addSlashes() == ""
      atom.workspace.getActiveEditor().selectLine()
      selection = atom.workspace.getActiveEditor().getSelection()
    osascript = require 'node-osascript'
    osascript.execute "tell application \"Terminal\" to activate\ntell application \"Terminal\"\ndo script code in window 1\nend tell", {code: selection.getText().addSlashes()}, (error, result, raw) ->
      if error
        console.error(error)
      else
        console.log result, raw

  rstudioserver: ->
    # This assumes the active pane item is an editor
    selection = atom.workspace.getActiveEditor().getSelection()
    if selection.getText().addSlashes() == ""
      atom.workspace.getActiveEditor().selectLine()
      selection = atom.workspace.getActiveEditor().getSelection()
    osascript = require 'node-osascript'
    atom.clipboard.write selection.getText()
    osascript.execute "tell application \"Safari\" to activate\ndelay 0.5\ntell application \"System Events\" to tell process \"Safari\" to keystroke \"v\" using {command down}\ndelay 0.1\ntell application \"System Events\" to tell process \"Safari\" to keystroke return", (error, result, raw) ->
      if error
        console.error(error)
      else
        console.log result, raw


atom.project.getPath()

# tell application "R" to activate
# if (item 2 of theCode) is not "" then tell application "R" to cmd "setwd(\"" & (item 2 of theCode) & "\")"
# tell application "R" to cmd (item 1 of theCode)
