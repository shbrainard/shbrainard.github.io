# Demonstration of using bcftools to filter VCF files 
# Author: Scott Brainard <shbrainard@wisc.edu>
# Version of bcftools: 1.11-1-g87d355e (using htslib 1.11-9-g2264113)
# Course: HORT-615

########################################################
# Tips for working with these programs on the command line:
#
# If you are using Windows, I recommend you use Cygwin for this tutorial.  There are a number of
# options out there for creating a UNIX-like environment on Windows that are POSIX-compatible, and I am no expert,
# but Cygwin seems like a very straightforward and well-supported option.
#
# All the commands in bcftools have a ton of options, and this script demonstrates a small fraction of them.
# Read more by running just the name of the program, or the name of the program + one of its commands
# E.g.: 'tabix' or 'bcftools query'
#
# All these programs also have extensive manuals which you can peruse online or by typing:
# 'man tabix' or 'man bcftools', etc.
# (This also applies to 'cd', 'ls', and 'head', etc. which are common utilities for working on the UNIX command line)
#
# There are also lots of common questions answered on the Biostars websites (sort of a StackOverflow for bioinformatics),
# as well as the Github pages for the samtools & bcftools repositories.
########################################################

########################################################
# # Installation instructions for bcftools:
#
# git clone git://github.com/samtools/htslib.git
# git clone git://github.com/samtools/bcftools.git
# cd bcftools
# # The following is optional:
# autoheader && autoconf && ./configure
# make
# # If you have root privileges:
# make install  
#
# # To subsequently install htslib (which contains 'bgzip' and 'tabix', among other common libraries):
#
# cd ../htslib
# autoheader && autoconf && ./configure
# make
# make install  
#
# As an alternative, tarballs of numbered versions of the source code of htslib, samtools, and bcftools is available here:
# https://www.htslib.org/download/
# If you choose to install the software in this way, instead of running the 'git' command, just decompress the .tar.gz file,
# and then proceed with the installation steps as above. 
########################################################


########################################################
# Part 0: prepare some files for processing
########################################################

# These commands aren't intended to be run, I'm just illustrating how I generated 'unfiltered.vcf'
# Instead just 'cd' to the directory where you downloaded 'unfiltered.vcf' to, and move on to Part 1

# Create environment variables that define where my raw VCF files are
# and where I want to be working in (i.e., where I want the output to go)
export VCF_DIR='/Volumes/backup/snp-data/191216_GBS_analysis/D_carota_V3_genome/Tassel_V2_GBS_191211/VCF'
export WORKING_DIR='/Users/boat/Box/Courses/Genetic_Mapping_2021/bcftools_tutorial'

# Move to the directory where we want all these files to be
cd $WORKING_DIR

# Our raw file is pretty big (20 GB), so to make the steps of this script run faster,
# I will read in just the first 10,000 lines ('head -n 10000'), which is a little less than 10,000 markers,
# and write these to unfiltered.vcf by redirecting stdout using the operator '>'
head -n 10000 $VCF_DIR/SNPs.mergedAll.vcf > unfiltered.vcf 


########################################################
# Part 1: compression, indexing, reformatting header, converting
########################################################

# 'bgzip' is a block compressor designed for VCF files
bgzip unfiltered.vcf

# 'tabix' creates indexes of tab-delimited files
# '-p' specifies what kind of file we're passing
# It accepts .vcf, .gff, .bed, and .sam
tabix -p vcf unfiltered.vcf.gz

# 'view' can be used for converting between VCF and BCF formats
# '-O' specifies the output format
# '-o' specifies the output name
# First let's try:
bcftools view unfiltered.vcf.gz -O b -o unfiltered.bcf.gz
# We get 2 warnings and an error:
#
# [W::bcf_hdr_check_sanity] PL should be declared as Number=G
# [W::vcf_parse_info] INFO 'QualityScore' is not defined in the header, assuming Type=String
# [E::bcf_write] Unchecked error (2) at DCARV3_CHR1:16395
# [main_vcfview] Error: cannot write to unfiltered.bcf.gz
#
# TASSEL doesn't generate headers in a 'sane' way
# Until they update their pipeline to conform with current VCF file specifications
# it's good to know how to fix these problems on our end

# Use 'view' again for extracting just the header
bcftools view unfiltered.vcf.gz -h > header.txt
# (we just get a warning, for now!)

