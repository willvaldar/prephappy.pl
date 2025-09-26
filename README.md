
<h1>Prephappy</h1>

[<a href="software/prephappy/distrib/prephappy_2013-02-26.tar.gz">Download</a>]
[<a href="#Intro">What it does</a>]
[<a href="#Examples">Examples</a>]
[<a href="#Installation">How to install it</a>]
[<a href="#Syntax">Syntax</a>]
[<a href="#Options">Options</a>]

<h2 id="Intro">What it does</h2>
Prephappy is a tool to help prepare input files for the haplotype reconstruction program <a href="http://mtweb.cs.ucl.ac.uk/mus/www/HAPPY/happyR.shtml">HAPPY</a>. It is a Perl program invoked on the command line. Given a set of <a href="allelesformat.md">alleles files</a> and corresponding ped files (eg, chr1.alleles, chr2.alleles, chr1.ped, chr2.ped), it will:
<ul>
	<li>Check the number of markers in the ped and alleles files match.
	<li>Check all individuals have the same number of markers.
	<li>Check that the alleles reported for each marker in the ped are consistent with those allowed by the alleles file.
	<li>Check for zero cM distances between markers (understandably not tolerated by HAPPY).
	<li>Reorder markers by their cM position within each chromosome.
	<li>Convert the deprecated ND values for missing data to NA.</li>
	<li>Renames markers to R-formula-friendly strings, replacing "()-*/^" characters with ".".</li>
	<li>Combine multiple files that specify different markers for the same chromosome.
	<li>Remove specified markers from the data.
	<li>Pad genotypes for subjects with missing chromosomes or missing markers with NA.
	<li>Overwrite existing cM distances in the alleles files with new cM distances specified in a separate table. 
	<li>Incorporate a model of missing genotype data into the happy alleles file (assuming this is not already included).
</ul>		
After these checks and corrections, Prephappy will write a set of "cleaned-up" files to a user-specified directory (by default a new subdirectory PREPHAPPY_GENOTYPES/).
<p>
Small print: Prephappy does not aspire to be interesting, merely useful. That said, Prephappy comes with absolutely no guarantees and users run and rely on it at their own risk.
	
<h2 id="Examples">Examples</h2>

<dl>
	<dt><code>prephappy.pl --alleles chr1.alleles  --ped chr1.ped</code>
	<dd>Check consistency and parity of chr1.alleles and chr1.ped, and write cleaned up versions to a new subdirectory PREPHAPPY_GENOTYPES/.
	<dt><code>prephappy.pl --alleles chr1.alleles  --ped chr1.ped  --skipmarkers 'rs314321,rs489233'</code>
	<dd>As above, but skips markers rs314321 and rs489233 in the checking process and omitting them from the cleaned up files.
	<dt><code>prephappy.pl --alleles old.chr1.alleles,old.chr2.alleles --ped old.chr1.ped,old.chr2.ped</code>
	<dd>Processes files for two chromosomes. There should be no spaces between the filenames.
	<dt><code>prephappy.pl --alleles "old.*.alleles" --ped "old.*.ped"</code>
	<dd>Process all files matching the patterns old.*.alleles and old.*.ped. Prephappy will assume the order of the matched files is the same.
	<dt><code>prephappy.pl --alleles="old.*.alleles",new.chr3.alleles --ped="old.*.ped",new.chr3.ped</code>
	<dd>As above but combines data from files new.chr3.alleles and new.chr3.ped.
		
	<dt><code>prephappy.pl --alleles chr1.alleles --ped chr1.ped --map my.map,my_added.map --mapfile_cM_column my_cM_pos</code>
	<dd>Process files using cM positions defined in my.map and my_added.map (under the column heading my_cM_pos) in place of those in the alleles files.
</dl>	


<h2 id="Installation">How to install it</h2>
These instructions assume you are installing Prephappy on Linux or Darwin/MacOSX, already have installed a working installation of Perl v5.10.0 or higher, and assumes you are familiar with the UNIX command line or in a position to ask favors from someone who is. It <em>may</em> be possible to run Prephappy on Windows or other operating systems but the author has not had occasion to try this.
<ol type=1>
	<li>Download prephappy.pl and put it in a directory you'd like to run it from <i>dir</i>.</li>
	<li>Open a UNIX shell and go to <i>dir</i>.</li>
	<li>Unzip and unarchive by typing <code>tar -zxf prephappy.tgz</code></li>
	<li>Set an environmental variable <code>PREPHAPPY_LIBS</code> to <code><i>dir</i>/prephappy/libs/</code>. For example, in your .bash_profile add the line <code>export PREPHAPPY_LIBS=<i>dir</i>/prephappy/libs/</code>.</li>
	<li>Set an alias to the prephappy program so you can run it from anywhere. For example, in your .bash_profile add the line <code>alias prephappy=<i>dir</i>/prephappy/prephappy.pl</code>.</li>
</ol>

<h2 id="Syntax">Syntax</h2>
<pre>
prephappy --alleles=chr1.alleles,chr2.alleles --ped=chr1.ped,chr2.ped
        [ --add_noise_prob 0 ]
        [ --founder_probs <i>string</i> ]
        [ --map <i>string</i> ]
        [ --mapfile_cM_column <i>string</i> ]
        [ --outdir PREPHAPPY_GENOTYPES/ ]
        [ --mismatch2na 0 ]
        [ --padsubjects 0 ]
        [ --ped_delimiter '\s+' ]   
     	[ --skipmarkers <i>string</i> ]
</pre>



<h2 id="Options">Options</h2>

<dl>
	<dt>--add_noise_prob
	<dd>A model of genotyping error. Specifies the probability $theta$ that at each 
       locus the allele call is a random draw from the set of available allele 
       types rather than from p(allele|founder). This models genotyping error such 
       that in a population of equiprobable founders with biallelic genotypes, the 
       rate of miscalled genotypes is approximately $theta$ (in fact, $theta$ -  
       1/4*$theta$^2). If founders are not equiprobable, then requires
		
	<dt>--founder_probs
	<dd>Optionally specify prior founder probabilities as comma-separated list.
        Only relevant for some options (eg, --add_noise_prob). Default is
        equiprobable founders.
		
	<dt>--alleles
	<dd>Alleles files specified as comma-separated list or/and file patterns (see examples)
	
	<dt>--map
	<dd>Specifies one or more map files to be included in the checking process. The files should be white space delimited (eg, tab delimited) and have columns under the headings "marker", "chr", "bp", as well as any other columns.

	<dt>--mapfile_cM_column
	<dd>Specify column in mapfile corresponding to centiMorgan position and use those cM positions in place of those in the alleles file(s).
	
	<dt>--mismatches2na=1
	<dd>Warns of inconsistent alleles, replacing them with NAs
	
	<dt>--padsubjects=1
	<dd>Sets missing genotypes for missing subjects as NA
	
	<dt>--ped_delimiter
	<dd>Specifies what separates columns in the ped file, eg, '\s', '\t'
	
	<dt>--skipmarkers
	<dd>Skips markers as specified by a comma-separated list (eg, 'rs314321,rs489233')
		                  		or the name of a file containing a whitespace-separated list
</dl>

