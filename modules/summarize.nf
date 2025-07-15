process SUMMARIZE {
	publishDir path: "${params.output}/summary", pattern: '*', mode: 'copy'
	input: 
 	 path(metrics)

  output:
   path("*") 

	"""
	SummarizeAssemblyPlot.py ${params.run} 
	"""
}
