import ballerina/http;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

final http:Client sentimentEp = check new ("http://localhost:9098/text-processing");

configurable string host = ?;
configurable int port = ?;
configurable string username = ?;
configurable string password = ?;
configurable string database = ?;

final mysql:Client socialMediaDb = check new (host, username, password, database, port);
