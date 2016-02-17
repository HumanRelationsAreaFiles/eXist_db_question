xquery version "3.1";

module namespace timeCoverage = "http://hraf.yale.edu/eHRAF/cultureChange/timeCoverage";

(:~
 : Time Coverage 
 : every culture change has a time coverage. This is sometimes
 : referred to a date[@type="coverage"]. The functions in this module
 : handle common tasks commonly related to Time Coverage. 
 : 
 : @author Matthew G. Roth <matthew.g.roth@yale.edu>
 :)



(:~
 : make
 :    a function that returns the XML date@coverage's
 :
 :    @param $timeCoverage {array} - containing the time coverages 
 :    @return sequence of time coverages
 :)
declare function timeCoverage:make($timeCoverage as array(*)) {
    let $resp := 
        for $coverage in $timeCoverage?*
            let $date := 
                if ($coverage?start ='0' and $coverage?end = '0') 
                    then  <date type="coverage" period="Not Specified">Not Specified</date>
                    else if ($coverage?period != '') then
                    <date type="coverage" period="{$coverage?period}">{
                        concat($coverage?start, ' ',
                            $coverage?startUnit, ' - ',
                            $coverage?end, ' ',
                            $coverage?endUnit)}
                    </date>
                    else  
                    <date type="coverage">{
                        concat($coverage?start, ' ',
                            $coverage?startUnit, ' - ',
                            $coverage?end, ' ',
                            $coverage?endUnit)}
                    </date>
           return $date
           
    return $resp
};


(:~
 : update
 :  update culture change with new time coverage
 : 
 :  @param $pages array of pages 
 :  @param $length  the amount of culture changes to select 
 :  @param $doc the document we are updating
 :  @param $tcs the new time coverage element(s)
 :  @return empty sequence
 :  TODO: determine if cultureChange should be replaced or if one needs to be inserted
 :)
declare function timeCoverage:update($pages, $length, $doc, $tcs) {
    let $cultureChanges := $doc//culture.change[@pageEid=(array:subarray($pages,1,$length))]
    let $resp := (# exist:batch-transaction #) { 
        for $cc at $pos in $cultureChanges
        let $newCC := element { node-name($cc) } 
                    {$cc/@*[name()!= 'pageEid'],
                    attribute pageEid {$pages($pos)},
                    $cc/*[not(self::date[@type="coverage"])],
                    $tcs}      
         return update replace $cc with $newCC 
         }
    
    return $resp
};


(:~
 : compare_time_coverage
 :   function that compares two times coverages to determine if they are equal
 :
 :    @param $timeCoverages - timeCoverage to test
 :    @param $testCoverages - the timeCoverage to test against
 :    @return xs:boolean value of equalivilence
 :)
 declare function timeCoverage:compare($timeCoverages as node()*, 
                                         $testCoverages as node()*) as xs:boolean {
                                         
    let $resp as xs:boolean := 
        if (count($timeCoverages) = count($testCoverages)) 
            then let $comparissons := 
                for $timeCoverage at $pos in $timeCoverages
                    let $testCoverage:= $testCoverages[$pos]
                    let $comp := if ($timeCoverage/text() = $testCoverage/text())
                                    then 1
                                    else 0
                    return $comp
               return if (contains($comparissons, 0))
                        then boolean(0)
                        else boolean(1)
                   
        else boolean(0)
        
    return $resp
};
