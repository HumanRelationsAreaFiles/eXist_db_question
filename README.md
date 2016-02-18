#eXist-db Questions

## Table of Contents
  0. Background
  1. Updating a Document causes index corruption?
  2. Indexing Speed?
  3. Performance during indexing?

# Background
Founded at Yale University, Human Relations Area Files (HRAF) is an internationally
recognized organization in the field of cultural anthropology. HRAF's mission 
is to encourage and facilitate the cross-cultural study of human culture, 
society, and behavior in the past and present. 

More plainly we are taking ethnographies about cultures and having trained 
anthropologists attach metadata at the paragraph and page level. 

Currently we use eXist to search the documents within our web applications. 
However, we would like to incorporate eXist earlier in the process and this is
where our troubles are beginning. Updating Documents seem to cause corruption 
of the index in some cases. This is solved with a reindexing. But, with 
Approximately 10,000 documents this takes over 1hr, and completely locks down 
the exist instance in the process. 

# Update a Document without corrupting
A problem we are running into is when updating page level metadata. The desired
action would be to add metadata one page at a time. Upon application on a single
page it is specified to propagate to future pages if the information 
is the same. However, this very consistently causes an error and/or corruption
of the database. Let me walk through an example.

##Example
Trying to add a `date[@type="coverage"]` causes an error.


>**Note**: this example can be reproduced by running `./test.sh` 
and calls the restxq `controller.xq` from `/db/apps/eHRAF/indexing`

````bash
curl http://$EXIST_URL/exist/restxq/eHRAF/am46-178/5 -o test.js
````

Snippet of the relevant output from `test.js`. 
````javascript
{
  "cultureChange" : {
    "dates" : [ {
      "period" : "",
      "start" : "1967",
      "startUnit" : "AD",
      "end" : "1985",
      "endUnit" : "AD"
    } ],
    "geoPlaces" : [ "Vientiane Province, Laos" ]
  }
}
````

next we mimic the call from the browser and add a second date coverage 
from the fictitious range of 10-20AD. 

>**Note**: that the browser sends the OPTIONS request immediately preceding the POST

````bash
curl 'http://$EXIST_URL/exist/restxq/eHRAF/am46/178/page/5' -X OPTIONS -H 'Access-Control-Request-Method: POST' -H 'Origin: http://192.168.10.155:3030' -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.82 Safari/537.36' -H 'Accept: */*' -H 'Referer: http://192.168.10.155:3030/owcs/am46/documents/178' -H 'Connection: keep-alive' -H 'Access-Control-Request-Headers: accept, access-control-allowed-origin, content-type' --compressed
curl 'http://$EXIST_URL/exist/restxq/eHRAF/am46/178/page/5' -H 'Origin: http://192.168.10.155:3030' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8'  -H 'content-type: application/xml' -H 'accept: application/json'  -H 'Connection: keep-alive' -H 'access-control-allowed-origin: *' --data-binary '{"timeCoverage":[{"period":"","start":"1967","startUnit":"AD","end":"1985","endUnit":"AD"},{"period":"","start":"10","startUnit":"AD","end":"20","endUnit":"AD"}],"propagateTimeCoverage":true,"placeCoverage":["Vientiane Province, Laos"],"propagatePlaceCoverage":true}' --compressed -o post.js
````

`test.js` sleeps for 10 seconds and calls the previous GET request of the page
````bash
curl http://$EXIST_URL/exist/restxq/eHRAF/am46-178/5 -o test2.js
````

The expected output would have the cultureChange.dates array populated with a
second map containing `{"start": 10, "startUnit": "AD", "end": 20, "endUnit": "AD"}` 
However the majority of the time it returns
````javascript
{
  "cultureChange" : {
    "dates" : [ "java:java.lang.NullPointerException: " ],
    "geoPlaces" : [ "Vientiane Province, Laos" ]
  }
````

exist.log returns
````
2016-02-18 11:34:45,784 [eXistThread-48] WARN  (AbstractEmbeddedXMLStreamReader.java [verifyOriginNodeId]:235) - expected node id 2.4.4.5.5.2.4.5, got 2.4.4.8.5.8.3.3.2; resyncing address 
````

in other tests it returns something like 
````
2016-02-18 11:12:59,407 [eXistThread-101] ERROR (VirtualNodeSet.java [addChildren]:528) - java.io.IOException: Node not found. 
2016-02-18 11:12:59,408 [eXistThread-101] ERROR (VirtualNodeSet.java [addChildren]:528) - java.io.IOException: Node not found. 
2016-02-18 11:12:59,901 [eXistThread-38] WARN  (AbstractEmbeddedXMLStreamReader.java [verifyOriginNodeId]:235) - expected node id 2.4.4.8.3.6.5, got 2.4.4.8.9.4.6.3.7.2; resyncing address 
2016-02-18 11:13:01,218 [eXistThread-101] ERROR (VirtualNodeSet.java [addChildren]:528) - java.io.IOException: Node not found. 
2016-02-18 11:13:01,218 [eXistThread-101] ERROR (VirtualNodeSet.java [addChildren]:528) - java.io.IOException: Node not found. 
````

And `cultureChange` may simply have a second date with blank options. 
In these cases reindexing often will resolve the problem, but in some cases a
full restore is necessary from back up. These tests are not included here
but may include not waiting and immediately calling the GET, removing a
successfully added second date, or modifying and existing date. Nevertheless,
the result is often one of the prior two errors.

##Other Thoughts
How can we avoid reading from the document as it is being written? Rather
how are we able to tell when an update finishes? In `test.sh` we are sleeping
ten seconds, but in a web application we would prefer this operation to occur 
in as quick as possible. 

We have considered updating only one page at a time. However, this is 
undesirable for two reasons. The first is that often times page metadata does
not change that often across the doucment. Additionally, it is not unusual
for the page metadata across multiple pages to be modified slightly during the 
review process. 

Additionally, we have long thought about removing the page level metadata from 
the document all together. Perhaps adding it to a relational database would 
make for quicker performance during document analysis. This would account for a 
radical departure from what we have been trying to accomplish and our current 
applications require it being in the XML already. We could always pump it back
into the xml at a later point. 



#Indexing Speed
In addition to solving the previously mentioned errors with reindexing we often
will need to regenerate xml:id’s when we add or remove elements within a document.
With Approximately 10k documents ranging in size from a few Kb to a few Mb this 
often takes over an hour. This could be acceptable, but is a full reindexing
Necessary each time a document is updated or added? And does an hour sound appropriate
considering the `collection.xconf` that can be seen under `/db/system/config/db/am46`

#Performance during indexing
When indexing the database completely grinds to a half. It will finish, but 
almost never are we able to retrieve any response from the database until the
indexing finishes. This makes the question related to Indexing speed all the
more relevant. 
