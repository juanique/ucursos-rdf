RegExp.escape = (text) -> text.replace /[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"

require [], () ->

  $ ->
    console.log "Document Loaded"
    magic = new MagicTextArea $("input")
    magic.addListener
      tagPlaced: (span) ->

    magic.addInlineSuggest
      trigger: 'NONE'
      refreshList: (word, list) ->
        toast word

        if word.length < 3
          list.setOptions []
        else
          list.setOptions ['CC10', 'Ingenieria', 'Algoritmos']
      parseCaretWord: (word, value) ->
        return {
          span: $("<span>").html(value).addClass("entity")[0]
          tag: $("<div>").attr("title", word)[0]
        }
