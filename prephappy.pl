#!/usr/bin/perl -w

#Copyright 2013 William Valdar
#This file is part of prephappy.

#prephappy is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.

#prephappy is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with prephappy.  If not, see <http://www.gnu.org/licenses/>.

# 
#  data ---- AlleleData ---- {marker} --- chr
#         |                            |- cM
#         |                            \- alleles --- { allele } -- probability
#         |
#         |- StrainOrder --- [ strains ]
#         |
#         \- SubjectData --- {id} --- family
#                                  |- subject
#                                  |- father
#                                  |- mother
#                                  |- sex
#                                  |- phenotype
#                                  \- genotypes --- {marker} -- [ allele1, allele2 ]  
#
use strict;
use StdDefs;
use English;
use Carp;
use Assert;
use Array;
use Array2d;
use File::Path;
use Getopt::Long;
use String qw(Trim Chomp);
use FileIoHelper qw(OpenFilesForReading OpenFilesForWriting FileNotEmpty FileEmptyOrAbsent FileExists DirExists);
use Data::Dumper;
use Text::Wrap;
$Text::Wrap::columns = 72;
use Shell ("ls");

my $MAX_CENTIMORGANS = 1e5;
my $ALLOW_CONSISTENT_DUPLICATES = false;
my $CONVERT_MISMATCHES_TO_NA = false;
my $MAP_CM_COLUMN	= undef;
my $PAD_MISSING_GENOTYPES = false;
my $PAD_MISSING_SUBJECTS = false;
my $PED_DELIMITER = '\s+';
my $TRIM_WHITESPACE = false;
my $REMOVE_UNINFORMATIVE = 0; # 1 => markers with entirely uninformative alleles, 2 => markers with any uninformative alleles  
my $ALLOW_UNINFORMATIVE_ALLELES = false;
my $ALLOW_UNINFORMATIVE_MARKERS = false;

sub AddNoiseProb($$$){
	my($data, $noiseProb, $hFounderProbs) = @ARG;
	my @aFounders      = sort keys %{$hFounderProbs};
	my @aFounderPriors = @$hFounderProbs{@aFounders};
	my $aMiscallTerm   = Array::Multiply(\@aFounderPriors, [], $noiseProb);

	while (my($marker, $markerInfo)=each %{$data->{'AlleleData'}}){
		while (my($allele, $hProbs)=each %{$markerInfo->{'alleles'}}){
			my $aProbs = [@$hProbs{@aFounders}];
			# normalise to [0,1]
			my $sum = Array::Sum($aProbs);
			if (0!=$sum){
			  Array::Divide($aProbs, $aProbs, $sum);
			} 
			else {
			  warn "Warning: Allele $allele of marker $marker on chr ".$markerInfo->{'chr'}." has pre-noise priors that sum to zero (possible error?)\n";
			}
			# (1-p(miscall))p(founder|allele) + p(miscall)p(founder)
			Array::Multiply($aProbs, $aProbs, (1-$noiseProb));
			Array::Plus($aProbs, $aProbs, $aMiscallTerm);
			@$hProbs{@aFounders} = @$aProbs;
		}		
	}
}

sub FormatError{
  warn "Format Error: @ARG\n";
  die;
}

sub DataException{
  warn "Unresolved Data Problem: @ARG\n";
  exit(1);
}

sub MakeRFriendlyName($)
{
	my $string = shift;
	$string =~ s/^(\d)/m$1/;
	$string =~ s/[^\w\._]/./g;
	return $string;
}

