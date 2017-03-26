EmojiscriptView = require './emojiscript-view'
{CompositeDisposable} = require 'atom'

module.exports = Emojiscript =
  emojiscriptView: null
  emojiPanel: null
  subscriptions: null

  activate: (state) ->
    @emojiscriptView = new EmojiscriptView(state.emojiscriptViewState)
    @emojiPanel = atom.workspace.addBottomPanel(item: @emojiscriptView.getElement(), visible: false, priority: 100)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'emojiscript:toggle': => @toggle()

  deactivate: ->
    @emojiPanel.destroy()
    @subscriptions.dispose()
    @emojiscriptView.destroy()

  serialize: ->
    emojiscriptViewState: @emojiscriptView.serialize()

  toggle: ->
    if @emojiPanel.isVisible()
      @emojiPanel.hide()
    else
      @emojiPanel.show()
