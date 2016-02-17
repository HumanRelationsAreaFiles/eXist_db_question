xquery version "3.1";

module namespace eHRAF = "http://hraf.yale.edu/eHRAF";



declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mods =  "http://www.loc.gov/mods/v3";



declare variable $eHRAF:svnData as xs:string := "/db/am46";

import module namespace cultureChange = "http://hraf.yale.edu/eHRAF/cultureChange" 
at "xmldb:exist:///db/apps/eHRAF/indexing/modules/cultureChange.xqm";
import module namespace sre = "http://hraf.yale.edu/eHRAF/sre" 
at "xmldb:exist:///db/apps/eHRAF/indexing/modules/sre.xqm";
import module namespace resp = "http://hraf.yale.edu/eHRAF/resp" 
at "xmldb:exist:///db/apps/eHRAF/indexing/modules/resp.xqm";
import module namespace citations = "http://hraf.yale.edu/eHRAF/citations" 
at "xmldb:exist:///db/apps/eHRAF/indexing/modules/citations.xqm";
import module namespace identifiers = "http://hraf.yale.edu/eHRAF/identifiers" 
at "xmldb:exist:///db/apps/eHRAF/indexing/modules/identifiers.xqm";


(:~
 : Controller
 : restxq paths for the indexing system
 :
 : @author Matthew G. Roth <matthew.g.roth@yale.edu>
 :)


(: ~
 : display_documents_for_owc
 :  gives a terse listing of the documents available for an owc.
 :  and attempts to display indexing status
 : 
 :  @param $owc the Outline of Cultural Material idenitifer 
 :  @return map containing metadata about each document
 :)
