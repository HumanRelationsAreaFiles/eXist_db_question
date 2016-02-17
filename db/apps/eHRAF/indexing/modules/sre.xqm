xquery version "3.1";

module namespace sre = "http://hraf.yale.edu/eHRAF/sre";

(:~ Search and Retrieval Elements (SREs)
 :  This module handles functions related to SREs. SREs are the unit of 
 :  analysis. Each one will me marked up with @ocms (Outline of 
 : Cultural Material Codes). 
 : 
 : @author Matthew G. Roth <matthew.g.roth@yale.edu> 
 :)


(:~
 : update
 :  for one or many SREs insert attribute ocms with given ocms
 : 
 :  @param $sres one or many SRE elements
 :  @param $ocms the ocms to insert into the sre
 :  @return empty Sequence 
 :)
declare function sre:update($sres, $ocms) {
    update insert attribute ocms { $ocms } into $sres
};

(:~
 : get_sres
 :  gather the sres in from xml:id start to end. Note TITLES are not SRES
 : 
 :  @param $doc the document we are to gather the sre's from
 :  @param $start the first xml:id to gather from
 :  @param $end the last xml:id to gather from
 :  @return a sequence containing eahc SRE from the range of xml:ids
 :)
declare function sre:get_sres($doc, $start as xs:string, $end as xs:string?) {
        let $elements := 
            if ($end) 
                then $doc//element()[(
                    (following-sibling::element()[@xml:id = $end]  and 
                     preceding-sibling::element()[@xml:id = $start]) or 
                     @xml:id=$start or @xml:id=$end) 
                     and @pageEid and local-name() != 'title' ]
          else 
            $doc//element()[@xml:id=$start]
            
        return $elements
};

(:~
 : get-ids 
 :  get IDS from each sre
 : 
 :  @param $page a single page from the document
 :  @return array of each sre id from the page. 
 :)
declare function sre:get-ids($page) {
    array { 
        for $sre in $page/section/node() 
            let $sid := $sre/@data-id/string()
            group by $sid
            order by $sid
            
            return $sid
        }
};

(:~
 : toArray
 :  an array of the sre with its components mapped to be inserted into the 
 :  indexing application
 : 
 :  @param $sres the sres we are mapping
 :  @return the array of mapped SREs 
 :)
declare function sre:toArray($sres) { 
    array {     
        for $sre in $sres/node()
            let $nodeName := $sre/local-name()
            let $dataid := $sre/@data-id/string()
            let $ocms := array { fn:tokenize($sre/@data-ocms/string(), ' ') }
            let $innerHTML := $sre/child::node()
            let $className := $sre/@class/string()
            return 
                map { 
                    "data-id": $dataid,
                   "ocms": $ocms,
                   "innerHTML": array { $innerHTML },
                   "nodeName": $nodeName,
                   "className" : $className
                   }
       }
};