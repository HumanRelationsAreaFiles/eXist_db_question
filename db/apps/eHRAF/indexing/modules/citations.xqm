xquery version "3.1";

module namespace citations = "http://hraf.yale.edu/eHRAF/citations";
declare namespace mods =  "http://www.loc.gov/mods/v3";


(:~ 
 : This module contains functions that can be applied to mod records
 : 
 : @author Matthew G. Roth <matthew.g.roth@yale.edu>
 :)


(:~
 : title-full
 :  concatenate all title the children of titleInfo to create a full title
 : 
 :  @param $titleInfo the title of the citation record
 :  @return string with all title parts 
 :)
declare function citations:title-full($titleInfo) as xs:string? {
        let $nonSort := $titleInfo/mods:nonSort/text()
        let $mainTitle :=  
            if ($nonSort) then
                concat($nonSort, $titleInfo/mods:title/text())
            else
                $titleInfo/mods:title/text()
        let $subTitle := $titleInfo/mods:subTitle/text()
        
        return 
            
        if ($subTitle) 
            then  concat($mainTitle, ': ', $subTitle)
        else
            $mainTitle
};


(:~
 : normalize-authors
 :  an array of all parts of an authors name mods:namePart
 : 
 : @param $names all namePart elements in the document
 : @return array of author names
 :)
declare function citations:normalize-authors($names as element()*) as array(*) {
    array {
        for $name in $names 
            return $name//text()
    }
};
