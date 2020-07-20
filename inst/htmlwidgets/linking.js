/* Linking Abstract and Physical Maps */

HTMLWidgets.widget({

  name: 'linked_views',
  type: 'output',

  factory: function(el, width, height) {
    return {
      renderValue: function(x) {
	      linked_views(el, width, height, x[0], x[1]);
      },

      resize: function(width, height) {}
    };
  }
});
