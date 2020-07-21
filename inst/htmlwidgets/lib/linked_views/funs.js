/**
 * Linked Views
 **/

let state = {polys: new Set([]), dimred: new Set([])};


function linked_views(el, width, height, polys, dimred) {
  let svg = d3.select(el)
    .append("svg")
    .attrs({
      id: "svg",
      width: width,
      height: height
    });

  svg.selectAll("g")
    .data(["cells", "scatter", "cellBrush", "scatterBrush"]).enter()
    .append("g")
    .attr("id", (d) => d);

  let scales = getScales(width, height);

  svg.select("#scatter")
    .attrs({transform: `translate(${scales.scatterX.range()[1]}, 10)`});

  initializeCells(svg.select("#cells"), scales, polys);
  initializeScatter(svg.select("#scatter"), scales, dimred);
  addBrush(svg.select("#scatterBrush"), scatterBrushFun, scales, [scales.scatterX.range()[1], 0], "scatterBrush");
  addBrush(svg.select("#cellBrush"), cellBrushFun, scales, [0, 0], "cellBrush");
}

function initializeCells(root, scales, polys) {
  const proj = d3.geoIdentity().fitExtent([[0, 0], [scales.scatterX.range()[1], scales.scatterX.range()[1]]], polys);
  const path = d3.geoPath().projection(proj);

  root.selectAll('path')
    .data(polys.features).enter()
    .append('path')
    .attrs({
      d: path,
      class: 'cellPath',
      fill: (d) => {
        const f = d.properties.tumorYN == 1 ? scales.tumorFill(d.properties.tumorCluster) : scales.immuneFill(d.properties.immuneGroup);
        return f;
      },
      "stroke-width": 0.1
    });
}

function initializeScatter(root, scales, dimred) {
  root.selectAll('circle')
    .data(dimred).enter()
    .append('circle')
    .attrs({
      cx: (d) => scales.scatterX(d.V1),
      cy: (d) => scales.scatterY(d.V2),
      fill: (d) => {
        const f = d.tumorYN == 1 ? scales.tumorFill(d.tumorCluster) : scales.immuneFill(d.immuneGroup);
        return f;
      },
      r: 2,
      stroke: "#0c0c0c",
      "stroke-width": 0.1,
      class: "scatterCircle"
    });
}

function addBrush(el, brushFun, scales, originOffset, brushId) {
  let brush = d3.brush()
      .on("brush", brushFun(scales, originOffset))
      .extent([
        [scales.scatterX.range()[0] + originOffset[0], scales.scatterY.range()[0] + originOffset[1]],
        [scales.scatterX.range()[1] + originOffset[0], scales.scatterY.range()[1] + originOffset[1]]
      ]);

  el.append("g")
    .attr("id", brushId)
    .classed("brush", true)
    .call(brush);
}

function scatterBrushFun(scales, originOffset) {
  return function() {
    let extent = brushExtent(this, [scales.scatterX, scales.scatterY], originOffset);
    // update state.polys
    // rerender
  };
}

function brushExtent(brush, scales, originOffset) {
  let pixelExtent = d3.brushSelection(brush),
      extent = [[0, 0], [0, 0]];

  for (let i = 0; i < pixelExtent.length; i++) {
    for (let j = 0; j < originOffset.length; j++) {
      extent[i][j] = scales[j].invert(pixelExtent[i][j] - originOffset[j]);
    }
  }

  return extent;
}

function cellBrushFun(scales, originOffset) {
  return function() {};
}

function cellOver(data) {
  const curState = new Set([...state.polys, ...state.dimred]);
  curState.add(data.properties.cellLabelInImage);
  updateHighlighted(curState);

  if (d3.event.shiftKey) {
    state.polys.add(data.properties.cellLabelInImage);
  } else if (d3.event.ctrlKey) {
    state.polys.delete(data.properties.cellLabelInImage);
  }
}

function scatterOver(data) {
  const curState = new Set([...state.polys, ...state.dimred]);
  curState.add(data.cellLabelInImage);
  updateHighlighted(curState);

  if (d3.event.shiftKey) {
    state.dimred.add(data.cellLabelInImage);
  } else if (d3.event.ctrlKey) {
    state.dimred.delete(data.cellLabelInImage);
  }
}

function updateHighlighted(curState) {
  d3.select('#scatter')
    .selectAll('.scatterCircle')
    .attrs({
      "stroke-width": (d) => curState.has(d.cellLabelInImage) ? .5 : 0,
      "fill-opacity": (d) => curState.has(d.cellLabelInImage) ? 1 : 0.2
    });

  d3.select('#cells')
    .selectAll('.cellPath')
    .attrs({
      "stroke-width": (d) => curState.has(d.properties.cellLabelInImage) ? 1 : 0.1
    });
}

function getScales(width, height) {
  let immuneCols = ['#8dd3c7','#ffffb3','#bebada','#fb8072','#80b1d3','#fdb462','#b3de69','#fccde5'],
      tumorCols = ['#d9d9d9','#bc80bd','#ccebc5','#ffed6f'];
  let projDims = d3.range(7).map((d) => 'V' + d);

  return {
    tumorFill: d3.scaleOrdinal().domain([4, 7, 10, 17]).range(immuneCols),
    immuneFill: d3.scaleOrdinal().domain([1, 2, 3, 4, 8, 10, 11, 12]).range(tumorCols),
    scatterX: d3.scaleLinear().domain([-5.5, 3.5]).range([0, width / 2]),
    scatterY: d3.scaleLinear().domain([-7, 7]).range([0, height]),
    hmFill: d3.scaleLinear().domain([-2, 0, 2]).range(["white", "grey", "black"])
  };
}