# Edit header.txt in your favorite text editor (just don't use Word...)
# For now we'll just fix the Number declaration of PL (change it from '.' to 'G'), and add the following line to define INFO/QualityScore:
# ##INFO=<ID=QualityScore,Number=.,Type=Float,Description="Quality score">
# Save the new file as 'new_header.txt'.  Here I used nano:
nano header.txt

# Use 'reheader' to replace the header using "new_header.txt"
bcftools reheader unfiltered.vcf.gz -h new_header.txt -o unfiltered_newHeader.vcf.gz 

# Second attempt, using 'view' to convert to .bcf
bcftools view unfiltered_newHeader.vcf.gz -O b -o unfiltered_newHeader.bcf.gz 
# Success!

# Use 'index' to index the .bcf (not 'tabix'; this is no longer a tab-delimited file)
bcftools index unfiltered_newHeader.bcf.gz


########################################################
# Part 2: Subsetting based on regions and samples
########################################################

# 'view' can also be used to perform subsetting
# '-S' filters samples on the basis of a file of sample IDs
# '-R' filters sites based on a tab delimited file containing three columns: %CHROM %START_POS %END_POS

# First use 'query' can be used to extract information for preparing a sample ID file
# In this case, the '-l' flag outputs a list of sample IDs
# Here I am piping this (with the pipe '|') to 'head', 
# and writing the first four lines by redirecting stdout (using '>') to subsamples.txt
# Note: '|' and '>' are two of several common operators that can be used in most terminal emulators (bash, zsh, fish)
# They aren't specific in any way to bcftools or VCF files
bcftools query unfiltered_newHeader.bcf.gz -l | head -n 4 > subsamples.txt

# Now create a file called 'regions.txt' to specify a region on chromosome 1 (using the ID for this chromosome)
echo 'DCARV3_CHR1\t10000\t200000' > regions.txt

# Now we can pass both of these files to 'view' and subset the VCF file to contain only the first four samples,
# and only sites between 10kb and 200kb on the first chromosome.  The output is getting written to an uncompressed .vcf file
bcftools view unfiltered_newHeader.bcf.gz -S subsamples.txt -R regions.txt -O v -o subsampled.vcf
bcftools query subsampled.vcf -l | wc -l #4 samples
bcftools view subsampled.vcf -H | wc -l #82 sites


########################################################
# Part 3: Filtering sites based on thresholds
########################################################

# 'filter' is one of the most useful & flexible commands in bcftools
# You can pass an enormous variety of expressions to the options '-e' or '-i',
# depending on whether you want to exclude or include sites which return "TRUE"
# for these expressions, respectively 


# Storing the number of variants in the unfiltered file, just for comparison purposes as we go
# '-H' suppresses the header
noFilter=$(bcftools view -H unfiltered_newHeader.vcf.gz | wc -l) 
depthFilter=$(bcftools filter DMxM6_F2_MAF05.bcf.gz -i 'F_PASS(FMT/DP>=50) >= 0.9 & MAF > 0.1' | bcftools view -H | wc -l)
depthFilter2=$(bcftools filter DMxM6_F2_MAF05.bcf.gz -i 'MEAN(FMT/DP) >=50 & MAF > 0.1' | bcftools view -H | wc -l)

echo "scale=5; $depthFilter2 / $noFilter" | bc #0.75483 - the same as depthFilter3

# Note:
# This pipes the output of the bcftools command to 'wc', and stores the result in a variable called 'noFilter'
# I perform a similar operation in all the commands below, just to make it easy to calculate 
# the fraction of variants in the resulting filtered BCF file (using the UNIX calculator 'bc')
# In every case, the relevant bcftools filtering command is just the part that starts with the first 'bcftools', and ends with first pipe ('|')

########################################################
# A. Filter on a single variable, e.g.: read depth
########################################################

# Exclude sites where at least one sample has depth less than or equal to 10
depthFilter1=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'FORMAT/DP<=10' | bcftools view -H | wc -l)
echo "scale=5; $depthFilter1 / $noFilter" | bc #0.05456

# Include sites where at least one sample has depth > 10
depthFilter2=$(bcftools filter unfiltered_newHeader.bcf.gz -i 'FORMAT/DP>10' | bcftools view -H | wc -l)
echo "scale=5; $depthFilter2 / $noFilter" | bc #0.943513 - very different from depthFilter1

