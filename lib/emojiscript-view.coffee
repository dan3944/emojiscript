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
    file_title = active_editor.getTitle()

    @emojiPanel = $('<div class="emojiscript">').load("#{file_path}/../../lib/emoji-panel.html", -> (
      emojis = $(@).find('.emoji')
      for emoji in emojis
      	subscriptions.add atom.tooltips.add(emoji, {title: emoji.textContent, delay: {show: 0, hide: 0} })
      	emoji.onclick = ->
        	active_editor.insertText(@textContent)
    ))

    atom.workspace.onDidStopChangingActivePaneItem( (item) ->
      # console.log item
      active_editor = item
    )
    # @active_editor = atom.workspace.getActiveTextEditor(@editor)
    # console.log @active_editor.getTitle()

    active_editor.onDidSave( ->
      cmd.run("./transpiler/emojiscript #{file_path} transpiler/substitutions.txt")
      console.log "File #{file_title} transpiled"
    )

  serialize: ->

  destroy: ->
    @emojiPanel.remove()

  getElement: ->
    @emojiPanel
