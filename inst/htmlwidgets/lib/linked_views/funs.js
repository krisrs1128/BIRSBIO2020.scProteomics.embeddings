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

  // logic for where the brushes should go
  let extent = [[scales.scatterX.range()[0], scales.scatterY.range()[0]],
                [scales.scatterX.range()[1], scales.scatterY.range()[1]]];
  let brushFun = cellBrushFun(scales, [0, 0], polys);
  addBrush(svg.select("#cellBrush"), brushFun, extent, "cellBrush");

  extent = [[scales.scatterX.range()[0] + scales.scatterX.range()[1], scales.scatterY.range()[0]],
            [2 * scales.scatterX.range()[1], scales.scatterY.range()[1]]];
  brushFun = scatterBrushFun(scales, [scales.scatterX.range()[1], 0], dimred),
  addBrush(svg.select("#scatterBrush"),  brushFun, extent, "scatterBrush");
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

function addBrush(el, brushFun, extent, brushId) {
  let brush = d3.brush()
      .on("brush", brushFun)
      .extent(extent);

  el.append("g")
    .attr("id", brushId)
    .classed("brush", true)
    .call(brush);
}

function scatterBrushFun(scales, originOffset, dimred) {
  return function() {
    let extent = brushExtent(this, [scales.scatterX, scales.scatterY], originOffset);

    state.polys = new Set([]);
    for (var i = 0; i < dimred.length; i++) {
      if (dimred[i].V1 > extent[0][0] && dimred[i].V1 < extent[1][0]) {
        if (dimred[i].V2 > extent[0][1] && dimred[i].V2 < extent[1][1]) {
          state.polys.add(dimred[i].cellLabelInImage);
        }
      }
    }

    updateHighlighted(state);
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

function cellBrushFun(scales, originOffset, polys) {
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
  curState = new Set([...curState.polys, ...curState.dimred]);

  d3.select('#scatter')
    .selectAll('.scatterCircle')
    .attrs({
      "stroke-width": (d) => curState.has(d.cellLabelInImage) ? .5 : 0,
      "fill-opacity": (d) => curState.has(d.cellLabelInImage) ? 1 : 0.2
    });

  d3.select('#cells')
    .selectAll('.cellPath')
    .attrs({
      "fill-opacity": (d) => { return curState.has(d.properties.cellLabelInImage) ? 1 : 0.1}
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