# Exclude sites where average depth <= 10
depthFilter3=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'MEAN(FORMAT/DP)<=10' | bcftools view -H | wc -l)
echo "scale=5; $depthFilter3 / $noFilter" | bc #0.75843

# Include sites where average depth > 10 
depthFilter4=$(bcftools filter unfiltered_newHeader.bcf.gz -i 'MEAN(FORMAT/DP)>10' | bcftools view -H | wc -l)
echo "scale=5; $depthFilter4 / $noFilter" | bc #0.75483 - the same as depthFilter3

# Note: instead of deleting the entire site, you can replace 
# filtered genotypes with a missing value character using '-S'
depthFilterSoft=$(bcftools filter unfiltered_newHeader.bcf.gz -S . -e 'FORMAT/DP<=10' | bcftools view -H | wc -l)
echo "scale=5; $depthFilterSoft / $noFilter" | bc #1.00000 - nothing is deleted

###############################################################
# B. Filter on single variables that are calculated on the fly
###############################################################

# Minor allele count
macFilter=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'MAC<100' | bcftools view -H | wc -l)
echo "scale=5; $macFilter / $noFilter" | bc #0.15557

# Number of alternate alleles (i.e., only biallelic SNPs)
altFilter=$(bcftools filter unfiltered_newHeader.bcf.gz -i 'N_ALT < 2' | bcftools view -H | wc -l)
echo "scale=5; $altFilter / $noFilter" | bc #0.96916

# Minor allele frequency
# Note: using any of the plugins requires an environment variable to be pointing to the right spot
# If you ran 'make install' during installation, this line should already be in '~/.bash_profile' (or equivalent for other shells):
# 'export BCFTOOLS_PLUGINS=/path/to/bcftools/plugins/'
# First use the plugin '+fill-tags' to add in alternate AF information ('-t AF')
bcftools +fill-tags unfiltered_newHeader.bcf.gz -Ob -o unfiltered_newHeader_AF.bcf.gz -- -t AF

# To see the current distribution of allele frequencies, use 'query' to extract them
# the awk command contained in 'tabFreq.awk' then groups them into bins, much like a histogram
bcftools filter unfiltered_newHeader_AF.bcf.gz -e 'N_ALT > 1' | bcftools query -f '%AF\n' > afVals.txt
awk -f ./tabFreq.awk afVals.txt | sort -n -k1
# This isn't necessary to do any filtering, it just shows that we have a lot of sites with low MAF
# Use 'histograms.R' to visualize the output as histogram

# Filter based on 0.05 threshold
mafFilter=$(bcftools filter unfiltered_newHeader_AF.bcf.gz -e 'MAF<=0.05' | bcftools view -H | wc -l)
echo "scale=5; $mafFilter / $noFilter" | bc #0.23595
bcftools filter unfiltered_newHeader_AF.bcf.gz -e 'MAF<=0.05' -Ob -o AF_filtered.bcf.gz

# What is the new distribution?
bcftools filter AF_filtered.bcf.gz -e 'N_ALT > 1' | bcftools query -f '%AF\n' > afVals2.txt
awk -f ./tabFreq.awk afVals2.txt | sort -n -k1
# Indeed, the sites with low MAF are now gone.  Always good to confirm these things the first time around!

###############################################################
# C. Filtering on multiple variables using boolean operators
###############################################################

####
# i. Depth and genotype quality
####
# & tests whether both expressions return true in a SINGLE sample
DPandGT1=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'FMT/DP<10 & FMT/GQ<70' | bcftools view -H | wc -l)
echo "scale=5; $DPandGT1 / $noFilter" | bc #0.39753

# && tests whether both expressions return true in ANY samples (i.e., can be the same or different samples)  
DPandGT2=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'FMT/DP<10 && FMT/GQ<70' | bcftools view -H | wc -l)
echo "scale=5; $DPandGT2 / $noFilter" | bc #O.34798 - more gets filtered out

####
# ii. Number of ALT alleles and depth
####
N_ALTandDP1=$(bcftools filter unfiltered_newHeader.bcf.gz -i 'N_ALT < 1 & FMT/DP>10' | bcftools view -H | wc -l)
echo "scale=5; $N_ALTandDP1 / $noFilter" | bc #0.51066
N_ALTandDP2=$(bcftools filter unfiltered_newHeader.bcf.gz -i 'N_ALT < 1 && FMT/DP>10' | bcftools view -H | wc -l)
echo "scale=5; $N_ALTandDP2 / $noFilter" | bc #0.51066