sub ReadAlleles($){
  my $ist = shift;

  my $hAlleles      = {};
  my $aMarkers      = [];
  my $aStrains      = undef;
  my $currentMarker = undef;
  while (my $line = $ist->getline){
    if ($line =~ m/^marker\s+(\S+)\s+(\S.*\S)\s*$/){
      my $markerName = $1;
      $currentMarker = MakeRFriendlyName($markerName);
      if ($markerName ne $currentMarker){
      	warn "Renamed $markerName to $currentMarker\n";
      }

      my($nAlleles, $chr, $cM) = split m/\s+/, $2;
      unless (defined $chr){
        FormatError("No chr defined in alleles file for $currentMarker");
      }
      unless (defined $cM){
        FormatError("No cM defined in alleles file for $currentMarker");
      }
      if ($cM > $MAX_CENTIMORGANS){
        FormatError("Aberrantly large centiMorgan location $cM for marker $currentMarker on chr $chr (could the bp have been used by accident?)")
      }
      if (exists $hAlleles->{$currentMarker}){
        FormatError("Multiple definitions of marker $currentMarker\n");
      }
      push @$aMarkers, $currentMarker;
      $hAlleles->{$currentMarker} = {
                  'chr' => $chr,
                  'cM'=> $cM,
                  'alleles'=>{}};
    }
    elsif ($line =~ m/^allele\s+(\w+)\s+(.*)\s*$/){
      my $allele = $1;
      my $aProbs = Array::Add([split m/\s+/, $2], 0);

      # check for redefinitions
      $allele = "NA" if $allele eq "ND";
      if (exists $hAlleles->{$currentMarker}{'alleles'}{$allele}){
        FormatError("Multiple definitions for allele $allele of marker"
                ." $currentMarker");
      }

      # check probabilities
      if (@$aProbs != @$aStrains){
        FormatError("$currentMarker has should have ".scalar(@$aStrains).
                " probabilities but reports ". scalar(@$aProbs));
      }
      
      # bank
      my $hash = Hash::New($aStrains, $aProbs);
      $hAlleles->{$currentMarker}{'alleles'}{$allele} = $hash;
    }
    elsif ($line =~ m/^strain_names\s+(\S+.*\S+)\s*$/){
      $aStrains = [split m/\s+/, $1] unless defined $aStrains;
      for my $strain (@$aStrains)
      {
        my $rname = MakeRFriendlyName($strain);
        if ($rname ne $strain){
          warn "Renamed $strain to $rname\n";
          $strain = $rname;
        }
      }
    }
  }
  return ($aStrains, $aMarkers, $hAlleles);
}

