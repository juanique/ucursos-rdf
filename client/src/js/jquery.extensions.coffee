(($) ->
  $.fn.extend fitToContent: ->
    @each (i, text) ->
      jTa = jQuery(text)
      adjustedHeight = Math.max(text.scrollHeight, jTa.height()) + 15
      jTa.height adjustedHeight  if adjustedHeight > text.clientHeight + 15
) jQuery
