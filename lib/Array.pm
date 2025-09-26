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

package Array;
use strict;
use English;
use StdDefs;
use Assert;
use Hash;
use CRing;
use VarType;
use Debug;

use constant NOT_FOUND => -1;

my $RECORD_START = "#begin#Array\n";
my $RECORD_END   = "#end#Array\n";

sub Array::Add
{
    my @arrayList = @ARG;

    WrongNumArgsError() unless @ARG;

    my $nElem = scalar(@{$arrayList[0]});
    my $aAdded = Array::New($nElem, 0);
    for my $array (@arrayList)
    {
        if (VarType::IsArrayRef($array))
        {
            for (my $i=0; $i<@$aAdded; $i++)
            {
                $aAdded->[$i] += $array->[$i];
            }
        }
        else
        {
            for my $elem (@$aAdded)
            {
                $elem += $array;
            }
        }
    }
    return $aAdded;
}

sub Array::All
{
    my $array = $ARG[0];
    my $predFunc = (2==@ARG) ? $ARG[1]
                             : 0;
    for my $elem (@$array)
    {
        if ($predFunc)
        {
            if (not $predFunc->($elem))
            {
                return false;
            }
        }
        else
        {
            return false if not $elem;
        }
    }
    return true;
}

sub Array::Any
{
    my $array = $ARG[0];
    my $predFunc = (2==@ARG) ? $ARG[1]
                             : 0;
    for my $elem (@$array)
    {
        if ($predFunc)
        {
            if ($predFunc->($elem))
            {
                return true;
            }
        }
        else
        {
            return true if $elem;
        }
    }
    return false;
}

sub Array::Apply($$)
{
    my($array, $func) = @ARG;

    return Array::Transform($array, [], $func);
}

sub Array::ApplyInSitu($$)
{
    my($array, $func) = @ARG;

    for my $elem (@$array)
    {
        $elem = $func->($elem);
    }
    return $array;
}


sub Array::Back($)
{
    my $array = shift;
    return $array->[scalar(@$array)-1];
}

sub Array::Common
{
    my @arrayList = @ARG;

    my $flatUniqArrays = [];
    for my $array (@arrayList)
    {
        push @$flatUniqArrays, @{ Unique($array) };
    }
    my $hElemFreq = ElementFrequencies($flatUniqArrays);

    my $aCommon = [];
    while( my($elem, $elemFreq) = each %$hElemFreq )
    {
        if( scalar(@arrayList) == $elemFreq )
        {
            push @$aCommon, $elem;
        }
    }
    return $aCommon;
}

sub Array::ConditionToMask($$)
{
    my($array, $predicate) = @ARG;

    my $mask = [];
    for (my $i=0; $i<@$array; $i++)
    {
        if ($predicate->($array->[$i]))
        {
            push @$mask, true;
        }
        else
        {
            push @$mask, false;
        }
    }
    return $mask;
}

sub Array::ContainsString($$)
{
    my($aIn, $value) = @ARG;
    for my $elem (@$aIn)
    {
        return true if $elem eq $value;
    }
    return false;
}


sub Copy($)
{
    my $array = shift;
    return [@$array];
}

sub CopyRange($$$)
{
    my($array, $start, $end) = @ARG;

    my $copy = [];
    for (my $i=$start; $i<=$end; $i++)
    {
        push @$copy, $array->[$i];
    }
    return $copy;
}

sub Array::CountUnique
{
    return scalar(@{Array::Unique(@ARG)});
}

sub Diff($$)
{
    my( $array1, $array2 ) = @ARG;

    my $aArray1Not2 = [];
    my $aArray2Not1 = [];
    my $aIntersect = [];

    my %hArray1UniqueElem = ();
    my %hArray2UniqueElem = ();
    my $hUnionElemFreq;

    my $elem;
    my $elemFreq;

    #---------------------------------
    #- get unique elements of each set
    #---------------------------------

    @hArray1UniqueElem{ @$array1 } = ();
    @hArray2UniqueElem{ @$array2 } = ();

    #--------------------------------------------------
    #- get the union of set1(unique) u set2(unique)
    #- make a frequency table of elements in this union
    #--------------------------------------------------

    $hUnionElemFreq = ElementFrequencies([ keys %hArray1UniqueElem, keys %hArray2UniqueElem ]);

    while( ($elem, $elemFreq) = each %$hUnionElemFreq )
    {
        #----------------------------------------------------
        #- non-intersection elements will appear only once...
        #----------------------------------------------------
        if( 1 == $elemFreq )
        {
            if(exists $hArray1UniqueElem{ $elem } )
            {
                push @$aArray1Not2, $elem;
            }
            else
            {
                push @$aArray2Not1, $elem;
            }
        }
        #--------------------------------------------------
        #- ...while intersection elements will appear twice
        #--------------------------------------------------
        else
        {
            push @$aIntersect, $elem;
        }
    }

    Prefer( wantarray, "Client should accept array from method" );

    return ( $aArray1Not2, $aArray2Not1, $aIntersect );
}

