#!/bin/sh

EXIST_URL=$1

#CLEAN
#CultureChange.dates.length should equal 1
curl http://$EXIST_URL/exist/restxq/eHRAF/am46-178/5 -o page5.js
curl http://$EXIST_URL/exist/restxq/eHRAF/am46-178/6 -o page6.js

#TEST 2 - OPTIONS/POST 
#Add Date Coverage to Page 5. Should propagate to Page 6
curl http://$EXIST_URL/exist/restxq/eHRAF/am46/178/page/5 -X OPTIONS -H 'Access-Control-Request-Method: POST' -H 'Origin: http://192.168.10.155:3030' -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.82 Safari/537.36' -H 'Accept: */*' -H 'Referer: http://192.168.10.155:3030/owcs/am46/documents/178' -H 'Connection: keep-alive' -H 'Access-Control-Request-Headers: accept, access-control-allowed-origin, content-type' --compressed
curl http://$EXIST_URL/exist/restxq/eHRAF/am46/178/page/5 -H 'Origin: http://192.168.10.155:3030' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8'  -H 'content-type: application/xml' -H 'accept: application/json'  -H 'Connection: keep-alive' -H 'access-control-allowed-origin: *' --data-binary '{"timeCoverage":[{"period":"","start":"1967","startUnit":"AD","end":"1985","endUnit":"AD"},{"period":"","start":"10","startUnit":"AD","end":"25","endUnit":"AD"}],"propagateTimeCoverage":true,"placeCoverage":["Vientiane Province, Laos"],"propagatePlaceCoverage":true}' --compressed -o post.js


#sleep five seconds
sleep 5

#TEST 2 - BAD?
#CultureChange.dates.length should equal 2
curl http://$EXIST_URL/exist/restxq/eHRAF/am46-178/5 -o test.page5.js

#TEST 3 - BAD?
#CultureChange.dates.length should equal 2
curl http://$EXIST_URL/exist/restxq/eHRAF/am46-178/6 -o test.page6.js
