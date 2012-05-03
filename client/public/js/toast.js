(function() {
  var HEIGHT, TIME, lastSlot, toastSlots;

  toastSlots = [false];

  lastSlot = 0;

  HEIGHT = {
    debug: 30,
    user: 50
  };

  TIME = {
    debug: 1500,
    user: 3000
  };

  window.toast = function(msg, type) {
    var add, center, i, k, occupied, offset, slot, _ref;
    if (type == null) type = 'debug';
    slot = -1;
    for (i = 0, _ref = toastSlots.length - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
      k = (i + lastSlot) % toastSlots.length;
      occupied = toastSlots[k];
      if (!occupied) {
        slot = k;
        break;
      } else {

      }
    }
    if (slot === -1) {
      slot = toastSlots.length;
      toastSlots.push(false);
    }
    toastSlots[slot] = true;
    offset = slot * HEIGHT[type];
    lastSlot = slot;
    center = function($el) {
      var left, top;
      $el.css("position", "absolute");
      top = offset + ((($(window).height() - $el.outerHeight()) / 2) + $(window).scrollTop()) + "px";
      left = (($(window).width() - $el.outerWidth()) / 2) + $(window).scrollLeft() + "px";
      $el.css("top", top);
      return $el.css("left", left);
    };
    add = function(className) {
      var $el, goAway, opacity,
        _this = this;
      $el = $("<span>").addClass(className).addClass("" + className + "-" + type);
      $el.html(msg);
      $el.appendTo(document.body);
      center($el);
      opacity = 1;
      if (className === "toast-background") opacity = 0.8;
      $el.animate({
        opacity: opacity
      });
      goAway = function() {
        return $el.fadeOut('slow', function() {
          if (className === "toast-background") return toastSlots[slot] = false;
        });
      };
      return setTimeout(goAway, TIME[type]);
    };
    add("toast-background");
    return add("toast-text");
  };

}).call(this);