# forward decl
sub Array::Dimensionality($);
#

sub Array::Dimensionality($)
{
    my $array = shift;

    if (VarType::IsArrayRef($array))
    {
        return 1 + Array::Dimensionality($array->[0]);
    }
    return 0;
}

sub Array::Divide($$$)
{
	my($aIn, $aOut, $divisor) = @ARG;
	
	if (VarType::IsArrayRef($divisor))
	{
		Fatal("Divisor array must be same length as target") if @$aIn!=@$divisor;
		for (my $i=0; $i<@$aIn; ++$i)
		{
			$aOut->[$i] = $aIn->[$i]/$divisor->[$i];
		}
	}
	elsif ($aIn==$aOut)
	{
		for my $elem (@$aOut) {$elem /= $divisor;}
	}
	else
	{
		for (my $i=0; $i<@$aIn; ++$i)
		{
			$aOut->[$i] = $aIn->[$i]/$divisor;
		}
	}
	return $aOut;
}

sub ElementFrequencies($)
{
    my ($array) = @ARG;
    my $hFreq = {};

    for my $elem ( @$array )
    {
        if( not exists($hFreq->{$elem}) )
        {
            $hFreq->{$elem} = 1;
        }
        else
        {
            $hFreq->{$elem}++;
        }
    }
    return $hFreq;
}

sub ElementRelativeFreqs($)
{
    my $array = shift;

    my $hFreqs = ElementFrequencies($array);

    for my $key (keys %$hFreqs)
    {
        $hFreqs->{$key} = $hFreqs->{$key} / scalar(@$array);
    }
    return $hFreqs;
}

sub Array::EqualContents($$)
{
    my($arrayA, $arrayB) = @ARG;

    my $hFreqA = Array::ElementFrequencies($arrayA);
    my $hFreqB = Array::ElementFrequencies($arrayB);

    return Hash::Equals($hFreqA, $hFreqB);
}

sub Array::EqualUnique($$)
{
    my($arrayA, $arrayB) = @ARG;

    my $uniqA = Array::Unique($arrayA);
    my %seenB = ();
    @seenB{@$arrayB} = ();

    return false unless @$uniqA == scalar keys %seenB;

    for my $key (@$uniqA)
    {
        return false unless exists $seenB{$key};
    }
    return true;
}

sub Equals($$)
{
    my($arrayA, $arrayB) = @ARG;

    # compare sizes
    return false if scalar(@$arrayA) != scalar(@$arrayB);

    # compare elements
    for (my $i=0; $i<@$arrayA; $i++)
    {
        return false if $arrayA->[$i] ne $arrayB->[$i];
    }
    return true;
}

sub Exclude($$)
{
    my($array, $not) = @ARG;
    my $hNot = Hash::New(VarType::AsArray($not), true);

    my $out = [];
    for my $elem (@$array)
    {
        unless (exists $hNot->{$elem})
        {
            push @$out, $elem;
        }
    }
    return $out;
}

sub Array::FindFirst($$)
{
    my($array, $target) = @ARG;

    for (my $i=0; $i<@$array; $i++)
    {
        return $i if $array->[$i] eq $target;
    }
    return NOT_FOUND;
}

sub Array::FindFirstIf($$)
{
    my($array, $func) = @ARG;

    for (my $i=0; $i<@$array; $i++)
    {
        return $i if $func->($array->[$i]);
    }
    return NOT_FOUND;
}

sub Generate($$$)
{
    my($array, $nElem, $func) = @ARG;

    for (my $i=0; $i<$nElem; $i++)
    {
        $array->[$i] = &$func;
    }
    return $array;
}


sub GroupElementsBy($$)
{
    my($array, $groupingFunc) = @ARG;

    my $hm = {};    # hash of arrays
    for my $elem (@$array)
    {
        my $key = $groupingFunc->($elem);
        unless (exists $hm->{$key})
        {
            $hm->{$key} = [];
        }
        push @{$hm->{$key}}, $elem;
    }
    return [values %$hm];
}

sub HashByIndex($)
{
    my $array = shift;

    warn "deprecated method\n";

    return HashElement2Index($array);
}