N_ALTandDP3=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'N_ALT > 1 & FMT/DP<20' | bcftools view -H | wc -l)
echo "scale=5; $N_ALTandDP3 / $noFilter" | bc #0.96966
onlyDP=$(bcftools filter unfiltered_newHeader_AF.bcf.gz -e 'FMT/DP<20' | bcftools view -H | wc -l)
echo "scale=5; $onlyDP / $noFilter" | bc #0.01381
onlyN_ALT=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'N_ALT > 1' | bcftools view -H | wc -l)
echo "scale=5; $onlyN_ALT / $noFilter" | bc #0.96916

####
# iii. Depth and MAF
####
# For reference, this is how many SNPs we started with in the full file:
# wc -l $VCF_DIR/SNPs.mergedAll.vcf #1,764,287
MAFandDP1=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'FORMAT/DP<5 | MAF < 0.05' | bcftools view -H | wc -l)
echo "scale=5; $MAFandDP1 / $noFilter" | bc #0.01221
echo "0.01221 * 1764287" | bc #21,541
MAFandDP2=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'MEAN(FORMAT/DP)<5 | MAF < 0.05' | bcftools view -H | wc -l)
echo "scale=5; $MAFandDP2 / $noFilter" | bc #0.23625
echo "0.23625 * 1764287" | bc #416,813
MAFandDP3=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'MEAN(FORMAT/DP)<5 | MAF < 0.05 | FORMAT/DP<1' | bcftools view -H | wc -l)
echo "scale=5; $MAFandDP3 / $noFilter" | bc #0.02883
echo "0.02883 * 1764287" | bc #50,864
# Depth less than 1?  How can than be?

# Depth, MAF, and missing data
MAFandDP4=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'MEAN(FORMAT/DP)<5 | MAF < 0.05 | GT="./."' | bcftools view -H | wc -l)
echo "scale=5; $MAFandDP4 / $noFilter" | bc #0.02883 - same as MAFandDP3
MAFandDP5=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'MEAN(FORMAT/DP)<5 | MAF < 0.05 | F_PASS(GT="./.") > 0.1' | bcftools view -H | wc -l)
echo "scale=5; $MAFandDP5 / $noFilter" | bc #0.10922
MAFandDP6=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'FORMAT/DP<5 | MAF < 0.05 | F_PASS(GT="./.") > 0.1' | bcftools view -H | wc -l)
echo "scale=5; $MAFandDP6 / $noFilter" | bc #0.01221 - same as MAFandDP1

####
# iv. Subsetting by samples
####

nSites_unfiltered=$(bcftools view -H unfiltered_newHeader.vcf.gz | wc -l) 
nSamples_unfiltered=$(bcftools query unfiltered_newHeader.bcf.gz -l | wc -l)

nSites_DPfilter=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'SMPL_MEAN(FORMAT/DP)<10' | bcftools view -H | wc -l)
nSamples_DPfilter=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'SMPL_MEAN(FORMAT/DP)<10' | bcftools query -l | wc -l)

echo "scale=5; $nSites_DPfilter / $nSites_unfiltered" | bc #0.17349 - sites are removed, even though the filter is being applied to samples
echo "scale=5; $nSamples_DPfilter / $nSamples_unfiltered" | bc #1.00000 - no samples removed, despite, again, the filter being appied to samples


nSites_DPfilter=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'SMPL_MEAN(FORMAT/DP)<10' | bcftools view -H | wc -l)
nSamples_DPfilter=$(bcftools filter unfiltered_newHeader.bcf.gz -e 'SMPL_MEAN(FORMAT/DP)<10' | bcftools query -l | wc -l)

echo "scale=5; $nSites_DPfilter / $nSites_unfiltered" | bc #0.17349 - sites are removed, even though the filter is being applied to samples
echo "scale=5; $nSamples_DPfilter / $nSamples_unfiltered" | bc #1.00000 - no samples removed, despite, again, the filter being appied to samples

bcftools +smpl-stats unfiltered.bcf.gz 
bcftools stats -s - unfiltered.bcf.gz | less -S


export SnpSift="/Users/shbrainard/Desktop/snpEff/SnpSift.jar"

