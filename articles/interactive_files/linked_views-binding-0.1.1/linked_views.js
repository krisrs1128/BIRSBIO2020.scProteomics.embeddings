HTMLWidgets.widget({
  name: "linked_views",
  type: "output",

  factory: function(el, width, height) {
    var instance = {};

    return {
      renderValue: function(x) {
        linked_views(el, width, height, x.polys, HTMLWidgets.dataframeToD3(x.dimred));
      },

      resize: function(width, height) {}

    };
  }
});