sub HashElement2Index($)
{
    my $array = shift;
    my $hash = {};

    my $i = 0;
    for my $elem (@$array)
    {
        $hash->{$elem} = $i++;
    }
    return $hash;
}

sub HashIndex2Element($)
{
    my $array = shift;
    my $hash = {};
    for (my $i=0; $i<@$array; $i++)
    {
        $hash->{$i} = $array->[$i];
    }
    return $hash;
}

sub HasIntersect
{
    my $aCommon = Array::Common(@ARG);
    return 0 != @$aCommon
}

sub IndicesToMask($$)
{
    my($nElem, $aIndices) = @ARG;

    my $mask = Array::New($nElem, false);
    for my $index (@$aIndices)
    {
        $mask->[$index] = true;
    }
    return $mask;
}

sub Array::InvertMask($)
{
    my $mask = shift;
    return Array::Transform($mask, [], sub{$ARG[0]?false:true});
}

sub IsSubSet($$)
{
    my($aSmall, $aBig) = @ARG;

    my $hBig = Array::ToHash($aBig, sub{$ARG[0]}, sub{true});

    for my $elem (@$aSmall)
    {
        if (not exists $hBig->{$elem})
        {
            return false;
        }
    }
    return true;
}


sub Join
{
    my(@aArrays) = @ARG;

    my $aJoined = [];
    for my $array (@aArrays)
    {
        push @$aJoined, @$array;
    }
    return $aJoined;
}

sub Array::LastIndex($)
{
    return scalar(@{$ARG[0]})-1;
}

sub Length($)
{
    return scalar(@{$ARG[0]});
}

sub Load($)
{
    my $ist = shift;

    # skip to record start
    return undef if $ist->eof;
    while ($ist->getline ne $RECORD_START)
    {
        return undef if $ist->eof;
    }

    my $array = [];
    while ((my $line = $ist->getline) ne $RECORD_END)
    {
        if ($ist->eof)
        {
            Fatal("Premature EOF encountered when reading object from file");
        }
        $line =~ m/^(\S+)\s+(\S.*)$/;
        $array->[$1] = $2;
    }
    return $array;
}

sub Array::Mask($$)
{
    my($array, $mask) = @ARG;

    if (@$array != @$mask)
    {
        Fatal("mask must be as long as array");
    }

    my $newArray = [];
    for (my $i=0; $i<@$array; $i++)
    {
        if ($mask->[$i])
        {
            push @$newArray, $array->[$i];
        }
    }
    return $newArray;
}

sub Array::Match($$)
{
    my($aAll, $aTargets) = @ARG;

    my $hTarget2FoundIndex = Hash::New($aTargets, NOT_FOUND);

    my $i=0;
    for my $elem (@$aAll)
    {
        if (exists $hTarget2FoundIndex->{$elem}
            and
            $hTarget2FoundIndex->{$elem} eq NOT_FOUND)
        {
            $hTarget2FoundIndex->{$elem} = $i;
        }
        $i++
    }
    my $aIndices = [];
    for my $target (@$aTargets)
    {
        push @$aIndices, $hTarget2FoundIndex->{$target};
    }
    return $aIndices;
}

sub Max($)
{
    my ($array) = @ARG;

    my $elem;
    my $max;
    my $firstIteration = true;

    for $elem (@$array)
    {
        if($firstIteration)
        {
            $max = $elem;
            $firstIteration = false;
        }
        elsif($elem > $max)
        {
            $max = $elem;
        }
    }
    return $max;
}

sub Array::Mean($)
{
    my $array = shift;

    return Array::Sum($array) / scalar(@$array);
}

sub Min($)
{
    my ($array) = @ARG;

    my $elem;
    my $min;
    my $firstIteration = true;

    for $elem (@$array)
    {
        if($firstIteration)
        {
            $min = $elem;
            $firstIteration = false;
        }
        elsif($elem < $min)
        {
            $min = $elem;
        }
    }
    return $min;
}

sub ModalFreq($)
{
    my $array = shift;

    return Max([values %{ElementFrequencies($array)}]);
}

sub Modes($)
{
    my $array = shift;

    my $hFreq = Array::ElementFrequencies($array);
    my $modeFreq = Array::Max([values %$hFreq]);
    my @aModes = ();
    while (my($elem, $freq) = each %$hFreq)
    {
        push @aModes, $elem if $modeFreq == $freq;
    }
    return @aModes;
}

