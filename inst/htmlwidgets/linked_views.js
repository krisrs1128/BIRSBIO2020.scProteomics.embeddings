HTMLWidgets.widget({
  name: "linked_views",
  type: "output",

  factory: function(el, width, height) {
    var instance = {};

    return {
      renderValue: function(x) {
        el.innerText = x.message;
        d3.select(el)
          .append("g")
          .attr("id", "thisisatest");
      },

      resize: function(width, height) {}

    };
  }
});
