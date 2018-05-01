#!/usr/bin/env nextflow

// Pipeline for analyzing barseq data to counts. 

// To run you need the nextflow program. You can use the one at
//       /home/dhm267/nextflow
// or you can get your own by running the super-sketch command:
//       curl -s https://get.nextflow.io | bash
// Then you run something like:
//       ~/nextflow run main.nf
//   depending on where those two files are.

// Here's the easily tweakable parameters:

email_address = 'dchmiller@gmail.com'
// The input gzipped fastq. 
gzipped_fastq = Channel.fromPath("/scratch/cgsb/gencore/out/Gresham/2017-04-14_AVA3A/1/000000000-AVA3A_l01n01.3310000008a5cf.fastq.gz")
// The sample index file
sample_index = Channel.fromPath("sampleBarcodesRobinson2014.txt")
// The strain index file
strain_index = Channel.fromPath("nislow_revised.txt")
// How many different mismatches to try
mismatches_to_try = [0,1,2,3]

// If you want to edit more, check out the nextflow documentation.
// I use the single quoted shell blocks because it makes it clear
// what's a !{nextflow_variable} and a ${shell_variable}. Most 
// documentation doesn't use that yet.

// This is making a directory for the outputs and reports
file("./out").mkdirs()
file("./reports").mkdirs()

// This process gunzips everything into plain fastq
process gunzip {
  input: file fgz from gzipped_fastq
  output: file "fastq" into fastq
  shell: 
    '''
    zcat !{fgz} > "fastq"
    '''
}

// This one actually launches out to slurm the barnone runs
process barnone {
  publishDir "out", mode: 'copy'
  input:
    file fastq
    file sample_index
    file strain_index
    each MM from mismatches_to_try
  output:
// rewrite as set
    file "barnone_output_${MM}.counts" into result_counts
    file "barnone_output_${MM}.mismatch" into result_mismatch
    file "barnone_output_${MM}.revised" into result_revised
  shell: 
    '''
    module purge
    module load barnone/intel/20170501
    BarNone -f fastq \
      --multiplexfile !{sample_index} \
      --multiplexstart 1 --multiplexlength 5 \
      --tagstart 18 --taglength 3 --start 9 \
      --mismatches !{MM} \
      --mismatchfile barnone_output_!{MM}.mismatch \
      --revisedcatalog barnone_output_!{MM}.revised \
      -p 500000 \
      !{sample_fastq} \
      barnone_output_!{MM}.counts \
      !{strain_index} 
    '''
}

// Special trigger for `onComplete`. I copied this from documentation.
// Some predefined variables. It somehow mails it. Cool.
workflow.onComplete {
  println "Pipeline completed at: $workflow.complete"
  println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"

  def subject = 'barnone run'
  def recipient = email_address

  ['mail', '-s', subject, recipient].execute() << """

  Pipeline execution summary
  ---------------------------
  Completed at: ${workflow.complete}
  Duration    : ${workflow.duration}
  Success     : ${workflow.success}
  workDir     : ${workflow.workDir}
  exit status : ${workflow.exitStatus}
  Error report: ${workflow.errorReport ?: '-'}
  """
}

//#!/usr/bin/env nextflow
//
//input_fastqs = Channel.fromPath("data/*fq")
//file("./tmp").mkdirs()
//
//process read_input_fastq {
//  input:
//    file in_fq from input_fastqs
//  output:
//    set val(in_fq), file("catted") into z
//  shell:
//    """
//    cat ${in_fq} > catted
//    """
//}
//
//process collase_catted {
//  publishDir  "tmp", mode: 'copy'
//  input:
//    set name, catted from z
//  output: 
//    file "${name}" into finalout
//  shell:
//    """
//    cat ${catted} > ${name}
//    """
//}


//grep 'Note=Dubious' ../ref/S288C_reference_genome_R64-2-1_20150113/saccharomyces_cerevisiae_R64-2-1_20150113.gff > tmp/dubious_orfs.gff
//grep -v '#' ../ref/S288C_reference_genome_R64-2-1_20150113/saccharomyces_cerevisiae_R64-2-1_20150113.gff | grep -v 'Note=Dubious' | grep 'gene' > tmp/notdubious_orfs.gff
//bedtools slop -b 200 -i tmp/notdubious_orfs.gff -g ../ref/S288C_reference_genome_R64-2-1_20150113/saccharomyces_cerevisiae_R64-2-1_20150113.fasta.fai > tmp/notdubious_expanded_orfs.gff 
//bedtools subtract -a tmp/dubious_orfs.gff -b tmp/notdubious_expanded_orfs.gff > tmp/dorfs_no_overlap.gff
//grep -o 'ID=[^;]\+;' tmp/dorfs_no_overlap.gff | sed 's/ID=//g' | sed 's/;//' > tmp/dorfs_no_overlap_list.txt
//
//module purge
//module load ${BARNONE}
//
//BarNone -f fastq \
//  --multiplexfile ${DATA}/sampleBarcodesRobinson2014.txt \
//  --multiplexstart 1 --multiplexlength 5 \
//  --tagstart 18 --taglength 3 --start 9 \
//  --mismatches numberMismatches,recommend_0,1,2 \
//  --mismatchfile ${BASENAME}.barnone_${j}.mismatches \
//  --revisedcatalog ${BASENAME}.barnone_${j}.revised \
//  -p 500000 \
//  input_fastq \
//  output_counts.txt \
//  strainBarcodesNislowRevision.txt
//