sub Array::Multiply($$$)
{
	my($aIn, $aOut, $factor) = @ARG;
	
	if (VarType::IsArrayRef($factor))
	{
		Fatal("Divisor array must be same length as target") if @$aIn!=@$factor;
		for (my $i=0; $i<@$aIn; ++$i)
		{
			$aOut->[$i] = $aIn->[$i]*$factor->[$i];
		}
	}
	elsif ($aIn==$aOut)
	{
		for my $elem (@$aOut) { $elem *= $factor };
	}
	else
	{
		for (my $i=0; $i<@$aIn; ++$i)
		{
			$aOut->[$i] = $aIn->[$i]*$factor;
		}
	}
	return $aOut;
}

sub New
#_ either     NewArray( size ) or
#_         NewArray( size, value )
#_ if size == 0, will confess with WrongNumArgsError
{
    my $size    = $ARG[0] || WrongNumArgsError();
    my $array;

    if(2 == @ARG)
    {
        $array = [($ARG[1]) x $size ];
    }
    else
    {
        $array = [];
        $#{$array} = $size - 1;
    }
    return $array;
}

sub NotEmpty($)
{
    return scalar(@{$ARG[0]});
}

sub NumElements
{
    return scalar(@{$ARG[0]});
}

sub NumUnique
{
    my @arg = @ARG;
    Warn("Deprecated method 'NumUnique'");
    return CountUnique(@arg);
}

sub Array::NextPermutation($)
# based on the C++ STL's next.permutation()
{
    my $array = shift;
    if (2>@$array) {return false;}

    my $last = Array::Length($array) - 1;
    my $i = $last;
    for (;;)
    {
        my $ii = $i--;
        if ($array->[$i] lt $array->[$ii])
        {
            my $j = $last+1;
            while (not ($array->[$i] lt $array->[--$j])){}
            Array::SwapElements($array, $i, $j);
            Array::ReverseRange($array, $ii, $last);
            return true;
        }
        if (0==$i)
        {
            Array::ReverseRange($array, 0, $last);
            return false;
        }
    }
}

sub Paste
{
    my $aIns = [];
    my $aOptions = [];

    for my $arg (@ARG)
    {
        if (VarType::IsArrayRef($arg))
        {
            push @$aIns, new CRing($arg);
        }
        else
        {
            push @$aOptions, $arg;
        }
    }
    my %hArg = @$aOptions;

    Assert::CheckArgHash(\%hArg,
            'optional' => [qw(sep collapse)],
            );

    my $sep = exists $hArg{'sep'}
            ? $hArg{'sep'}
            : " ";

    my $numItems = Array::Max(
            Array::Transform($aIns, [], sub{$ARG[0]->getSize})
            );

    my $out = [];
    for (my $i=0; $i<$numItems; $i++)
    {
        my $string = "";
        for (my $r=0; $r<@$aIns; $r++)
        {
            $string .= $sep unless 0==$r;
            $string .= $aIns->[$r]->nextElement;
        }
        push @$out, $string;
    }

    if (exists $hArg{'collapse'})
    {
        return join($hArg{'collapse'}, @$out);
    }
    return $out;
}

sub Array::Plus($$$)
{
	my($aIn, $aOut, $plus) = @ARG;
	
	if (VarType::IsArrayRef($plus))
	{
		Fatal("Divisor array must be same length as target") if @$aIn!=@$plus;
		for (my $i=0; $i<@$aIn; ++$i)
		{
			$aOut->[$i] = $aIn->[$i]+$plus->[$i];
		}
	}
	elsif ($aIn==$aOut)
	{
		for my $elem (@$aOut) {$elem += $plus;}
	}
	else
	{
		for (my $i=0; $i<@$aIn; ++$i)
		{
			$aOut->[$i] = $aIn->[$i]+$plus;
		}
	}
	return $aOut;
}

sub RandomElement($)
{
    my $array = shift;
    return $array->[int rand scalar @$array];
}

sub Range($)
{
    my ($array) = @ARG;

    my $max;
    my $min;
    my $firstIteration = true;

    for my $elem (@$array)
    {
        if($firstIteration)
        {
            $max = $elem;
            $min = $elem;
            $firstIteration = false;
        }
        elsif($elem < $min)
        {
            $min = $elem;
        }
        elsif($elem > $max)
        {
            $max = $elem;
        }
    }
    my $range = abs( $max - $min );

    return wantarray ?
        ($range, $min, $max):
        $range;
}

