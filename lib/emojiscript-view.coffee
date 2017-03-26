$ = require('jquery')
{CompositeDisposable} = require 'atom'
subscriptions = new CompositeDisposable

module.exports =
class EmojiscriptView

  constructor: (serializedState) ->

    workspace = atom.workspace
    editor = workspace.getActivePaneItem()
    file = editor?.buffer.file
    filePath = file?.path
    emojis = null
    editor = atom.workspace.getActiveTextEditor(editor)

    @element = $('<div class="emojiscript">').load("#{filePath}/../../lib/emoji-panel.html", -> (
      emojis = $(@).find('.emoji')
      for emoji in emojis
      	subscriptions.add atom.tooltips.add(emoji, {title: emoji.textContent, delay: {show: 0, hide: 0} })
      	emoji.onclick = ->
        	editor.insertText(@textContent) 
    ))

    # atom.workspace.observeTextEditors (editor) ->
    #   editor.insertText('Hello World')


  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
