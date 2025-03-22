import ballerina/http;

final http:Client sentimentEp = check new ("http://localhost:9098/text-processing");
