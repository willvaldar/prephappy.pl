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

use strict;
#--------------------------------------------------------------------------
package CRingNode;
use English;
use StdDefs;

sub new($$)
{
    my($class, $value) = @ARG;
    my $this = {
            'leftLink' => null,
            'rightLink' => null,
            'value' => $value,
            };
    return bless $this, $class;
}

sub getLeft($)  {$ARG[0]->{'leftLink'}}
sub getRight($) {$ARG[0]->{'rightLink'}}
sub getValue($) {$ARG[0]->{'value'}}

sub setLeft($$)  {$ARG[0]->{'leftLink'} = $ARG[1]}
sub setRight($$) {$ARG[0]->{'rightLink'} = $ARG[1]}
        
#--------------------------------------------------------------------------
package CRing;
use English;
use StdDefs;
use Array;

sub new
{
    my($class) = shift;
    my $array = @ARG ? shift
                     : [];
    my $this = {
            'length' => scalar(@$array),
            'head' => _MakeRing($array),
            };
    return bless $this, $class;
}

sub get($$)
{
    my($this, $i) = @ARG;
    return $this->_getNode($i)->getValue;
}

sub getSize($) {$ARG[0]{'length'}}

sub nextElement($)
{
    my $this = shift;
    my $currNode = $this->_getHead;
    $this->rotate(1);
    return $currNode->getValue;
}

sub rotate($$)
{
    my($this, $nMoves) = @ARG;
    
    $this->_setHead($this->_getNode($nMoves));
    
    return $this;
}

sub _getHead($) {$ARG[0]->{'head'}}

sub _getNode($$)
{
    my($this, $nPlaces) = @ARG;
    
    my $node = $this->_getHead;
    if ($nPlaces >= 0)
    {
        for (my $i=1; $i<=$nPlaces; $i++)
        {
            $node = $node->getRight;
        }
    }
    else # $nPlaces is negative
    {
        for (my $i=1; $i<=-$nPlaces; $i++)
        {
            $node = $node->getLeft;
        }
    }
    return $node;
}
  
sub _setHead($) {$ARG[0]->{'head'} = $ARG[1]}

sub _MakeRing($)
{
    my($array) = @ARG;
    
    my $aNodes = Array::Transform($array, [], sub{new CRingNode($ARG[0])});
    my $nNodes = scalar(@$aNodes);
    
    for (my $i=0; $i<$nNodes; $i++)
    {
        my $leftIndex = (0==$i)
                ? $nNodes-1
                : $i-1;
        my $rightIndex = ($nNodes-1==$i)
                ? 0
                : $i+1;
        $aNodes->[$i]->setLeft($aNodes->[$leftIndex]);
        $aNodes->[$i]->setRight($aNodes->[$rightIndex]);
    }
    return $aNodes->[0];
}
1;
