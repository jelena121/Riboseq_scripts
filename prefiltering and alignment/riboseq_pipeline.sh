#rename files
#requires the file naming_scheme.txt as input
# 1st column = old name
# 2nd column = desired new name
perl ~/software/scripts/renamefiles.pl

# initial QC
PATH=$PATH\:~/software/fastqc ; export PATH
fastqc raw_data/*
mkdir raw_data_qc
mv raw_data/*fastqc* raw_data_qc

# adapter trimming
mkdir trimmed
chmod +x adapter_trim.sh
./adapter_trim.sh

# QC trimmed files
fastqc trimmed/*trimmed.fq
mkdir trimqc
mv trimmed/*fastqc* trimqc

# trim off first base
perl ~/software/scripts/strip_first_char.pl trimmed/

# rename trimmed files to sensible names
perl renamefiles.pl

# get rid of rRNA
mkdir no_rrna
for file in first_char_stripped/*.fq; do
	echo $file
	echo $file > temp2
	name=$(cut -d / -f 2 temp2)
	echo $name
	bowtie --seedlen=23 --un=no_rrna/${name} /home/ja313/genomes/Homo_sapiens/Ensembl/GRCh38/JelenaCustom/rrna_index_updated/rrna_reference $file >/dev/null
done
rm temp2

# align all files to genome
for file in no_rrna/*.fq; do
	echo $file
	echo $file > temp2
	name=$(cut -d / -f 2 temp2)
	echo $name > temp3
	sample=$(cut -d . -f 1 temp3)
	echo $sample

	echo "tophat --no-novel-juncs --output-dir ${sample}_thout --GTF ~/genomes/Homo_sapiens/Ensembl/GRCh38/Annotation/rel_76/Homo_sapiens.GRCh38.76.withchr.gtf /home/ja313/genomes/Homo_sapiens/Ensembl/GRCh38/Sequence/Bowtie2Index/hg38_genome $file"
done
rm temp2
rm temp3

perl ~/software/scripts/alignmentInfo.pl > tophat_alignment_summary.txt

mkdir sam_files
mkdir bam_files
mkdir gene_counts
mkdir bedgraph
mkdir bigwig

for file in no_rrna/*.fq; do
	echo $file
	echo $file > temp2
	name=$(cut -d / -f 2 temp2)
	echo $name > temp3
	sample=$(cut -d . -f 1 temp3)
	echo $sample

	# make a sam file and extract unique hits
	echo "Creating ${sample} sam file"
	samtools view -h ${sample}_thout/accepted_hits.bam > sam_files/${sample}_accepted.sam
	echo "Sam file created"
	echo $(date)

	echo "Extracting ${sample} unique hits"
	perl ~/software/scripts/unique_flag_search.pl sam_files/${sample}_accepted.sam > sam_files/${sample}_unique.sam
	echo "Unique hits extracted"
	echo $(date)

	echo "Turning ${sample} unique hits to bam file"
	samtools view -S -b sam_files/${sample}_unique.sam > bam_files/${sample}_unique.bam
	echo "Bam file created"
	echo $(date)

	echo "Making a bam index for viewing"
	samtools index bam_files/${sample}_unique.bam bam_files/${sample}_unique.bai

	# getting a read count per gene
	echo "Getting ${sample} read count per gene"
	htseq-count -i gene_id -m union sam_files/${sample}_unique.sam ~/genomes/Homo_sapiens/Ensembl/GRCh38/Annotation/rel_76/Homo_sapiens.GRCh38.76.withchr.gtf > gene_counts/${sample}_gene_counts.txt &
	echo "Read count per gene done"
	echo $(date)

	#convert bam to bedgraph
	echo "Creating bedgraph for ${sample}"
	genomeCoverageBed -bg -split -ibam bam_files/${sample}_unique.bam -g ~/software/UCSC/hg38_genome_UCSC.table > bedgraph/${sample}_unique.bedgraph
	echo "Bedgraph done"
	echo $(date)
 
	echo "Replacing MT for ${sample}"
	# replace 'MT' chromosome to the UCSC term 'chrM' for track upload
	sed -e "s/chrMT/chrM/ig" bedgraph/${sample}_unique.bedgraph > /tmp/tempfile.tmp
	mv /tmp/tempfile.tmp bedgraph/${sample}_unique.bedgraph
	echo "Renaming done"
	echo $(date)
 
	# 	#convert bedgraph to bigwig
	echo "Converting bedgraph to bigwig for ${sample}"
	~/software/UCSC/bedGraphToBigWig bedgraph/${sample}_unique.bedgraph ~/software/UCSC/hg38_genome_UCSC.table bigwig/${sample}_unique.bw
	echo "BigWig conversion done"
	echo $(date)

done
rm temp2 
rm temp3

echo "Generating table of counts"
perl  ~/software/scripts/htseq_table.pl gene_counts > htseq_gene_counts_table.txt