declare
%rest:GET
%rest:path("/eHRAF/{$owc}")
%rest:produces("application/json")
%output:media-type("application/json")
%output:method("json")
function eHRAF:display_documents_for_owc($owc as xs:string?) {
    let $resp :=  array {
        for $doc in collection($eHRAF:svnData)//hraf.doc[starts-with(@id,$owc)]
            let $pages as xs:integer := count($doc//page.break)
            let $id := $doc/@id/string()
            let $headers as xs:integer := count($doc//culture.change)
            let $sres := $doc//*[@pageEid][not(ancestor::citation) and local-name() != 'title' and local-name() != 'culture.change']
            let $mod_record := collection('/db/citations/')//mods:mods[@ID=$id]
                
            let $title :=  citations:title-full($mod_record/mods:titleInfo)
            let $author := $mod_record/mods:name[@usage="primary"]/mods:namePart/text()
            order by $id
            return map { 
                "id": $id, 
                "pages": $pages, 
                "indexed_pages": $headers,
                "sres": count($sres),
                "indexed_sres": count($sres[@ocms]),
                "title": $title,
                "author": $author
                }
        }

    return
        resp:http-response(200, $resp)
};

(: ~
 : display_document_toc_json
 :   retreives the Table of Contents for a given document. Some pages have no content
 : 
 :   @param $doc the document to retrieve
 :   @return array containing pages in a document
 :)
declare
%rest:GET
%rest:path("/eHRAF/{$doc}/toc")
%rest:produces("application/json")
%output:media-type("application/json")
%output:method("json")
function eHRAF:display_document_toc_json($doc as xs:string?) {
    let $document := collection($eHRAF:svnData)//hraf.doc[@id=$doc]
    let $pages := $document//page.break
    let $resp := <doc id="{$doc}" pagecount="{count($pages)}">
        { for $page at $pos in $pages
            let $pgno := $page/@pg.no
            let $id := $page/@xml:id
            let $content := count($document//node()[@pageEid=$id and not(self::culture.change)])
            let $section := $page/ancestor-or-self::section[1]/title//text()
            return 
                <page num="{$pgno}" 
                      id="{$id}"
                      pos="{$pos}"
                      section="{$section}"
                      content="{boolean($content)}"/>
        }
    </doc>
    return
        resp:http-response(200, $resp)
};

(: ~
 : display_document_toc_xml
 :   retreives the Table of Contents for a given document. Some pages have no content
 : 
 :   @param $doc the document to retrieve
 :   @return nodeset containing pages in a document
 :)
declare
%rest:GET
%rest:path("/eHRAF/{$doc}/toc")
%rest:produces("application/xml")
%output:media-type("application/xml")
%output:method("xml")
function eHRAF:display_document_toc_xml($doc as xs:string?) {
    let $document := collection($eHRAF:svnData)//hraf.doc[@id=$doc]
    let $pages := $document//page.break
    let $resp := <doc id="{$doc}" pagecount="{count($pages)}">
        { for $page at $pos in $pages
            let $pgno := $page/@pg.no
            let $id := $page/@xml:id
            let $content := count($document//node()[@pageEid=$id and not(self::culture.change)])
            let $section := $page/ancestor-or-self::section[1]/title//text()
            return 
                <page num="{$pgno}" 
                      id="{$id}"
                      pos="{$pos}"
                      section="{$section}"
                      content="{boolean($content)}"/>
        }
    </doc>
    return
        resp:http-response(200, $resp)
};



 


(: ~
 : display_document_page_json
 :   return a the requested page ready to be inserted into the editor
 : 
 :   @param $doc the doucment to edit
 :   @param $page the page number to edit
 :   @return map containing the page
 :)
declare
%rest:GET
%rest:path("/eHRAF/{$doc}/{$page}")
%rest:produces("application/json")
%output:media-type("application/json")
%output:method("json")
function eHRAF:display_document_page_json($doc as xs:string?, $page as xs:int) {
    let $document := doc(concat($eHRAF:svnData,'/', $doc, '.xml'))
    let $id := ($document//page.break)[$page]/@xml:id
    let $cultureChange := $document//culture.change[@pageEid = $id]
    let $cc := if ($cultureChange) 
        then cultureChange:culture_change_array($cultureChange) 
        else cultureChange:culture_change_array(<empty/>)
    let $sres := <body>{$document//node()[@pageEid=$id]}</body>
    let $html := <doc>{transform:transform($sres, doc("./toHTML.xsl"),())}</doc>
    let $sreids := sre:get-ids($html) 
    let $section := sre:toArray($html/section)
    let $footer := sre:toArray($html/footer)  
   
    let $resp := map { 
        "section": $section, 
        "footer": $footer,
        "sres": $sreids,
        "cultureChange": $cc
    }

    return resp:http-response(200, $resp)
    
};



(: ~
 : display_document_page_html
 :   return a the requested page ready to be inserted into the editor
 : 
 :   @param $doc the doucment to edit
 :   @param $page the page number to edit
 :   @return the html version of the page as xml
 :)
declare
%rest:GET
%rest:path("/eHRAF/{$doc}/{$page}/html")
%rest:produces("application/xml")
%output:media-type("application/xml")
%output:method("xml")
function eHRAF:display_document_page_html($doc as xs:string?, $page as xs:int) {
    let $document := collection($eHRAF:svnData)//hraf.doc[@id=$doc]
    let $id := ($document//page.break)[$page]/@xml:id
    let $sres := <body>{$document//node()[@pageEid=$id]}</body>
    let $html := <doc>{transform:transform($sres,doc("./toHTML.xsl"),())}</doc>
    let $resp :=  array {
        
        for $sre in $html/section/node()
            let $dataid := $sre/@data-id/string()
            let $ocms := $sre/@data-ocm/string()
            let $innerHTML := $sre/child::node()
            
            return 
                map { "data-id": $dataid,
                   "ocms": $ocms,
                   "innerHTML": $innerHTML
                   }
       }
                                
    return $html
    
};

(: ~
 : display_document_page_xml
 :   return a the requested page ready to be inserted into the editor prior to 
 :   its xsl transformation
 : 
 :   @param $doc the doucment to edit
 :   @param $page the page number to edit
 :   @return the xml version of the page as xml
 :)
declare
%rest:GET
%rest:path("/eHRAF/{$doc}/{$page}/xml")
%rest:produces("application/xml")
%output:media-type("application/xml")
%output:method("xml")
function eHRAF:display_document_page_xml($doc as xs:string?, $page as xs:integer) {
    let $document := collection($eHRAF:svnData)//hraf.doc[@id=$doc]
    let $id := ($document//page.break)[$page]/@xml:id
    let $sres := $document//node()[@pageEid=$id]

    return <doc>{$sres}</doc>
    
};



(:~
 : add_culture_change
 :   a function that recieves and updated culture change
 :   
 :   @param $owc {xs:string} the OWC code of the document
 :   @param $doc {xs:string} the document number 
 :   @param $num {xs:integer} the page number to (begin) applying the CC
 :   @return json array summarzing operation
 :)
declare
%rest:POST("{$form-body}")
%rest:path("/eHRAF/{$owc}/{$doc}/page/{$num}")
%output:method("json")
function eHRAF:add_culture_change($owc as xs:string,
                                   $doc as xs:string,
                                   $form-body as xs:string,
                                   $num as xs:integer) 
{
    let $resp := try { 
       let $payload := parse-json($form-body)
       let $docID := concat($owc,'-', $doc)
       let $update := cultureChange:iterate($payload, $docID, $num)
       
       return array { 
                       map { 
                       "doc": $docID, 
                       "payload": $payload, 
                       "x": $update }}
    } catch * {
    
         array { concat($err:code, ": ", $err:description)  }
    }
    return resp:http-response(200, $resp)

};

(:~
 : add_culture_change_options
 :   a function that recieves and updated culture change options. 
 :   
 :   @param $owc {xs:string} the OWC code of the document
 :   @param $doc {xs:string} the document number 
 :   @param $num {xs:integer} the page number to (begin) applying the CC
 :   @return json array summarzing operation
 :)
declare
%rest:OPTIONS
%rest:path("/eHRAF/{$owc}/{$doc}/page/{$num}")
%output:method("json")
function eHRAF:add_culture_change_options($owc as xs:string,
                                   $doc as xs:string,
                                   $num as xs:integer)  
{

    resp:http-options-response(200)
};



(:~
 : add_ocms
 :  a function that recieves updated @ocms for one or many sre's
 : 
 :  @param $owc the OWC code of the document
 :  @param $doc the document number
 :  @map confirming or denying updating of sre's  :)
declare
%rest:POST("{$form-body}")
%rest:path("/eHRAF/{$owc}/{$doc}/sres/ocms")
%output:method("json")
function eHRAF:add_ocms($owc as xs:string,
                         $doc as xs:string, 
                         $form-body as xs:string )  
{

    let $payload := parse-json($form-body)
    let $docID := concat($owc,"-",$doc)
    let $document := collection($eHRAF:svnData)//hraf.doc[@id=$docID]
    let $sres := $document//node()[@xml:id = $payload?sres]
    let $resp := array { 
        if (count($sres) eq array:size($payload?sres)) 
            then let $update := sre:update($sres,$payload?ocms)
                      return map {
                         "sres_found": count($sres), 
                         "sres_expected": array:size($payload?sres),
                         "code": 200,
                         "message": "SREs updated"
                         }
            else
                map { 
                  "code": 405,
                  "sres_found": count($sres), 
                  "sres_expected": array:size($payload?sres),
                  "error_message": "SRES not updated. `sres_found` ne `sres_expected`"
                  }
                  
    }         
    
   
    return resp:http-response(200,$resp)
};

(:~
 : add_ocms_options
 :  a function that recieves updated @ocms for one or many sre's options
 : 
 :  @param $owc the OWC code of the document
 :  @param $doc the document number
 :  @map confirming or denying updating of sre's  :)

declare
%rest:OPTIONS
%rest:path("/eHRAF/{$owc}/{$doc}/sres/ocms")
%output:method("json")
function eHRAF:add_ocms_options($owc as xs:string,
                         $doc as xs:string)  
{

    resp:http-options-response(200)
};





(: ~
 : update_idenitifers
 :  update the indetifiers a documnet 
 : 
 : @param $owc the outline of world cultures code (culture)
 : @param $doc the document number 
 : @return array stating which document was updated 
 :)
declare 
%rest:GET
%rest:path("/eHRAF/update/{$owc}/{$doc}")
%output:method("json")
function eHRAF:update_identifiers($owc as xs:string, $doc as xs:string) {
    let $document := doc(concat($eHRAF:svnData,'/', $owc,'-',$doc,'.xml'))
    let  $docid := $document/hraf.doc/@id/string()
    let $up := identifiers:update_xmlids($document, $docid)
    let $update := identifiers:update_pageEids($document)
 
    let $resp := array { concat("updated ", $docid) }
 
    return resp:http-response(200, $resp)
};