grep \#CHROM unfiltered.vcf | tr -dc : | wc -c #672
wc -l unfiltered.vcf #10000
cat unfiltered.vcf | java -jar $SnpSift filter " ( MEAN(GEN[*].DP[*]) > 10 )" > filtered.vcf
grep \#CHROM filtered.vcf | tr -dc : | wc -c #672
wc -l filtered.vcf #9435


bcftools filter unfiltered.bcf.gz -e 'N_ALT >= 2 | FMT/DP<=20' | bcftools query -l | wc -l  #672
bcftools filter unfiltered.bcf.gz -e 'N_ALT >= 2 || FMT/DP<=20' | bcftools query -l | wc -l  #672

bcftools query -f'[%POS %SAMPLE %DP\n]\n' -i 'FMT/DP=19 | FMT/DP="."' unfiltered_newHeader.bcf.gz | wc -l
bcftools query -f'[%POS %SAMPLE %DP\n]\n' -i 'FMT/DP=19 || FMT/DP="."' unfiltered_newHeader.bcf.gz | wc -l 

bcftools query -f'[%POS %SAMPLE %DP\n]\n' -e 'sMEAN(FMT/DP) < 10' unfiltered_newHeader.bcf.gz | wc -l 

bcftools filter -e 'sMEAN(FMT/DP) < 10' unfiltered_newHeader.bcf.gz | bcftools view -H | wc -l 
bcftools filter -e 'MEAN(FMT/DP) < 10' unfiltered_newHeader.bcf.gz | bcftools view -H | wc -l 

nSites_normalDPFilter=$(bcftools filter unfiltered.bcf.gz -e 'MEAN(FMT/DP) < 5' | bcftools view -H | wc -l)
echo "scale=5; $nSites_normalDPFilter / $nSites_unfiltered" | bc #0.75483 - fewer sites removed the sMEAN

####
# v. Subsetting by samples with high degree of missingness
####

# 'stats' provides a ton of summary statistics; '-s -' indicates we want information on all samples
# Specifically the section 'PSC, Per-sample counts' has some interesting info summarized by sample ID:
bcftools stats -v -s - unfiltered_newHeader.bcf.gz | less -S

# Let's extract the 3rd and 14th columns and write them to 'nMissing.txt'
bcftools stats -s - unfiltered_newHeader.bcf.gz | grep -E ^PSC | cut -f3,14 > nMissing.txt

# Inspection in R (see 'histograms.R') identifies a couple samples with > 22.5% missing data
# We can remove them with 'view', using the '-s' flag (instead of the '-S' flag used above when passing a file of sample IDs) 
# the leading '^' character indicates we want to delete these samples, instead of including only them
bcftools view unfiltered_newHeader.bcf.gz -s ^142914:201911151539170,142726:2019111515391711 -Ob -o unfiltered_newHeader_noMissing.bcf.gz

# Confirmation that this did what we expected:
bcftools query unfiltered_newHeader.bcf.gz -l | wc -l #672 samples
bcftools query unfiltered_newHeader_noMissing.bcf.gz -l | wc -l #670 samples

# Column 10 contains average depth per sample, in case you want to filter on depth.
bcftools stats -s - unfiltered_newHeader.bcf.gz | grep -E ^PSC | cut -f3,10 > avgSMPLDepth.txt

# Sample 143804:2019111515391763 has an avg depth of 9.3, which depending on your species and objectives, might be too low


########################################################
# Part 4: Prune based on statistics computed across sites 
########################################################

# '+prune' allows you to filter based on comparisons across sites
# in this case we filter out markers that have an LD (i.e., r^2) > 0.75, calculated in sliding windows of 100bp, 10kb and 100kb

LDpruned1=$(bcftools +prune unfiltered_newHeader.bcf.gz -m 0.75 -w 100 | bcftools view -H | wc -l)
echo "scale=5; $LDpruned1 / $noFilter" | bc #0.29522 

LDpruned2=$(bcftools +prune unfiltered_newHeader.bcf.gz -m 0.75 -w 10000 | bcftools view -H | wc -l)
echo "scale=5; $LDpruned2 / $noFilter" | bc #0.24446

LDpruned3=$(bcftools +prune unfiltered_newHeader.bcf.gz -m 0.75 -w 100000 | bcftools view -H | wc -l)
echo "scale=5; $LDpruned3 / $noFilter" | bc #0.24446