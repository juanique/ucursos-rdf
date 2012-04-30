toastSlots = [false]
lastSlot = 0

HEIGHT = {
  debug: 30
  user: 50
}

TIME = {
  debug: 1500
  user: 3000
}

window.toast = (msg, type='debug') ->

  slot = -1
  for i in [0..(toastSlots.length-1)]
    k = (i + lastSlot) % toastSlots.length
    occupied = toastSlots[k]
    if not occupied
      slot = k
      break
    else

  if slot == -1
    slot = toastSlots.length
    toastSlots.push false

  toastSlots[slot] = true
  offset = slot * HEIGHT[type]
  lastSlot = slot

  center = ($el) ->
    $el.css("position","absolute")
    top = offset + ((($(window).height() - $el.outerHeight()) / 2) + $(window).scrollTop()) + "px"
    left = (($(window).width() - $el.outerWidth()) / 2) + $(window).scrollLeft() + "px"

    $el.css("top", top)
    $el.css("left", left)

  add = (className) ->
    $el = $("<span>").addClass(className).addClass("#{className}-#{type}")
    $el.html msg
    $el.appendTo document.body
    center $el

    opacity = 1
    opacity = 0.8 if className == "toast-background"

    $el.animate {opacity: opacity}

    goAway = =>
      $el.fadeOut 'slow', =>
        if className == "toast-background"
          toastSlots[slot] = false

    setTimeout goAway, TIME[type]

  add "toast-background"
  add "toast-text"
