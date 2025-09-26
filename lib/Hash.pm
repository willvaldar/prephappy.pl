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

package Hash;
use strict;
use English;
use StdDefs;
use Assert;
use Array;
use VarType qw(IsArrayRef);


sub Hash::Apply($$)
{
    my($hash, $func) = @ARG;
    my $out = {};
    while (my($key, $value)=each %$hash)
    {
        $out->{$key} = $func->($value);
    }
    return $out;
}

sub Copy
{
    1 == @ARG || 2 == @ARG or WrongNumArgsError();

    my $hSrc = $ARG[0];
    my $hDest = 2 == @ARG ? $ARG[1] : {};

    Assert(defined($hSrc), "source not defined");
    Assert(defined($hDest), "dest not defined");


    %$hDest = %$hSrc;

    return $hDest;
}

sub Equals($$)
{
    my($hash1, $hash2) = @ARG;

    # cmp sizes
    if ((scalar keys %$hash1) != (scalar keys %$hash2))
    {
        return false;
    }
    # cmp contents
    while (my($key1, $value1) = each %$hash1)
    {
        unless (exists $hash2->{$key1} and $hash2->{$key1} eq $value1)
        {
            return false;
        }
    }
    return true;
}

sub Invert($)
{
    my ($hOriginal) = @ARG;

    my $hInverted;

    %{$hInverted} = reverse %$hOriginal;

    return $hInverted;
}

sub IsEmpty($)
{
    return 0 == scalar keys %{$ARG[0]};
}

sub Join
{
    my(@aHashes) = @ARG;

    my $hJoined = {};

    for my $hash (@aHashes)
    {
        while (my($key, $value) = each(%$hash))
        {
            $hJoined->{$key} = $value;
        }
    }
    return $hJoined;
}

sub New($$)
{
    if (IsArrayRef($ARG[1]))
    {
        return New_from2Arrays(@ARG);
    }
    else
    {
        return New_from1Array(@ARG);
    }
}

sub New_from1Array
{
    my($aKeys, $value) = @ARG;
    return New_from2Arrays($aKeys,
            Array::New(scalar(@$aKeys), $value));
}

sub New_from2Arrays
{
    my ($aKeys, $aValues) = @ARG;
    my $hash;
    @$hash{@$aKeys} = @$aValues;
    return $hash;
}

sub RandomKey($)
{
    my $hash = shift;
    my @keys = keys %$hash;
    return Array::RandomElement(\@keys);
}

sub Size($)
{
    return scalar keys %{$ARG[0]};
}

sub Hash::ToArrays($)
{
    my $hash = shift;

    my $aKeys = [];
    my $aValues = [];
    while (my($key, $value)=each %$hash)
    {
        push @$aKeys, $key;
        push @$aValues, $value;
    }
    return ($aKeys, $aValues);
}

sub Hash::Transform($$$)
{
    my($hIn, $hOut, $func) = @ARG;
    while (my($key, $value)=each %$hIn)
    {
        $hOut->{$key} = $func->($value);
    }
    return $hOut;
}

true;
