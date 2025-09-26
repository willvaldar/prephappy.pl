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

package NamedArgs;
use base qw(Exporter);
use Exporter;
use English;
use StdDefs;
use Assert;
use strict;
use Number;

sub NamedArgs::Parse($$$)
{
    my($aSubArgs, $numPlainArgs, $hSpec) = @ARG;

    #---------------------------
    # Check number of args given
    #---------------------------

    my $numSubArgs = scalar(@$aSubArgs);

    # check minimum number of args given
    my $numReqArgs = $numPlainArgs;
    if (exists $hSpec->{'required'})
    {
        $numReqArgs += 2*scalar(@{$hSpec->{'required'}});
    }
    unless ($numSubArgs >= $numReqArgs)
    {
        WrongNumArgsError();
    }

    # check number of args is sensible
    if (
        (Number::IsEven($numPlainArgs) and Number::IsOdd($numSubArgs))
        or
        (Number::IsOdd($numPlainArgs) and Number::IsEven($numSubArgs))
    )
    {
        WrongNumArgsError();
    }

    # check maximum number of args
    if (exists $hSpec->{'optional'})
    {
        my $numMaxArgs = $numReqArgs
                + 2*scalar keys %{$hSpec->{'optional'}};
        if ($numSubArgs > $numMaxArgs)
        {
            WrongNumArgsError();
        }
    }

    #------------------
    # Separate out args
    #------------------

    # take out unnamed args
    my @aPlainArgs = splice @$aSubArgs, 0, $numPlainArgs;
    my %hSubArgs = @$aSubArgs;

    # prepare specification
    my %hRequired = ();
    @hRequired{@{$hSpec->{'required'}}} = () if exists $hSpec->{'required'};

    my %hOptional = (exists $hSpec->{'optional'})
            ? %{$hSpec->{'optional'}}
            : ();

    # fill args, check for illegals
    while (my($name, $arg) = each %hSubArgs)
    {
        if (exists $hRequired{$name})
        {
            $hRequired{$name} = $arg;
        }
        elsif (exists $hOptional{$name})
        {
            $hOptional{$name} = $arg;
        }
        else
        {
            Fatal("Invalid argument \'$name\' to method\n");
        }
    }
    # check for unfilled requireds
    while (my($name, $val) = each %hRequired)
    {
        if (not defined($val))
        {
            Fatal("Must specify value for required argument \'$name\'");
        }
    }

    return @aPlainArgs, {%hRequired, %hOptional};
}
1;


