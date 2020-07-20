
function linked_views(el, width, height, polys, dimred) {
  console.log("linkedviews being called")
  let svg = d3.select(el)
    .append("svg")
    .attrs({
      width: width,
      height: height
    });

  d3.select(el)
    .append("g")
    .attr("id", "test");
}
