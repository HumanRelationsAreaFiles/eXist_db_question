xquery version "3.1";

module namespace cultureChange = "http://hraf.yale.edu/eHRAF/cultureChange";

import module namespace functx="http://www.functx.com";
import module namespace timeCoverage = "http://hraf.yale.edu/eHRAF/cultureChange/timeCoverage" 
at "xmldb:exist:///db/apps/eHRAF/indexing/modules/timeCoverage.xqm";
import module namespace placeCoverage = "http://hraf.yale.edu/eHRAF/cultureChange/placeCoverage" 
at "xmldb:exist:///db/apps/eHRAF/indexing/modules/placeCoverage.xqm";




(:~
 : Culture Change Module
 : every eHRAF document has a culture change element following each page break.
 : these contain metadata related to the page. Culture,time coverage, place
 : coverage, et al. 
 : 
 : This module provides functions to help handle tasks related to the culture
 : change in anaylsis of the document. 
 : 
 : @author Matthew G. Roth <matthew.g.roth@yale.edu>
 :)


(: location of document in the colleciton  :)
declare variable $cultureChange:svnData as xs:string := "/db/am46";


(:~
 : culture_change_array
 :  a map containing the dates and geoPlaces
 :  
 :  @param $cultureChange the culture change of the page
 :  @return map containing dates and place coverages of the page :)
declare function cultureChange:culture_change_array($cultureChange as element()?) {
    map { 
          "dates": local:parse-dates($cultureChange/date[@type="coverage"]),
          "geoPlaces": local:parse-geoPlaces($cultureChange/place[@type="coverage"])          

        }
};


(:~
 : iterate
 :    iterate over culture change object and determine the time and place coverages to update
 :
 :    @param $payload object that contains information about propagation and 
 :                    thus iteration depth
 :    @param $docID {xs:string} used to lookup the document of interest
 :    @param $num {xs:int} page number we should start at
 :)
declare function cultureChange:iterate($payload as item()*, 
                                              $docID as xs:string, 
                                              $num as xs:int) {
                                              
    let $doc := collection($cultureChange:svnData)//hraf.doc[@id=$docID]
    let $timeCoverages :=  timeCoverage:make($payload?timeCoverage)
    let $geoPlace := placeCoverage:make($payload?placeCoverage)
    let $pages :=  array { ($doc//page.break/@xml:id/string())[position() >= $num] }
    let $tcm := if ($payload("propagateTimeCoverage")) then 0 else 1
    let $pcm := if ($payload("propagatePlaceCoverage")) then 0 else 1
    
    let $indexs := local:compare($doc, $pages,1, boolean(0) , $tcm, $pcm)
    let $update_tc := timeCoverage:update($pages, $indexs?timeCoverage, $doc, $timeCoverages)
 
    return  $indexs

};




(:~
 : compare
 :   recursive function that compares the current culture change with previous culture change 
 :
 :  @param $doc we are testing
 :  @param $pages {array} of pageEids
 :  @param $pos {xs:int} position in the page array
 :  @param $lastCC {node} of previous culture change
 :  @param $tcm {xs:int} postive int representing the index of divergence
 :                       for time coverage || no match 0
 :  @param $pcm {xs:int} postive int representing the index of divergence
 :                       for place coverage || no match 0
 :  @return xs:boolean value of equalivilance 
 :) 
declare %private function local:compare($doc, 
                                          $pages as array(*), 
                                          $pos as xs:int,
                                          $lastCC as item()?,
                                          $tcm as xs:int,
                                          $pcm as xs:int)
{


    let $page := $pages($pos)
    let $cc := $doc//culture.change[@pageEid=$page]
    let $newParams  :=
        if ($lastCC) then
            let $ntcm := 
                if ($tcm < 1) then
                    let $timeCoverage := $cc/date[@type="coverage"]
                    let $testTimeCoverage := $lastCC/date[@type="coverage"]
                    return if (timeCoverage:compare($timeCoverage, $testTimeCoverage)) 
                        then 0 else $pos - 1 
                    
                else $tcm
            let $npcm :=
                if ($pcm < 1) then
                    let $placeCoverage := $cc/place[@type="coverage"]
                    let $testPlaceCoverage := $lastCC/place[@type="coverage"]
                    return if (placeCoverage:compare($placeCoverage, $testPlaceCoverage))
                        then 0 else $pos - 1
                else $pcm
            return map { "tcm": $ntcm, "pcm": $npcm }
        else if (not($lastCC) and $pos = 1) then 
            if (count($doc//culture.change)) 
                then map { "tcm": $tcm, "pcm": $pcm}
                else
                    let $ntcm := if ($tcm = 0) then array:size($pages) else $tcm 
                    let $npcm := if ($pcm = 0) then array:size($pages) else $pcm 
                    return map { "tcm": $ntcm, "pcm": $npcm }
        else map { "tcm": $tcm, "pcm": $pcm }
            
           
        
        return 
            if ($newParams?tcm > 0 and $newParams?pcm > 0) 
                then map { "timeCoverage": $newParams?tcm, "placeCoverage": $newParams?pcm }
            else local:compare($doc, $pages, $pos + 1, $cc, $newParams?tcm, $newParams?pcm)
};




(:~
 : parse-geoPlaces
 :  gather the text of each geo place
 :  
 :  @param geoPlaces - zero or many place coverages
 :  @return array of the text for each geo place
 :)
declare %private  function local:parse-geoPlaces($geoPlace as element()*) as array(*) { 
    array { for $place in $geoPlace
                return $place/text()
           }
                          
};

(:~
 : parse-dates
 :  parase dates into their component parts
 : 
 :  @param dates one of more date elements
 :  @return array of date elements split into a map containing component parts
 :)
declare %private function local:parse-dates($dates) as array(*) {
    try {
        array {
            for $date in $dates
             let $tokens := tokenize(normalize-space($date/text()), '-')
             let $map := if (lower-case($date/text()) = 'not specified') then
                     let $startYear := '0'
                     let $startUnit := 'AD'
                     let $endYear := '0'
                     let $endUnit := 'AD'
                     let $period := 'Not Specified'
                 
                     return 
                         map { 
                             'start': string-join($startYear),
                             'startUnit': string-join($startUnit),
                             'end': string-join($endYear),
                             'endUnit': string-join($endUnit),
                             'period': $period
                             }
                 
                 else if (count($tokens) eq 2) then
                     let $startYear := functx:get-matches($tokens[1], '[0-9]+')
                     let $startUnit := functx:get-matches(upper-case($tokens[1]), '[A-Z]+')
                     let $endYear := functx:get-matches($tokens[2], '\d+')
                     let $endUnit := functx:get-matches($tokens[2], '[A-Z]{2}')
                     let $period := if ($date/@period) then $date/@period else ''
                     return 
                         map { 
                             'start': string-join($startYear),
                             'startUnit': string-join($startUnit),
                             'end': string-join($endYear),
                             'endUnit': string-join($endUnit),
                             'period': $period
                             }
                else (: no range :)
                     let $startYear := functx:get-matches($tokens[1], '[0-9]+')
                     let $startUnit := functx:get-matches(upper-case($tokens[1]), '[A-Z]+')
                     let $period := if ($date/@period) then $date/@period else ''
                     
                     return 
                         map { 
                             'start': string-join($startYear),
                             'startUnit': string-join($startUnit),
                             'end': string-join($startYear),
                             'endUnit': string-join($startUnit),
                             'period': $period
                             }
              
             return $map
        } 
     } catch * { 
     
          array { concat($err:code, ": ", $err:description) }
    }

};