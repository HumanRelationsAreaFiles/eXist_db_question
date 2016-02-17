xquery version "3.1";

module namespace resp = "http://hraf.yale.edu/eHRAF/resp";
declare namespace http = "http://expath.org/ns/http-client";

(:~
 : Http Responses (resp)
 : this handles the http response to API. 
 : 
 : @author Matthew G. Roth <matthew.g.roth@yale.edu>
 :)

(:~
 : http-response 
 :  Is a function that sets the headers of an HTTP response
 :  
 :  @param $http-code is the HTTP response code for the response
 :  @param $resource is the actual resource being returned 
 :  @return http response
 :)
declare function resp:http-response($http-code as xs:integer, $resource)
{
    (
    <rest:response>
        <http:response
            status="{$http-code}">
            <http:header
                name="Access-Control-Allow-Origin"
                value="*"/>
        </http:response>
    </rest:response>,
    $resource
    )
};

(:~
 : http-options-response
 :  Supply a response to OPTIONS
 :  (note: this seems to be first necessary in 3RC2 
 :  
 :  @param $http-code the status code to return 
 :  @return http response
 :)
declare function resp:http-options-response($http-code as xs:integer) {
    
    <rest:response>
        <http:response
            status="{$http-code}">
            <http:header
                name="Access-Control-Allow-Origin"
                value="*"/>
            <http:header
                name="Access-Control-Allow-Headers"
                value="Content-type,Access-Control-Allowed-Origin,Accept"/>
        </http:response>
    </rest:response>

};
