function createColumnChart(element){
  $(element.target).highcharts({
      chart: {
        type: 'column'
      },
      title: {
        text: element.label
      },
      xAxis: {
        categories: element.categories,
        title: {
          text: null
        }
      },
      yAxis: {
        min: 0,
        title: {
          text: element.label_y_axis,
        }
      },
      plotOptions: {
        column: {
          pointPadding: 0.2,
          borderWidth: 0
        }
      },
      tooltip: {
        headerFormat: '<span style="font-size:10px">{point.key}</span><table>',
        pointFormat: '<tr><td style="color:{series.color};padding:0">{series.name}: </td>' +
            '<td style="padding:0"><b>{point.y}</b></td></tr>',
        footerFormat: '</table>',
        shared: true,
        useHTML: true
      },
      series: element.series
  });
}