sub ReadPed($$$)
{
    my($ist,$aMarkers,$hAlleles) = @ARG;

    my $hSubjects = {};
    while (my $line = $ist->getline)
    {
        if ($line =~ s/\#MARKER_ORDER\s+//)
        {
            $aMarkers = [split m/\s+/, $line];
            warn "Using header to determine marker order in ped file\n";
            next;
        }

        next if $line =~ m/^\#/;
        next unless $line =~ m/\S/;
        if ($line !~ m/^\S/)
        {
            die "Format error in ped file. Offending line: \n\""
                    .wrap("","",$line)."\"";
        }

        $line = String::Chomp($line);
        if ($TRIM_WHITESPACE)
        {
            $line = String::Trim($line);        
        }

        my($family, $subject, $father, $mother, $sex, $phenotype, @genos) = split m/$PED_DELIMITER/o, $line;

        if (scalar(@$aMarkers)*2 != scalar(@genos))
        {
            FormatError("Expected ".(2*scalar(@$aMarkers))." markers for subject $subject but got ".scalar(@genos)
                 .". Could the ped file contain trailing delimiters? These can be removed with --trim=1"
                 .", but note that trailing blanks will no longer be converted to NA.");
        }
        for my $geno (@genos)
        {
            $geno = "NA" if ($geno eq "ND" or $geno eq "");
        }
        
        if (not defined \@genos)
        {
            print Dumper([@genos]);
        }

        my $aGenotypes = Array2d::Matrix(\@genos, "dim2"=>2);

        my $hSubject = {
                "family"    => $family,
                "subject"   => $subject,
                "father"    => $father,
                "mother"    => $mother,
                "sex"       => $sex,
                "phenotype" => $phenotype,
                "genotypes" => Hash::New($aMarkers, $aGenotypes),
                };
        if (exists $hSubjects->{$subject})
        {
            FormatError("Multiple rows for subject $subject");
        }
        while (my($marker, $aGenotypes)= each %{$hSubject->{'genotypes'}})
        {
            my $alleles = $hAlleles->{$marker}{'alleles'};
            for my $a (@$aGenotypes)
            {
                unless (exists $hAlleles->{$marker}{'alleles'}{$a})
                {
                    my $msg = "No matching allele $a for marker $marker".
                            " in subject $subject";
                    if ($CONVERT_MISMATCHES_TO_NA)
                    {
                        warn "Warning: $msg. Converting to NA\n";
                        $a = "NA";
                    }
                    else
                    {
                        FormatError($msg);
                    }
                }
            }
        }
        $hSubjects->{$subject} = $hSubject;
    }
    return $hSubjects;
}

sub ReadData($$)
{
    my($allelesFile, $pedFile) = @ARG;

    print "Reading $allelesFile ";
    my($aStrains, $aMarkers, $hAlleles) = ReadAlleles(
            OpenFilesForReading($allelesFile));

    print "with $pedFile\n";
    my($hSubjects) = ReadPed(OpenFilesForReading($pedFile),
            $aMarkers, $hAlleles);

    # map file
    return {
        'StrainOrder'  => $aStrains,
        'AlleleData'   => $hAlleles,
        'SubjectData'  => $hSubjects};
}

sub LoadStore($)
{
    my $file = shift;
    my $ist = OpenFilesForReading($file);
    my $string = $ist->getline;
    my ($data) = FreezeThaw::thaw($string);
    return $data;
}

sub SaveStore($$)
{
    my($data, $file) = @ARG;
    my $ost = OpenFilesForWriting($file);
    $ost->print(FreezeThaw::freeze($data));
}

sub CombineData($$)
{
    my($data, $newData) = @ARG;
    return $data unless defined $newData;
    return $newData unless defined $data;

    # strains
    my($aCurrentOnly, $aNewOnly, $aIntersect) = Array::Diff(
            $data->{'StrainOrder'}, $newData->{'StrainOrder'});

    if (0<scalar(@$aNewOnly) or 0<scalar(@$aCurrentOnly))
    {
        FormatError("Mismatch of strains sets between files.",
                "File specific strains: { @$aNewOnly } vs { @$aCurrentOnly }",
                "Common strains: { @$aIntersect }");
    }


    # subjects
    my $aCurrentSubjects = [keys %{$data->{'SubjectData'}}];
    my $aNewSubjects     = [keys %{$newData->{'SubjectData'}}];

    ($aCurrentOnly, $aNewOnly, $aIntersect) = Array::Diff(
            $aCurrentSubjects, $aNewSubjects);

    for my $id (@$aIntersect)
    {
        $data->{'SubjectData'}{$id}{'genotypes'} = Hash::Join(
                $data->{'SubjectData'}{$id}{'genotypes'},
                $newData->{'SubjectData'}{$id}{'genotypes'});
    }

    if (0<@$aCurrentOnly)
    {
        print "got here\n"; die;
        unless ($PAD_MISSING_SUBJECTS)
        {
            Fatal("Subjects @$aCurrentOnly missing from some ped files");
        }
        my $aMarkers = [keys %{$newData->{'AlleleData'}} ];
        my $aFakeGeno = ["NA","NA"];
        my $aFakeGenotypes = Array::ToHash($aMarkers,
                sub{$ARG[0]}, sub{$aFakeGeno});
        for my $id (@$aCurrentOnly)
        {
            warn "Adding NA genotypes for incomplete subject $id\n";
            $data->{'SubjectData'}{$id}{'genotypes'} = Hash::Join(
                $data->{'SubjectData'}{$id}{'genotypes'},
                $aFakeGenotypes);
        }
    }
	
    if (0<@$aNewOnly)
    {
        print "got here 2\n"; die;
        unless ($PAD_MISSING_SUBJECTS)
        {
            Fatal("Subjects @$aNewOnly missing from some ped files");
        }
        my $aMarkers = [keys %{$data->{'AlleleData'}} ];
        my $aFakeGeno = ["NA","NA"];
        my $aFakeGenotypes = Array::ToHash($aMarkers,
                sub{$ARG[0]}, sub{$aFakeGeno});
        for my $id (@$aNewOnly)
        {
          warn "Adding NA genotypes for incomplete subject $id\n";
          $data->{'SubjectData'}{$id}{'genotypes'} = Hash::Join(
              $data->{'SubjectData'}{$id}{'genotypes'},
              $aFakeGenotypes);
        }
    }

    # alleles
    while (my($marker, $info) = each %{$newData->{'AlleleData'}})
    {
        if (exists $data->{'AlleleData'}{$marker})
        {
            unless ($ALLOW_CONSISTENT_DUPLICATES)
  			{
  				Fatal("Marker $marker defined in multiple alleles files");
  			}
			# TODO
        }
        $data->{'AlleleData'}{$marker} = $info;
    }
    return $data;
}

sub RemoveMarkers($$$)
{
    my($data, $aMarkers, $verbose) = @ARG;

    for my $marker (@$aMarkers)
    {
        print "Skipping marker $marker\n" if $verbose;
        delete $data->{'AlleleData'}{$marker};
        while (my($subject, $hash) = each %{ $data->{'SubjectData'} })
        {
            delete $hash->{'genotypes'}{$marker};
        }
    }
    return $data;
}

sub ListChrMarkers($$)
{
    my($data, $chr) = @ARG;
    my $aMarkers = [];
    while (my($marker, $info) = each %{$data->{'AlleleData'}} )
    {
        if ($info->{'chr'} eq $chr)
        {
            push @$aMarkers, $marker;
        }
    }
    $aMarkers = [ sort {
                $data->{'AlleleData'}{$a}{'cM'} <=>
                $data->{'AlleleData'}{$b}{'cM'}
                } @$aMarkers];
    return $aMarkers;
}

sub WriteChrFiles($$$$)
{
    my($data, $chr, $allelesFile, $pedFile) = @ARG;

    my $aMarkers = ListChrMarkers($data, $chr);

    my($ostAlleles) = OpenFilesForWriting($allelesFile);

    print "Writing $allelesFile\n";
    # write alleles file
    $ostAlleles->print("markers ".scalar(@$aMarkers)." strains ".
            scalar(@{$data->{'StrainOrder'}})."\n");
    $ostAlleles->print("strain_names\t\t".
            join("\t",@{$data->{'StrainOrder'}})."\n");
    for my $marker (@$aMarkers)
    {
        my $markerData = $data->{'AlleleData'}{$marker};
        my $hAlleles = $markerData->{'alleles'};
        $ostAlleles->print("marker ".join("\t",
                $marker,
                scalar keys %$hAlleles,
                $chr,
                $markerData->{'cM'}), "\n");
        for my $allele (sort keys %$hAlleles)
        {
            $ostAlleles->print("allele\t$allele");
            for my $strain (@{$data->{'StrainOrder'}})
            {
                $ostAlleles->print("\t",
                        $hAlleles->{$allele}{$strain});
            }
            $ostAlleles->print("\n");
        }
    }

    print "Writing $pedFile\n";
    # write ped file
    my($ostPed) = OpenFilesForWriting($pedFile);
    $ostPed->print("\#family\tsubject\tfather\tmother\tsex\tphenotype");
    $ostPed->print("\t", join("\t\t", @$aMarkers), "\t\n");

    for my $subject (sort keys %{$data->{'SubjectData'}} )
    {
        my $hSubject = $data->{'SubjectData'}{$subject};
        $ostPed->print(join("\t",
                $hSubject->{'family'},
                $subject,
                $hSubject->{'father'},
                $hSubject->{'mother'},
                $hSubject->{'sex'},
                $hSubject->{'phenotype'}));
        my $hGenotypes = $hSubject->{'genotypes'};
        for my $marker (@$aMarkers)
        {
            if (not defined $hGenotypes->{$marker})
            {
                warn "$marker missing from $subject\n";
die;#                next;
#                print Dumper( $hGenotypes );    
            }
            my($a1, $a2) = @{$hGenotypes->{$marker}};
            $ostPed->print("\t$a1\t$a2");
        }
        $ostPed->print("\n");
    }
}

sub ReadMap($$)
{
    my($data, $mapFile) = @ARG;
    # read map
    my $ist = OpenFilesForReading($mapFile);
    my @headers = split(m/\s+/, $ist->getline);
    my %map = ();
    for my $header (@headers){ $map{$header}=[]; }
    unless (exists $map{'marker'} and exists $map{'bp'})
    {
        Fatal("Map file $mapFile must contain marker and bp columns\n");
    }
	if (defined $MAP_CM_COLUMN and not exists $map{$MAP_CM_COLUMN})
	{
		Fatal("Map file $mapFile must contain specified cM column $MAP_CM_COLUMN")
	}

    while (my $line = $ist->getline)
    {
        my(@cols) = split m/\s+/, $line;
        for (my $i=0; $i<@headers; $i++)
        {
            push @{ $map{$headers[$i]} }, $cols[$i];
        }
    }

    # inc map into data
    for (my $i=0; $i<@{$map{'marker'}}; $i++)
    {
        my $marker = $map{'marker'}[$i];
		$marker = MakeRFriendlyName($marker);
        if (exists $data->{'AlleleData'}{$marker})
        {
            $data->{'AlleleData'}{$marker}{'bp'} = $map{'bp'}[$i];
			if (defined $MAP_CM_COLUMN)
			{
				$data->{'AlleleData'}{$marker}{'cM'} = $map{$MAP_CM_COLUMN}[$i];
			}
        }
    }
    return $data;
}

sub ListChromosomes($)
{
    my $data = shift;
    my $hChrom = {};
    while (my($marker, $info) = each %{$data->{'AlleleData'}})
    {
        my $chr = $info->{'chr'};
        $hChrom->{$chr} = true unless exists $hChrom->{$chr};
    }
    keys %$hChrom;
}

sub WriteMap($$)
{
    my($data, $mapFile) = @ARG;
    my $ost = OpenFilesForWriting($mapFile);
    $ost->print("marker\tchr\tpos\tbp\n");
    for my $chr (ListChromosomes($data))
    {
        my $aMarkers = ListChrMarkers($data, $chr);
        for my $marker (@$aMarkers)
        {
            my $cM = $data->{'AlleleData'}{$marker}{'cM'};
            my $bp = exists $data->{'AlleleData'}{$marker}{'bp'}
                            ? $data->{'AlleleData'}{$marker}{'bp'}
                            : "NA";
            $ost->print(join("\t", $marker, $chr, $cM, $bp), "\n");
        }
    }
}

sub CheckData($){
  my $data = shift;

  # collect a list of bad markers to be chucked out
  my $aBadMarkers = [];

  my %chr2pos2marker = ();
  while (my($marker, $info) = each %{$data->{'AlleleData'}})
  {
    # check for duplicate marker locations
    my $chr = $info->{'chr'};
    my $cM  = $info->{'cM'};
    if (exists $chr2pos2marker{$chr}{$cM})
    {
        FormatError("Multiple markers with same cM position: $marker, "
                .$chr2pos2marker{$chr}{$cM});
    }
    $chr2pos2marker{$chr}{$cM} = $marker;
    
    # check for uninformative markers
    my $markerHasIncompleteInfo = false;
    my $markerHasNoInfo = true;
    while (my($allele, $hProbs) = each %{$info->{'alleles'}}){
      my $aProbs = [values %$hProbs];
      # find problems with NA 'allele' probs
      if ('NA' eq $allele){
        if (0==Array::Sum($aProbs)){
          warn "Warning: NA allele of marker $marker has zero prior weight. "
              ."Consider giving equal weight to allow genotype missingness "
              ."for this marker.\n";
        }
        next;
      }
      # check information level in non-na alleles
      if (1==Array::CountUnique($aProbs)){
        $markerHasIncompleteInfo = true;
      } else {
        $markerHasNoInfo = false; 
      }
    }
    # filter, warn or stop depending on options
    if ($markerHasIncompleteInfo){
      if ($ALLOW_UNINFORMATIVE_MARKERS or $ALLOW_UNINFORMATIVE_ALLELES){
        next;
      } elsif ($REMOVE_UNINFORMATIVE == 2){
        print "Removing marker $marker with one or more uniformative alleles.\n";
        push @$aBadMarkers, $marker;
      } else {
        DataException("Marker $marker on chr ".$info->{'chr'}
          ." has one or more uninformative alleles in its alleles file. "
          ." Either remove using --rm_uninformative=2 or "
          ." explicitly allow using --allow_uninformative_alleles=1 .");
      }
    }
    if ($markerHasNoInfo){
      if ($ALLOW_UNINFORMATIVE_MARKERS){
        next;
      } elsif ($REMOVE_UNINFORMATIVE >= 1){
        push @$aBadMarkers, $marker;
        print "Removing marker $marker with entirely uniformative alleles.\n";
      } else {
        DataException("Marker $marker on chr ".$info->{'chr'}
          ." has entirely uninformative alleles in its alleles file."
          ." Either remove using --rm_uninformative=1"
          ." (or --rm_uninformative=2 for ), or"
          ." explicitly allow using --allow_uninformative_markers=1 .");
      }
    }
  }
  
  # check genotypes are available for all markers on all subjects
  # SHOULDN'T BE NECESSARY
  #my $subject;
  while (my($subject, $info) = each %{$data->{'SubjectData'}}){
    my $hGenos = $info->{'genotypes'};
    for my $marker (keys %{$data->{'AlleleData'}}){
      if (not exists $hGenos->{$marker}){
          my $msg = "Subject $subject has no genotype for marker $marker";
          FormatError($msg);
      }
    }
  }
  return $aBadMarkers;
}

sub Usage()
{
    print << 'EOH';

prephappy --alleles=chr1.alleles,chr2.alleles --ped=chr1.ped,chr2.ped
        [ --add_noise_prob=<float> ]
        [ --founder_probs=<string> ]
        [ --map=any.map,another.map ]
        [ --mapfile_cM_column=<string> ]
        [ --outdir=PREPHAPPY_GENOTYPES/ ]
        [ --mismatch2na=0 ]
        [ --padsubjects=0 ]
        [ --ped_delimiter='\s+' ]
        [ --rm_uninformative=0 ]   
        [ --allow_uninformative_markers=0 ]   
        [ --allow_uninformative_alleles=0 ]   
     	  [ --skipmarkers=<string> ]

  add_noise_prob : a model of genotyping error. Specifies the probability $theta$ that at each locus
the  allele call  is  a random  draw  from  the set  of  available allele  types  rather than  from
p(allele|founder). This models genotyping error such  that in a population of equiprobable founders
with  biallelic genotypes,  the rate  of  miscalled genotypes  is approximately  $theta$ (in  fact,
$theta$  -  1/4*$theta$^2).  If  founders  are not  equiprobable,  then  requires  --founder_probs.

  alleles : alleles files specified as comma-separated list or/and file patterns (see examples)
  
  allow_uninformative_alleles=0 : if set to zero (default) then prephappy throws an exception when it encounters an allele in the ".alleles" file that is equiprobable for all founders (and is not the NA pseudo-allele). Setting this to 1 skips this check. See related options allow_uninformative_markers and rm_uninformative.

  allow_uninformative_markers=0 : if set to zero (default) then prephappy throws an exception when it encounters a marker in the ".alleles" file whose alleles are all equiprobable for all founders. See related options allow_uninformative_alleles and rm_uninformative.      
  
  founder_probs : optionally specify prior founder probabilities as comma-separated list. Only  relevant  for  some  options   (eg,  --add_noise_prob).  Default  is  equiprobable  founders.

  mapfile_cM_column : specify column in mapfile corresponding to centiMorgan position and use those cM positions in place of those in the alleles file(s).

  mismatches2na=1 :	warns of inconsistent alleles, replacing them with NAs

  padsubjects=1 : sets missing genotypes for missing subjects as NA

  ped_delimiter : 	specifies what separates columns in the ped file, eg, '\s', '\t'

  rm_uninformative=0 : filtering of uninformative markers. If set to 2 then prephappy will remove markers possessing one or more uninformative alleles (ie, alleles that are equiprobable for all founders). If set to 1 then prephappy will remove any markers with entirely uninformative alleles (ie, all alleles are equiprobable across founders).

  skipmarkers : skips markers as specified by a comma-separated list (eg, 'rs314321,rs489233') or the name of a file containing a whitespace-separated list

Examples: 

prephappy --alleles="old.*.alleles",new.chr3.alleles --ped="old.*.ped",new.chr3.ped 

EOH
}


##-----------------------------------------------
## Parse command line

my $outDir = "./PREPHAPPY_GENOTYPES";

my %options = ();
my $correctArgList	= GetOptions(\%options,
  'h',
  'add_noise_prob=f',
  'alleles=s',
  'founder_probs=s',
  'ped=s',
  'map=s',
  'skipmarkers=s',
  'outdir=s'              => \$outDir,
  'allow_uninformative=i' => \$ALLOW_UNINFORMATIVE_MARKERS,
  'mismatch2na=i'         => \$CONVERT_MISMATCHES_TO_NA,
  'padsubjects=i'         => \$PAD_MISSING_SUBJECTS,
  'ped_delimiter=s'       => \$PED_DELIMITER,
  'rm_uninformative=i'    => \$REMOVE_UNINFORMATIVE,  
  'trim=i'                => \$TRIM_WHITESPACE,
  'mapfile_cM_column=s'   => \$MAP_CM_COLUMN,
  );

unless (exists $options{'alleles'} and exists $options{'ped'}
        and $correctArgList and not exists $options{'h'})
{
    Usage();
    exit(1);
}

my $aAllelesFiles = [map {glob $ARG} split m/,/, $options{'alleles'} ];
my $aPedFiles     = [map {glob $ARG} split m/,/, $options{'ped'} ];
if (scalar(@$aAllelesFiles)!=scalar(@$aPedFiles) or 0==@$aAllelesFiles)
{
    FormatError("Must have equal number of alleles files and ped files");
}
my $aMapFiles = [];
if (exists $options{'map'})
{
    $aMapFiles = [split m/,/, $options{'map'}];
}
my $aSkipMarkers = [];
if (exists $options{'skipmarkers'})
{
	my $string = $options{'skipmarkers'};
	if (FileExists($string))
	{
		my $ist = OpenFilesForReading($string);
		$aSkipMarkers = [split(m/\s+/, join("", $ist->getlines))];
	}
	else
	{
    	$aSkipMarkers = [split m/,/, $options{'skipmarkers'}];
	}
}

mkpath($outDir, 1, 0755);

## Read data

my $data = undef;
for (my $i=0; $i<@$aAllelesFiles; $i++)
{
    my $newData = ReadData($aAllelesFiles->[$i], $aPedFiles->[$i]);
    $data = CombineData($data, $newData);
}

for my $mapFile (@$aMapFiles)
{
    $data = ReadMap($data, $mapFile);
}
$data = RemoveMarkers($data, $aSkipMarkers, true);

my $aBadMarkers = CheckData($data);
if (0!=Array::Length($aBadMarkers)){
  $data = RemoveMarkers($data, $aBadMarkers, false);
}

if (defined $options{'add_noise_prob'})
{
	my $noiseProb = $options{'add_noise_prob'};
	if ($noiseProb < 0 or $noiseProb >1)
	{
		die "Bad option: noise prob must be between 0 and 1\n";
	}
	my $numFounders  = Array::Length($data->{'StrainOrder'});
	my $hFounderProbs = Hash::New(
			$data->{'StrainOrder'},
			Array::Rep(1/$numFounders, "times"=>$numFounders));
	AddNoiseProb($data, $noiseProb, $hFounderProbs);
}

#----- output ----

for my $chr (ListChromosomes($data)){
  WriteChrFiles($data, $chr, "$outDir/chr$chr.alleles", "$outDir/chr$chr.ped");
}

print "Writing map file\n";
WriteMap($data, "$outDir/map.txt");



#if (FileNotEmpty($storeFile))
#{
#    my $oldData = LoadStore($storeFile);
#    $data = CombineData($oldData, $data);
#}

#SaveStore($data, $storeFile);
