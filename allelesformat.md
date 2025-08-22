<html>
<body>
<h1>HAPPY .alleles file format</h1>


<table>
  <tr>
    <th style="background-color: rgb(240,240,240) ; color: black;" >Line #</th>
    <th style="background-color: rgb(240,240,240) ; color: black;" >Example .alleles file</th>
  <tr>
    <td style="background-color: rgb(240,240,240) ; color: black;" ><pre>
 1
 2
 3
 4
 5
 6
 7
 8
 9
10
</pre>
    </td>
    <td><pre>
markers 2 strains 8
strain_names    A.J     C57BL   CAST    NOD     NZO     PWK     WSB     X129
marker rs31192577       3       1       1.506
allele  A       0.25    0.25    0       0       0.25    0       0.25    0
allele  T       0       0       0.25    0.25    0       0.25    0       0.25
allele  NA      0.125   0.125   0.125   0.125   0.125   0.125   0.125   0.125
marker rs30462182       3       1       1.5473
allele  A       0       0       0.25    0.25    0       0.25    0       0.25
allele  C       0.25    0.25    0       0       0.25    0       0.25    0
allele  NA      0.125   0.125   0.125   0.125   0.125   0.125   0.125   0.125
</pre>
    </td>
  </tr>
</table>

<h3>Line 1: summary</h3>

<code>markers <i>M</i> strains <i>F</i></code>
<br>
<br>
<table>
  <tr>
    <th>Field name</th>
    <th>Type</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>M</code></td>
    <td>integer</td>
    <td>The number of markers described in the alleles file</td>
  </tr>
  <tr>
    <td><code>F</code></td>
    <td>integer</td>
    <td>The number of founders listed in the alleles file</td>
  </tr>
</table>

<h3>Line 2: strain names</h3>

<code>strain_names <i>strain1</i> <i>strain2</i> ... <i>strainF</i></code>
<br>
<br>
<table>
  <tr>
    <th>Field name</th>
    <th>Type</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>strainX</code></td>
    <td>Rstring</td>
    <td>The name of the founder. There must be as many names as founders.</td>
  </tr>
</table>

<h3>Line 3: marker summary</h3>

<code>marker <i>marker_name</i> <i>num_alleles</i> <i>chr</i> <i>cM</i></code>
<br>
<br>
<table>
  <tr>
    <th>Field name</th>
    <th>Type</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>marker_name</code></td>
    <td>Rstring</td>
    <td>Name of the marker. Markers should be given in cM position order.</td>
  </tr>
  <tr>
    <td><code>num_alleles</code></td>
    <td>integer</td>
    <td>The number of possible alleles for this marker, plus one for the missing allele value <code>NA</code>.</td>
  </tr>
  <tr>
    <td><code>chr</code></td>
    <td>string</td>
    <td>The name of the chromosome. Can be written as a number. "X" is interpreted as the sex chromosome.</td>
  </tr>
  <tr>
    <td><code>cM</code></td>
    <td>float</td>
    <td>The position of the marker on the chromosome in centiMorgans based on an unexpanded map. The increase in cM position from one marker to the next is taken as the probability that a recombination event occurs between them in a single generation. The cM specified must be numerically unique (up to 6 decimal places) in the alleles file, such that no markers can occupy the same position.</td>
  </tr>
</table>

<h3>Line 4 to (4 + <code>num_alleles</code>-1): allele-specific founder priors for <code>marker_name</code></h3>

<code>allele <i>symbol</i> <i>probStrain1</i> <i>probStrain2</i> ... <i>probStrainF</i></code>
<br>
<br>
<table>
  <tr>
    <th>Field name</th>
    <th>Type</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>symbol</code></td>
    <td>string</td>
    <td>The name of the allele as it would appear in the <a href="pedformat.html">two-column genotype ped file</a>. NA (ie, a missing value) is treated as an allele.</td>
  </tr>
  <tr>
    <td><code>probStrainX</code></td>
    <td>float</td>
    <td>The conditional prior probability that an observed allele <code>symbol</code> would be descended from founder X. See below for more info.</td>
  </tr>
</table>
<br>
In the example above it assumed that the target individual (ie, the individual whose haplotype mosaic is to be reconstructed by the HMM) has an equal chance of receiving a haplotype from any of the 8 founders.  At marker rs31192577, the 4 inbred strains A.J, C57BL, NZO, and WSB all have the <code>A</code>. Therefore, if you were told that in a target individual the allele <code>A</code> was observed at marker rs31192577, in the absence of any other information the probability of underlying haplotype would be 1/4. More generally,
<dl>
  <dt><code>probStrainX = Pr(X|A) = Pr(X) * Pr(A|X) / Pr(A)</code></dt>
  <dd>where
  <dt><code>Pr(X)</code></dt>
  <dd>is the prior probability of inheriting a haplotype from founder <code>X</code>. When all <code>F</code> founders contribute equally to the population, <code>Pr(X)=1/F</code>.</dd>
  <dt><code>Pr(A|X)</code></dt>
  <dd>is the probability of getting allele <code>A</code> from founder <code>X</code>. For example, if <code>X</code> is heterozygous for <code>A</code> then <code>Pr(A|X)=1/2</code>.</dd>
  <dt><code>Pr(A)</code></dt>
  <dd>is the total probability of getting allele <code>A</code>, which is calculated as the sum of <code>Pr(A|X)</code> for all <code>X</code>.</dd>
</dl>

</body>
</html> 


