process SUMMARIZE {
	publishDir path: "${params.output}/summary", pattern: '*', mode: 'copy'
	input: 
 	 path(metrics)

  output:
   path("*") 

	"""
	SummarizeAssembly.py ${params.run} 
	"""
}
