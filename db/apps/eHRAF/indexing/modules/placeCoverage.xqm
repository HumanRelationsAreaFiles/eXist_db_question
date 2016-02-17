xquery version "3.1";

module namespace placeCoverage = "http://hraf.yale.edu/eHRAF/cultureChange/placeCoverage";

(:~
 : Place Coverage 
 : every culture change has a place coverage. The functions in this module
 : handle common tasks commonly related to Place Coverage
 : 
 : @author Matthew G. Roth <matthew.g.roth@yale.edu>
 :)


(:~
 : make
 :    a function that returns the XML place@coverage's
 : 
 :    @param $placeCoverage {array} - an array containing place coverages
 :    @return seqeuence of place coverages
 :)
declare function placeCoverage:make($placeCoverage as array(*)) {
    let $resp := 
        for $coverage in $placeCoverage?*
            return <place type="coverage">{$coverage}</place>
    return $resp
};




(:~
 : compare
 :    function that compares two place coverages to determine if they are equal
 :
 :    @param $placeCoverages - the place coverage to test
 :    @param $testCoverages - the place coverage to test against
 :    @return xs:boolean value of equalivilence
 :)
 declare function placeCoverage:compare($placeCoverages as node()*,
                                                         $testCoverages as node()*) as xs:boolean {
    let $resp as xs:boolean := if (count($placeCoverages) = count($testCoverages)) 
        then let $comparissons :=
            for $placeCoverage at $pos in $placeCoverages
                let $testCoverage := $testCoverages[$pos]
                let $comp := if ($placeCoverage/text() = $testCoverage/text())
                                then 1
                                else 0
                return $comp
            return if (contains($comparissons, 0))
                    then boolean(0)
                    else boolean(1)
        
        (: differeing counts :)
        else boolean(0)
        
    return $resp        
 };