sub Array::Rep
# modeled after the S-plus function rep
# Will ignore 'length' if 'times' is given
{
    my($in, %hArg) = @ARG;

    $in = VarType::AsArray($in);

    Assert::CheckArgHash(\%hArg,
            'optional' => [qw(times length each)],
            );
    unless (exists $hArg{'times'} or exists $hArg{'length'})
    {
        Error::Fatal("Method must have one of times or length as args");
    }
    my $each = exists $hArg{'each'}
            ? $hArg{'each'}
            : 1;
    my $length = exists $hArg{'times'}
            ? scalar(@$in)*$hArg{'times'}*$each
            : $hArg{'length'};
    my $out = [];
    while(true)
    {
        for my $elem (@$in)
        {
            for (my $i=0; $i<$each; $i++)
            {
                push @$out, $elem;
                return $out if $length == @$out;
            }
        }
    }
}

sub Resize($$)
{
    my($array, $newSize) = @ARG;
    $#{$array} = $newSize - 1;
}

sub Array::ReverseRange($$$)
{
    my($array, $first, $last) = @ARG;
    @{$array}[$first..$last] = reverse @{$array}[$first..$last];
    return $array;
}


sub Shuffle($)
{
    my $array = shift;

    my $nElem = @$array;

    for (my $i=0; $i<$nElem; $i++)
    {
        my $j = int rand($nElem);

        next if $i==$j;

        # swap i and j
        my $tmp = $array->[$i];
        $array->[$i] = $array->[$j];
        $array->[$j] = $tmp;
    }
    return $array;
}


sub Save($$)
{
    my($ost, $array) = @ARG;

    $ost->print($RECORD_START);
    my $i = 0;
    for my $elem (@$array)
    {
        $ost->print("$i\t$elem\n");
        $i++;
    }
    $ost->print($RECORD_END);
}

sub Array::Size($)
{
    return scalar(@{$ARG[0]});
}

sub Array::Subset($$)
{
    my($aIn, $wantedIndices) = @ARG;

    my $aOut = [];
    for my $i (@$wantedIndices)
    {
        push @$aOut, $aIn->[$i];
    }
    return $aOut;
}

sub Array::SuccessiveDifference($)
{
    my $array = shift;
    my $diff = [];
    for (my $i=0; $i < @$array-1 ; $i++)
    {
        $diff->[$i] = $array->[$i+1] - $array->[$i];
    }
    return $diff;
}


sub Array::Sum($)
{
    my $array = shift;

    my $sum = 0;
    for my $elem (@$array)
    {
        $sum += $elem;
    }
    return $sum;
}

sub Array::SwapElements($$$)
{
    my($array, $i, $j) = @ARG;
    my $tmp = $array->[$i];
    $array->[$i] = $array->[$j];
    $array->[$j] = $tmp;
    return $array;
}

sub Array::Transform($$$)
{
    my($aIn, $aOut, $op) = @ARG;

    for (my $i=0; $i<@$aIn; $i++)
    {
        $aOut->[$i] = &$op($aIn->[$i]);
    }
    return $aOut;
}

sub ToHash
{
    2 == @ARG || 3 == @ARG or WrongNumArgsError();

    my($array, $keyFunc) = @ARG;
    my $valueFunc = (3 == @ARG) ? $ARG[2] : sub{$ARG[0]};

    my $hash = {};
    for my $elem (@$array)
    {
        $hash->{ &$keyFunc($elem) } = &$valueFunc($elem);
    }
    return $hash;
}

sub WhichMax($)
{
    my $array = shift;

    my $maxValue = $array->[0];
    my $maxIndex = 0;
    for (my $i=1; $i<@$array; $i++)
    {
        if ($maxValue < $array->[$i])
        {
            $maxValue = $array->[$i];
            $maxIndex = $i;
        }
    }
    return $maxIndex;
}

sub Array::UniqueOrdered($)
{
    my $array = shift;
    unless (@$array)
    {
        Fatal("array must be of non-zero size");
    }

    my $prev = $array->[0];
    my $uniqArray = [$prev];
    for (my $i=1; $i<@$array; ++$i)
    {
        if ($array->[$i] ne $prev)
        {
            push @$uniqArray, ($prev = $array->[$i]);
        }
    }
    return $uniqArray;
}


sub Unique
{
    if (1==@ARG){return Unique_1arg(@ARG)}
    if (2==@ARG){return Unique_2arg(@ARG)}
    WrongNumArgsError();
}

sub Unique_1arg
{
    my $array = shift;

    my %seen;

    @seen{@$array} = ();

    return [keys %seen];
}

sub Unique_2arg
{
    my($array, $cmpFunc) = @ARG;

    my $hUniq = Array::ToHash($array, $cmpFunc);
    return [values %$hUniq];
}

true;
