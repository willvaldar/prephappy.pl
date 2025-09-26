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

package Array2d;
use strict;
use English;
use StdDefs;
use Assert;
use Array;
use NamedArgs;

my $RECORD_START = "#begin#Array2d\n";
my $RECORD_END   = "#end#Array2d\n";

sub Flatten($)
{
    my $array2d = shift;
    my $flatArray = [];

    for my $array (@$array2d)
    {
        push @$flatArray, @$array;
    }
    return $flatArray;
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
        $line =~ m/^(\S+)\s+(\S+)\s+(\S.*)$/;
        $array->[$1][$2] = $3;
    }
    return $array;
}

sub Array2d::Matrix
# nrow is the 1st dimension
# ncol is the 2nd dimension
{
    my($data, $hArgs) = NamedArgs::Parse(\@ARG, 1,
        {'optional'=> {
                'dim1'        => undef,
                'dim2'        => undef,
                'bydim1'      => false}
        });

    my $dim1 = $hArgs->{'dim1'};
    my $dim2 = $hArgs->{'dim2'};

    if (VarType::IsArrayRef($data))
    {
        if (not defined $dim1)
        {
            if (not defined $dim2)
            {
                $dim1 = @$data;
                $dim2 = 1;
            }
            else
            {
                $dim1 = @$data/$dim2;
            }
        }
        elsif (not defined $dim2)
        {
            $dim2 = @$data/$dim1
        }

        my $array2d = [];
        my $k = 0;
        if ($hArgs->{"bydim1"})
        {
            for (my $j = 0; $j<$dim2; $j++)
            {
                for (my $i = 0; $i<$dim1; $i++)
                {
                    $array2d->[$i][$j] = $data->[$k++];
                    return $array2d if $k==@$data;
                }
            }
        }
        else
        {
            for (my $i = 0; $i<$dim1; $i++)
            {
                for (my $j = 0; $j<$dim2; $j++)
                {
                    $array2d->[$i][$j] = $data->[$k++];
                    return $array2d if $k==@$data;
                }
            }

        }
    }
    Fatal("not yet implemented\n");
}

sub New
{
    my $dim1Size = $ARG[0] || WrongNumArgsError();
    my $dim2Size = (2 <= @ARG) ? $ARG[1] : 0;
    my $value    = (3 <= @ARG) ? $ARG[2] : 0;

    my $array2d = [];
    $#{$array2d} = $dim1Size -1;

    for (my $i=0; $i<$dim1Size; $i++)
    {
        if ($dim2Size)
        {
            $array2d->[$i] = Array::New($dim2Size, $value);
        }
        else
        {
            $array2d->[$i] = [];
        }
    }
    return $array2d;
}

sub NumElements($)
{
    my $array2d = shift;

    my $sum = 0;
    for my $array (@$array2d)
    {
        $sum += scalar(@$array);
    }
    return $sum;
}

sub Reset($$$$)
{
    my($array2d, $value) = @ARG;

    for my $array (@$array2d)
    {
        for my $elem (@$array)
        {
            $elem = $value;
        }
    }
}

sub Save($$)
{
    my($ost, $array2d) = @ARG;

    $ost->print($RECORD_START);
    my $i = 0;
    for my $array (@$array2d)
    {
        my $j = 0;
        for my $elem (@$array)
        {
            $ost->print("$i\t$j\t$elem\n");
            $j++;
        }
        $i++;
    }
    $ost->print($RECORD_END);
}

sub SwapAxes ($)
{
    return Transpose($ARG[0]);
}

sub Transpose($)
{
    my $array2d = shift;

    my $swapped = [];
    for (my $i=0; $i<@$array2d; $i++)
    {
        for (my $j=0; $j<@{$array2d->[$i]}; $j++)
        {
            $swapped->[$j][$i] = $array2d->[$i][$j];
        }
    }
    return $swapped;
}


true;
