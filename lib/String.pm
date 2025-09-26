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

package String;
use strict;
use English;
use StdDefs;
use Exporter;
use Array;
use base qw(Exporter);
use vars qw(@EXPORT_OK);

@EXPORT_OK = qw(
        Trim
        Chomp
        Columnify
        CountChar
        UniqueChars
        );

sub Chomp($)
{
    my $s = shift;
    $s =~ s/[\r\n]+$//;
    return $s;
}

sub Columnify
{
    my($colw, @aData) = @ARG;

    return sprintf( "%-${colw}.${colw}s" x scalar(@aData), @aData );
}

sub CountChar($$)
{
    my($string, $char) = @ARG;

    my $count = 0;
    $count++ while $string =~ m/$char/go;
    return $count;
}

sub Trim($)
{
    my $text = shift;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    return $text;
}

sub TrimArray($)
{
    my $array = shift;
    for my $text (@$array)
    {
        $text =~ s/^\s+//;
        $text =~ s/\s+$//;
    }
    return $array;
}

sub UniqueChars($)
{
    my $text = shift;
    return Array::Unique([split m//, $text]);
}

sub OrderedStrcat($$$)
{
    my($a, $b, $token) = @ARG;

    return $a lt $b ? $a.$token.$b : $b.$token.$a;
}


true;
