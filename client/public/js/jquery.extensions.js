(function() {

  (function($) {
    return $.fn.extend({
      fitToContent: function() {
        return this.each(function(i, text) {
          var adjustedHeight, jTa;
          jTa = jQuery(text);
          adjustedHeight = Math.max(text.scrollHeight, jTa.height()) + 15;
          if (adjustedHeight > text.clientHeight + 15) {
            return jTa.height(adjustedHeight);
          }
        });
      }
    });
  })(jQuery);

}).call(this);
