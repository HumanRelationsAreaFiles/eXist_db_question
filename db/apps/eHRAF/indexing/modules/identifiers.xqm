xquery version "3.1";

module namespace identifiers = "http://hraf.yale.edu/eHRAF/identifiers";
import module namespace functx="http://www.functx.com";

(:~
 : identifiers
 : this module handles document identifers. Currently limited to the update of 
 : identifiers. xml:ids and pageEids. Each element gets a linear xml:id and will
 : need to be update upon addition or removal of an elemenet. Similiarly each
 : element in a "page" will come with a pageEid or the xml:id of the pg.br
 : 
 : @author Matthew G. Roth <matthew.g.roth@yale.edu>
 :)

(:~
 : update_xmlids
 :  is a function that updates/insert XMLIDs on every element
 :  @param $doc is the document to update
 :  @param $docid {string} the document identifier used as part of the update
 :)
declare  function identifiers:update_xmlids($doc as item()*, $docid as xs:string) {

let $paras := $doc//*
let $resp := (# exist:batch-transaction #) {
    for $para at $pos in $paras
       return
        if (exists($para/@xml:id)) then
          update value $para/@xml:id with attribute xml:id { concat($docid, "-", functx:pad-integer-to-length($pos,5) ) }
        else 
            update insert attribute xml:id {concat($docid, "-", functx:pad-integer-to-length($pos,5) ) } into $para
    }
    return $resp
};


(:~ 
 : update_pageEids
 :   is a function that updates each SRE with a  fresh PageEid from the xml:id 
 :   of the preceding page.break
 : 
 :   @param $doc is the document to update
 :)
declare function identifiers:update_pageEids($doc as item()*) {
let $paras := $doc/hraf.doc/(front|body|back)//*
let $resp := (# exist:batch-transaction #) { 
    for $para in $paras
        let $pageEid := $para/preceding::page.break[1]/@xml:id/string()
        return
          if ($para[self::p[parent::section or 
                             parent::front or 
                             parent::body or 
                             parent::back or 
                             parent::title.page] or 
                     self::title[parent::section or 
                                  parent::body or 
                                  parent::title.page] or 
                     self::bibl.item or 
                     self::enote or 
                     self::culture.change]) 
                     then
             (
              update insert attribute pageEid {$pageEid} into $para
              )
          else if ($para/@pageEid) then
             update delete $para/@pageEid
          else ()
}
    return $resp

};