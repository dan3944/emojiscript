$ = require('jquery')
{CompositeDisposable} = require 'atom'
subscriptions = new CompositeDisposable
cmd = require 'node-cmd'

module.exports =
class EmojiscriptView

  constructor: (serializedState) ->

    editor = atom.workspace.getActivePaneItem()
    active_editor = atom.workspace.getActiveTextEditor(editor)
    file = editor?.buffer.file
    file_path = file?.path

    active_editor.onDidSave( ->
      title = active_editor.getTitle()
      ext = title.split(".")[1]
      path = active_editor.getPath()
      if ext == "emoji"
        cmd.get("cd #{file_path}/../../ && ./transpiler/emojiscript #{path} transpiler/substitutions.txt", (output) ->
          atom.notifications.addSuccess "File #{title} successfully transpiled",
            detail: "Press Cntr+Alt+R to run"
        )
    )

    atom.workspace.onDidStopChangingActivePaneItem( (item) ->
      active_editor = item
      if active_editor
        active_editor.onDidSave( ->
          title = active_editor.getTitle()
          ext = title.split(".")[1]
          path = active_editor.getPath()
          if ext == "emoji"
            cmd.get("cd #{file_path}/../../ && ./transpiler/emojiscript #{path} transpiler/substitutions.txt", (output) ->
              atom.notifications.addSuccess "File #{title} successfully transpiled",
                detail: "Press Cntr+Alt+R to run"
            )
        )
    )

    @emojiPanel = $('<div class="emojiscript">').load("#{file_path}/../../lib/emoji-panel.html", -> (
      emojis = $(@).find('.emoji')
      for emoji in emojis
      	subscriptions.add atom.tooltips.add(emoji, {title: emoji.textContent, delay: {show: 0, hide: 0} })
      	emoji.onclick = ->
        	active_editor.insertText(@textContent)
    ))

  serialize: ->

  destroy: ->
    @emojiPanel.remove()

  getElement: ->
    @emojiPanel
