/**
 * Linked Views
 **/

let state = {cells: new Set([]), hm: new Set([])};


function linked_views(el, width, height, polys, dimred) {
  d3.select(el)
    .append("svg")
    .attrs({
      id: "svg",
      width: width,
      height: height
    });

  d3.select(el)
    .select("#svg")
    .selectAll("g")
    .data(["cells", "scatter"]).enter()
    .append("g")
    .attr("id", (d) => d);

  let scales = getScales(width, height);

  d3.select(el)
    .select("#scatter")
    .attrs({
      transform: `translate(${scales.scatterX.range()[1]}, 10)`
    });

  initializeCells(d3.select(el).select("#cells"), scales, polys);
  initializeScatter(d3.select(el).select("#scatter"), scales, dimred);
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
    })
    .on("mouseover", cellOver);
}

function initializeScatter(root, scales, dimred) {
  console.log(dimred)
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
    })
    .on("mouseover", scatterOver);
}

function cellOver(data) {
  const curState = new Set([...state.cells, ...state.hm]);
  curState.add(data.properties.cellLabelInImage);
  updateHighlighted(curState);

  if (d3.event.shiftKey) {
    state.cells.add(data.properties.cellLabelInImage);
  } else if (d3.event.ctrlKey) {
    state.cells.delete(data.properties.cellLabelInImage);
  }
}

function scatterOver(data) {
  const curState = new Set([...state.cells, ...state.hm]);
  curState.add(data.cellLabelInImage);
  updateHighlighted(curState);

  if (d3.event.shiftKey) {
    state.hm.add(data.cellLabelInImage);
  } else if (d3.event.ctrlKey) {
    state.hm.delete(data.cellLabelInImage);
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
